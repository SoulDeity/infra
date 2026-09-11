#!/usr/bin/env bash
# Need to run the following
# source /home/restic/backrest.sh
# restic -r s3:{{ restic_b2_endpoint }}/{{ restic_b2_bucket }}/{{ restic_dir }} init
#
# Entry points (invoked by cron):
#   backrest.sh cron_backup   -- backup, then forget --prune
#   backrest.sh cron_check    -- repository integrity check
#   backrest.sh run <args>    -- run restic ad hoc with the environment set up
#
# NOTE: no `set -e`. The restic calls are piped into tee, so their exit status
# comes from ${PIPESTATUS[0]} rather than being relied on to abort the script.
# With `set -e`, a single failed healthchecks curl would kill the run -- and if
# it were the curl before forget, the forget phase would silently never
# execute. Do NOT add `set -o pipefail` either: it would make the pipelines
# report tee's status instead of restic's, breaking the exit code reporting.

export AWS_ACCESS_KEY_ID="{{ restic_b2_application_key_id }}"
export AWS_SECRET_ACCESS_KEY="{{ restic_b2_application_key }}"
export RESTIC_PASSWORD="{{ restic_key }}"
export RESTIC_REPOSITORY="s3:{{ restic_b2_endpoint }}/{{ restic_b2_bucket }}/{{ restic_dir }}"
export GOGC=20  # HACK: Work around for restic's high memory usage https://github.com/restic/restic/issues/1988

export RESTIC_LOG_DIR="/home/restic/log"
export RESTIC_LOG_KEEP_DAYS={{ restic_log_keep_days | default(14) }}

# --retry-lock waits rather than failing instantly on transient contention. It
# does NOT rescue a lock orphaned by a killed process -- it waits the full
# duration and then fails. That case needs `restic unlock` (or `unlock
# --remove-all` if the PID has been reused and restic won't call it stale).
RETRY_LOCK="--retry-lock {{ restic_retry_lock | default('10m') }}"

# --cleanup-cache stops old per-repo cache directories accumulating.
GLOBAL_OPTIONS="$RETRY_LOCK --cleanup-cache"

export BACKUP_OPTIONS="--files-from=/home/restic/restic-include.txt --exclude-file=/home/restic/restic-excludes.txt"
# --keep-last 3 is a hard floor: it survives regardless of dates, so a long
# run of failed backups can never let a later forget prune down to nothing.
export FORGET_OPTIONS="--keep-last 3 --keep-daily {{ restic_keep_daily | default(30) }} --keep-monthly {{ restic_keep_monthly | default(12) }} --group-by host"
export CHECK_OPTIONS="--read-data-subset={{ restic_check_subset | default('10%') }}"

mkdir -p "$RESTIC_LOG_DIR"

# Ping healthchecks. $1 = check uuid, $2 = endpoint (start | <exit code>),
# $3 = optional log file to POST as the body. Never fatal: a monitoring
# outage must not stop the backup, so failures are swallowed.
ping_hc() {
    local uuid="$1" endpoint="$2" logfile="${3:-}"
    [ -n "$uuid" ] || return 0
    if [ -n "$logfile" ] && [ -f "$logfile" ]; then
        curl -fsS -m 30 --retry 5 -o /dev/null \
            "https://hc.{{ secret_domain_cloud }}/ping/$uuid/$endpoint" \
            --data-binary "@$logfile" || true
    else
        curl -fsS -m 10 --retry 5 -o /dev/null \
            "https://hc.{{ secret_domain_cloud }}/ping/$uuid/$endpoint" || true
    fi
}

# Run one restic phase: log to its own file, report the outcome, echo the code.
# $1 = phase name (log prefix), $2 = healthchecks uuid, rest = restic args.
#
# 2>&1 is essential. restic writes fatal errors to stderr and a bare pipe only
# carries stdout, so without it a failure reaches neither the log file nor the
# healthchecks body -- the check goes red with a body that looks like success.
# The redirect does not affect ${PIPESTATUS[0]}.
run_phase() {
    local phase="$1" uuid="$2"
    shift 2
    local logfile="$RESTIC_LOG_DIR/$phase-$(date -Iseconds).log"
    local exit_code

    ping_hc "$uuid" start
    restic "$@" 2>&1 | tee -a "$logfile"
    exit_code=${PIPESTATUS[0]}
    ping_hc "$uuid" "$exit_code" "$logfile"
    echo "${phase} exit code: $exit_code"
    return "$exit_code"
}

# Delete logs older than the retention window. The previous logrotate config
# could never do this: filenames are unique per run, so logrotate renamed each
# to .log.1.gz once (no longer matching *.log) and never touched it again.
prune_logs() {
    find "$RESTIC_LOG_DIR" -maxdepth 1 -type f -name '*.log' \
        -mtime +"$RESTIC_LOG_KEEP_DAYS" -delete 2>/dev/null || true
}

cron_backup() {
    run_phase backup "{{ restic_healthchecks_id }}" \
        --verbose backup $GLOBAL_OPTIONS $BACKUP_OPTIONS

    run_phase forget "{{ restic_forget_healthchecks_id }}" \
        forget --prune $GLOBAL_OPTIONS $FORGET_OPTIONS

    prune_logs
}

# Integrity check. Runs on its own schedule, well away from the backup window.
# --read-data-subset actually downloads and verifies a slice of the pack files;
# a bare `check` only validates structure. Note the B2 download egress: 10% of
# a 350 GiB repo is ~35 GiB per run.
cron_check() {
    run_phase check "{{ restic_check_healthchecks_id | default('') }}" \
        check $GLOBAL_OPTIONS $CHECK_OPTIONS

    prune_logs
}

# Run restic ad hoc, with the environment set up.
#   backrest.sh run snapshots
#   backrest.sh run unlock
# (Named `run`, not `exec` -- the old name shadowed the shell builtin.)
run() {
    set -x
    restic "$@"
}

# Run the things
"$@"