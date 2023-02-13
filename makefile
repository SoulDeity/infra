### Servers
pms:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass

pcomp:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass --tags compose

prepl:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass --tags replication

pnut:
	ansible-playbook -b run.yaml --limit pms --ask-become-pass --tags nut

bastion:
	ansible-playbook -b run.yaml --limit bastion --ask-become-pass

bcomp:
	ansible-playbook run.yaml --limit bastion --tags compose

nut:
	ansible-playbook -b run.yaml --limit nut --ask-become-pass

cloud:
	ansible-playbook -b run.yaml --limit cloud --ask-become-pass

ccomp:
	ansible-playbook -b run.yaml --limit cloud --ask-become-pass --tags compose

### Updates
update:
	ansible-playbook update.yaml --limit servers --ask-become-pass

docker:
	ansible-playbook docker.yaml

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