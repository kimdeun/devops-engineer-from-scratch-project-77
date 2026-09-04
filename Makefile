SHELL := /bin/sh

TF_DIR := terraform
ANSIBLE_DIR := ansible
VAULT_PASSWORD_FILE := $(ANSIBLE_DIR)/.vault_password
VAULT_SOURCE ?= $(ANSIBLE_DIR)/vault.local.yml
export ANSIBLE_LOCAL_TEMP := /private/tmp/ansible-local

.PHONY: install vault-create vault-edit secrets init fmt validate plan apply destroy prepare deploy monitoring ping output clean-generated

install:
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml
	ansible-galaxy role install -r $(ANSIBLE_DIR)/requirements.yml -p $(ANSIBLE_DIR)/roles

vault-create:
	test -f $(VAULT_PASSWORD_FILE) || (echo "Create $(VAULT_PASSWORD_FILE) first"; exit 1)
	test -f $(VAULT_SOURCE) || (echo "Create $(VAULT_SOURCE) from vault.example.yml first"; exit 1)
	ansible-vault encrypt $(VAULT_SOURCE) --output $(ANSIBLE_DIR)/vault.yml --vault-password-file $(VAULT_PASSWORD_FILE)

vault-edit:
	ansible-vault edit $(ANSIBLE_DIR)/vault.yml --vault-password-file $(VAULT_PASSWORD_FILE)

secrets:
	cd $(ANSIBLE_DIR) && ansible-playbook -i localhost, render-secrets.yml --vault-password-file .vault_password

init: secrets
	terraform -chdir=$(TF_DIR) init -backend-config=backend.hcl

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive -check

validate:
	terraform -chdir=$(TF_DIR) validate

plan: secrets
	terraform -chdir=$(TF_DIR) plan -out=project.tfplan

apply: plan
	terraform -chdir=$(TF_DIR) apply project.tfplan

destroy: secrets
	terraform -chdir=$(TF_DIR) destroy

prepare:
	cd $(ANSIBLE_DIR) && ansible-playbook playbook.yml --tags prepare --vault-password-file .vault_password

deploy:
	cd $(ANSIBLE_DIR) && ansible-playbook playbook.yml --tags deploy --vault-password-file .vault_password

monitoring:
	cd $(ANSIBLE_DIR) && ansible-playbook playbook.yml --tags monitoring --vault-password-file .vault_password

ping:
	cd $(ANSIBLE_DIR) && ansible web -m ping

output:
	terraform -chdir=$(TF_DIR) output

clean-generated:
	rm -f $(TF_DIR)/secrets.auto.tfvars $(TF_DIR)/backend.hcl $(TF_DIR)/project.tfplan
