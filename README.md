# souldeity/infra

This repo is my go at Infrastructure as Code for my Home Lab.

Massive credit to [Ironicbadger](https://github.com/IronicBadger/infra), [FuzzyMistborn](https://github.com/FuzzyMistborn/infra), and [TheOrangeOne](https://github.com/RealOrangeOne/infrastructure). A lot of this code is taken from their infra repos and adapted for my specific use.

## Pre-req's

Playbooks assume user has SSH with SSH Keys access from the Ansible Host to each VM/Host.

Ansible [integrates](https://theorangeone.net/posts/ansible-vault-bitwarden/) with Bitwarden through its [CLI](https://bitwarden.com/help/article/cli/).

## Playbooks

`run.yaml` - Main playbook that configures my servers (currently only SoulPMS and SoulBastion), reference the makefile for specific commands.

`update.yaml` - Updates ssh keys from GitHub and updates packages on all hosts in \[servers\] group.

`docker.yaml` - Updates docker-compose files and specific containers on chosen hosts.

`playbooks/core.yaml` / `playbooks/core-update.yaml` - Configure and patch the core edge nodes (see below).

## Core Edge Nodes (DNS + VIP)

Two Raspberry Pis run DNS and the local reverse proxy, sharing a floating VIP
through keepalived. Clients only ever use the VIP, so either Pi can go down
(or be patched) without losing DNS. Based on ironicbadger's core edge nodes.

| Host | IP | Role | Hardware |
|------|-----|------|----------|
| core-pi4-1 | 10.42.0.51 | MASTER, AdGuard sync origin | Raspberry Pi 4 (4GB) |
| core-pi4-2 | 10.42.0.52 | BACKUP, sync replica | Raspberry Pi 4 (4GB) |
| **VIP** | **10.42.0.53** | Floating | - |

DHCP is **not** on these nodes; it lives on the router (OPNsense Dnsmasq), which
hands out the VIP as the DNS server.

### Services

- **AdGuard Home** - local DNS and ad blocking (port 53, web UI on 3000)
- **Caddy** - reverse proxy with Cloudflare DNS-01 certificates
- **Keepalived** - VRRP failover for the VIP. The health check does a real DNS
  lookup against the local AdGuard, so a hung AdGuard fails over too
- **Chrony** - NTP
- **AdGuard Home Sync** - copies settings from pi4-1 to pi4-2 every 5 minutes

### Usage

```bash
make core-check                         # dry run with diff, changes nothing
make core                               # full playbook, BACKUP node first
make core ARGS="--tags adguard-config"  # just DNS rewrites/settings
make core ARGS="--tags caddy"           # just Caddy
make core-update                        # apt upgrade, reboot only if needed
make core-update ARGS="-e core_reboot=true"  # always reboot
```

Both playbooks run one node at a time, BACKUP first. `core-update` refuses to
start on a node unless the other one is answering DNS, and waits for DNS and
the VIP to come back before moving on.

### Where things live

| What | Source of truth | Applied by |
|------|-----------------|------------|
| DHCP reservations + local DNS names | `group_vars/dns.yaml` | `make core` (DNS); entered by hand in OPNsense (DHCP) |
| Extra rewrites, upstreams, DNSSEC, query log | `group_vars/core.yaml` | `make core --tags adguard-config` |
| Reverse proxy routes | `caddy_endpoints` in `group_vars/core.yaml` | `make core --tags caddy` |
| Blocklists, allowlists, clients | AdGuard UI on pi4-1 | adguardhome-sync |

Rewrites in AdGuard are managed by Ansible: any rewrite added in the UI that
isn't in the repo is removed on the next `make core`. Change settings on
**pi4-1** only; anything changed on pi4-2 is overwritten by the sync.

### Adding a device

1. Add it to `dhcp_reservations` in `group_vars/dns.yaml` (MAC, IP, hostname)
2. Add the same reservation in OPNsense: Services > Dnsmasq DNS & DHCP > Hosts
3. `make core ARGS="--tags adguard-config"` to publish its DNS name

### Adding a reverse proxy route

Add an entry under the wildcard in `caddy_endpoints` (`group_vars/core.yaml`)
and run `make core ARGS="--tags caddy"`. The wildcard rewrite already points
every `*.<local domain>` name at the VIP. Names two levels deep (like
`proxmox.p.<local domain>`) aren't covered by the wildcard certificate, so they
need their own top-level entry plus an exact rewrite in `adguard_extra_rewrites`.

### Network backend

The `core-network` role supports `networkd` (Debian) and `networkmanager`
(Raspberry Pi OS, used here) via `network_backend`. On NetworkManager it only
changes and restarts the connection when the static settings differ.
