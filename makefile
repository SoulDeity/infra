### Servers
pms:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass --vault-password-file .vault-password

pcomp:
	ansible-playbook run.yaml --limit pms --vault-password-file .vault-password --tags compose

ptr:
	ansible-playbook run.yaml --limit pms --vault-password-file .vault-password --tags traefik

bastion:
	ansible-playbook -b run.yaml --limit bastion --ask-become-pass --vault-password-file .vault-password

bcomp:
	ansible-playbook run.yaml --limit bastion --vault-password-file .vault-password --tags compose

### Updates
update:
	ansible-playbook update.yaml --limit servers --ask-become-pass --vault-password-file .vault-password

docker:
	ansible-playbook docker.yaml --vault-password-file .vault-password

reqs:
	ansible-galaxy install -r requirements.yaml

forcereqs:
	ansible-galaxy install -r requirements.yaml --force

### Vault
decrypt:
	ansible-vault decrypt --vault-password-file .vault-password vars/vault.yaml

encrypt:
	ansible-vault encrypt --vault-password-file .vault-password vars/vault.yaml

### Git
gitinit:
	@./git-init.sh
	@echo "ansible vault pre-commit hook installed"
	@echo "don't forget to create a .vault-password too"

git:
	@./gitupdate.sh