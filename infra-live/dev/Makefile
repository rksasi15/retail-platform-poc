# infra-live/dev — one command per layer. Run `make bootstrap` first (one time).
SHELL := /bin/bash
ENV   := dev
TFVARS := terraform.tfvars

.PHONY: bootstrap init plan apply apply-irsa output destroy destroy-bootstrap fmt validate

## 1) One-time: create state bucket + lock table + kOps/OIDC buckets (local backend)
bootstrap:
	cd bootstrap && terraform init && terraform apply -auto-approve
	@echo ">> Copy bootstrap bucket/table names into ../backend.tf and terraform.tfvars if you changed defaults."

## 2) Foundations
init:
	terraform init

fmt:
	terraform fmt -recursive ../../

validate:
	terraform validate

plan:
	terraform plan -var-file=$(TFVARS) -out=tfplan

apply:
	terraform apply tfplan

## 5) After the kOps cluster is up: create IRSA roles (Phase 2)
apply-irsa:
	terraform apply -var-file=$(TFVARS) -var 'create_irsa=true' -auto-approve

## Export outputs for Ansible
output:
	terraform output -json > /tmp/tf-dev-outputs.json && echo "wrote /tmp/tf-dev-outputs.json"

## Teardown (run cluster-destroy.yml FIRST)
destroy:
	terraform destroy -var-file=$(TFVARS) -var 'create_irsa=true' -auto-approve

destroy-bootstrap:
	cd bootstrap && terraform destroy -auto-approve
