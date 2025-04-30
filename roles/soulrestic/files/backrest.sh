#!/usr/bin/env bash
# Need to run the following
# source /home/restic/backrest.sh
# restic -r s3:{{ restic_b2_endpoint }}/{{ restic_b2_bucket }}/{{ restic_dir }} init

set -e

export AWS_ACCESS_KEY_ID="{{ restic_b2_application_key_id }}"
export AWS_SECRET_ACCESS_KEY="{{ restic_b2_application_key }}"
export RESTIC_PASSWORD="{{ restic_key }}"
export RESTIC_REPOSITORY="s3:{{ restic_b2_endpoint }}/{{ restic_b2_bucket }}/{{ restic_dir }}"
export GOGC=20  # HACK: Work around for restic's high memory usage https://github.com/restic/restic/issues/1988

export RESTIC_LOG_DIR="/home/restic/log"
export RESTIC_LOG_FILE="$RESTIC_LOG_DIR/$1-$(date -Iseconds).log"

export BACKUP_OPTIONS="--files-from=/home/restic/restic-include.txt --exclude-file=/home/restic/restic-excludes.txt"
export FORGET_OPTIONS="--keep-daily 30 --keep-monthly 3 --group-by host"

mkdir -p "$RESTIC_LOG_DIR"

cron_backup() {
    # Run backup, and capture logs to file
    curl -fsS -m 10 --retry 5 -o /dev/null https://hc.{{ secret_domain_cloud }}/ping/{{ restic_healthchecks_id }}/start
    restic --verbose backup $BACKUP_OPTIONS | tee -a $RESTIC_LOG_FILE
    exit_code=${PIPESTATUS[0]}
    curl -fsS -m 10 --retry 5 -o /dev/null https://hc.{{ secret_domain_cloud }}/ping/{{ restic_healthchecks_id }}/$exit_code --data-binary "@$RESTIC_LOG_FILE"
    echo "Backup Exit code: $exit_code"

    # Run forget and prune, and capture logs to file
    curl -fsS -m 10 --retry 5 -o /dev/null https://hc.{{ secret_domain_cloud }}/ping/{{ restic_forget_healthchecks_id }}/start
    restic forget --prune $FORGET_OPTIONS | tee -a $RESTIC_LOG_FILE
    exit_code=${PIPESTATUS[0]}
    curl -fsS -m 10 --retry 5 -o /dev/null https://hc.{{ secret_domain_cloud }}/ping/{{ restic_forget_healthchecks_id }}/$exit_code --data-binary "@$RESTIC_LOG_FILE"
    echo "Prune Exit code: $exit_code"
}

# Run restic, but with environment variables set
exec () {
    set -x
    restic $@
}

# Run the things
"$@"