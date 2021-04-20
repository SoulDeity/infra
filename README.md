# souldeity/infra

This repo is my go at Infrastructure as Code for my Home Lab.

Massive credit to [Ironicbadger](https://github.com/IronicBadger/infra) and [FuzzyMistborn](https://github.com/FuzzyMistborn/infra). A lot of this code is taken from their infra repos and adapted for my specific use.

# Pre-req's

Playbooks assume user has SSH with SSH Keys access from the Ansible Host to each VM/Host.

# Playbooks

`run.yaml` - main playbook that configures my VM's, reference the makefile for specific commands.

`update.yaml` - updates ssh keys from GitHub and updates packages on all hosts in \[servers\] group.

`docker.yaml` - Coutesy of [FuzzyMistborn](https://github.com/FuzzyMistborn/infra/blob/main/docker.yml). Updates docker-compose files and specific containers on chosen hosts.
