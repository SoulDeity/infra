### Network Infrastructure
pihole:
	ansible-playbook -b run.yaml --limit pihole --ask-become-pass

caddy:
	ansible-playbook -b run.yaml --limit caddy

unifi:
	ansible-playbook -b run.yaml --limit unifi

### Servers
pms:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass

pcomp:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass --tags compose

prepl:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass --tags replication

cloud:
	ansible-playbook -b run.yaml --limit cloud --ask-become-pass

ccomp:
	ansible-playbook -b run.yaml --limit cloud --ask-become-pass --tags compose

crepl:
	ansible-playbook -b run.yaml --limit cloud --ask-become-pass --tags replication

frigate:
	ansible-playbook -b run.yaml --limit frigate --ask-become-pass

fcomp:
	ansible-playbook -b run.yaml --limit frigate --ask-become-pass --tags compose

frepl:
	ansible-playbook -b run.yaml --limit frigate --ask-become-pass --tags replication

apps:
	ansible-playbook -b run.yaml --limit apps --ask-become-pass

acomp:
	ansible-playbook -b run.yaml --limit apps --ask-become-pass --tags compose

### Updates
update:
	ansible-playbook update.yaml --limit servers --ask-become-pass

docker:
	ansible-playbook docker.yaml

proxmox:
	ansible-playbook -b playbooks/proxmox-nag.yaml --limit proxmox --ask-become-pass 

net-updates:
	ansible-playbook playbooks/net-updates.yaml --limit netkids -b --ask-become-pass

reqs:
	ansible-galaxy install -r requirements.yaml

forcereqs:
	ansible-galaxy install -r requirements.yaml --force

### Vault
decrypt:
	ansible-vault decrypt vars/vault.yaml

encrypt:
	ansible-vault encrypt vars/vault.yaml

### Git
gitinit:
	@./git-init.sh
	@echo "ansible vault pre-commit hook installed"
	@echo "don't forget to create a .vault-password too"

git:
	@./gitupdate.sh