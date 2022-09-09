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
