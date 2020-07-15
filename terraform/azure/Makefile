SHELL := /bin/bash

SCENARIOS = $(shell ls -1 scenarios 2>/dev/null | tr -d /)
WORKSPACES = $(shell find scenarios/*/terraform.tfstate.d -maxdepth 1 -type d 2>/dev/null | sed 's|.*tfstate.d/||;/tfstate.d/d;')

ifneq ($(ARM_TENANT_ID),)
	export TF_VAR_arm_tenant_id ?= $(ARM_TENANT_ID)
endif

ifneq ($(ARM_SUBSCRIPTION_ID),)
	export TF_VAR_arm_subscription_id ?= $(ARM_SUBSCRIPTION_ID)
endif

ifneq ($(ARM_SSH_KEY_FILE),)
	export TF_VAR_arm_ssh_key_file ?= $(ARM_SSH_KEY_FILE)
endif

ifneq ($(ARM_DEPT),)
	export TF_VAR_arm_department ?= $(ARM_DEPT)
endif

ifneq ($(ARM_CONTACT),)
	export TF_VAR_arm_contact ?= $(ARM_CONTACT)
endif

ifneq ($(ARM_DEFAULT_LOCATION),)
	export TF_VAR_arm_location ?= $(ARM_DEFAULT_LOCATION)
endif

ifneq ($(ARM_DEFAULT_INSTANCE_TYPE),)
	export TF_VAR_arm_instance_type ?= $(ARM_DEFAULT_INSTANCE_TYPE)
endif

ifneq ($(SERVER_PLATFORM),)
	export TF_VAR_server_platform ?= $(SERVER_PLATFORM)
else
	export TF_VAR_server_platform ?= ubuntu-18.04
endif

ifneq ($(WORKSTATION_PLATFORM),)
	export TF_VAR_workstation_platform ?= $(WORKSTATION_PLATFORM)
else
	export TF_VAR_workstation_platform ?= ubuntu-18.04
endif

ifneq ($(NODE_PLATFORMS),)
	export TF_VAR_node_platforms ?= $(NODE_PLATFORMS)
endif

ifneq ($(CLIENT_VERSION),)
    export TF_VAR_client_version ?= $(CLIENT_VERSION)
	export TF_VAR_client_version_url ?= $(shell workstation_platform=$(TF_VAR_workstation_platform); for channel in stable current unstable ; do mixlib-install download chef --url -c $$channel -a x86_64 -p $$(echo $${workstation_platform%-*} | sed 's/rhel/el/') -l $${workstation_platform\#\#*-} -v $(CLIENT_VERSION) 2>/dev/null && break; done | head -n1)
else
    export CLIENT_VERSION ?= $(shell mixlib-install list-versions chef current | tail -n1)
    export TF_VAR_client_version ?= $(CLIENT_VERSION)
	export TF_VAR_client_version_url ?= $(shell workstation_platform=$(TF_VAR_workstation_platform); mixlib-install download chef --url -c current -a x86_64 -p $$(echo $${workstation_platform%-*} | sed 's/rhel/el/') -l $${workstation_platform\#\#*-} -v $(CLIENT_VERSION) 2>/dev/null)
endif

ifneq ($(SERVER_VERSION),)
	export TF_VAR_server_version_url ?= $(shell server_platform=$(TF_VAR_server_platform); for channel in stable current unstable ; do mixlib-install download chef-server --url -c $$channel -a x86_64 -p $$(echo $${server_platform%-*} | sed 's/rhel/el/') -l $${server_platform\#\#*-} -v $(SERVER_VERSION) 2>/dev/null && break; done | head -n1)
else
	export TF_VAR_server_version_url ?= $(shell server_platform=$(TF_VAR_server_platform); mixlib-install download chef-server --url -c stable -a x86_64 -p $$(echo $${server_platform%-*} | sed 's/rhel/el/') -l $${server_platform\#\#*-} -v latest 2>/dev/null)
endif

ifneq ($(SCENARIO),)
	export TF_VAR_scenario ?= $(SCENARIO)
endif

ifeq ($(WORKSPACE),)
	export WORKSPACE = "$(TF_VAR_workstation_platform)_$(TF_VAR_scenario)"
else
	export TF_VAR_workstation_platform = $(shell sed 's/_.*//' <<<$(WORKSPACE))
	export TF_VAR_scenario = $(shell sed 's/_.*//' <<<$(WORKSPACE))
endif

verify-arm:
ifeq ($(TF_VAR_arm_department),)
	$(error The department that owns the resources must be provided via the "ARM_DEPT" environment variable.)
endif

ifeq ($(TF_VAR_arm_contact),)
	$(error The primary contact for the resources must be provided via the "ARM_CONTACT" environment variable.)
endif

create-resource-group: verify-arm
	@set -e; \
	cd modules/arm_resource_group && \
	rm -rf .terraform && \
	terraform init && \
	terraform apply -auto-approve

create-chef-server: verify-arm
	@set -e; \
	cd modules/arm_chef_server && \
	rm -rf .terraform && \
	terraform init && \
	terraform apply -auto-approve

show-resource-group: verify-arm
	@set -e; \
	cd modules/arm_resource_group && \
	terraform show

show-chef-server: verify-arm
	@set -e; \
	cd modules/arm_chef_server && \
	terraform show

destroy-resource-group: verify-arm
	@set -e; \
	cd modules/arm_resource_group && \
	terraform destroy -auto-approve && \
	rm -rf .terraform terraform.tfstate*

destroy-chef-server: verify-arm
	@set -e; \
	cd modules/arm_chef_server && \
	terraform destroy -auto-approve && \
	rm -rf .terraform terraform.tfstate*

verify-scenario: verify-arm
ifeq ($(TF_VAR_arm_ssh_key_file),)
	$(error The file system path for a SSH public key must be provided via the "ARM_SSH_KEY_FILE" environment variable.)
endif

ifeq ($(TF_VAR_scenario),)
	$(error A valid $(SCENARIO) scenario must be provided via the "SCENARIO" environment variable.)
endif

ifeq ($(TF_VAR_client_version),)
	$(error A chef version must be provided.)
endif

ifeq ($(TF_VAR_client_version_url),)
	$(error A chef artifact couldn't be found of version $(CLIENT_VERSION) for $(TF_VAR_workstation_platform).)
endif

ifeq ($(TF_VAR_server_version_url),)
	$(error A chef-server artifact couldn't be found of version $(SERVER_VERSION) for $(TF_VAR_workstation_platform).)
endif

init: verify-scenario
	@set -e; \
	cd scenarios/$(TF_VAR_scenario) && (test -d .terraform || terraform init) && \
	test -d "terraform.tfstate.d/$(WORKSPACE)" || terraform workspace new "$(WORKSPACE)"

plan: init
	@set -e; \
	echo -e "\n\nGenerating Plan for $(WORKSPACE)\n" && \
	cd scenarios/$(TF_VAR_scenario) && \
	terraform workspace select "$(WORKSPACE)" && \
	terraform plan

show: init
	@set -e; \
	cd scenarios/$(TF_VAR_scenario) && \
	terraform workspace select "$(WORKSPACE)" && \
	terraform show

apply: init
	@set -e; \
	echo -e "\n\nApplying $(WORKSPACE)\n" && \
	cd scenarios/$(TF_VAR_scenario) && \
	terraform workspace select "$(WORKSPACE)" && \
	terraform apply -auto-approve

apply-all:
	@set -e; \
	for scenario in $(SCENARIOS); do \
		workspace="$(TF_VAR_workstation_platform)_$${scenario}"; \
		mkdir -p "scenarios/$${scenario}/terraform.tfstate.d/$$workspace"; \
		output="/tmp/$$workspace.log"; \
		echo -e "\nApplying $$workspace:\n\toutput log can be found in $${output}"; \
		WORKSPACE="$$workspace" $(MAKE) apply > "$$output" 2>&1 & \
		sleep 1; \
	done; \
	echo -en "\nWaiting for scenarios to complete ... "; \
	wait; \
	echo 'Done';

destroy: init
	@set -e; \
	echo -e "\n\nDestroying $(WORKSPACE)\n" && \
	cd scenarios/$(TF_VAR_scenario) && \
	terraform workspace select "$(WORKSPACE)" && \
	terraform destroy -auto-approve && \
	terraform workspace select default && \
	terraform workspace delete $(WORKSPACE) && \
	(rmdir terraform.tfstate.d 2>/dev/null && rm -rf .terraform)

destroy-all:
	@set -e; \
	[ -z "$(WORKSPACES)" ] && exit 0; \
	for workspace in $(WORKSPACES); do \
		echo -e "\nDestroying $$workspace"; \
		WORKSPACE=$$workspace TF_VAR_client_version_url=x TF_VAR_workstation_version_url=x $(MAKE) destroy & \
		sleep 1; \
	done; \
	echo -en "\nWaiting for scenario cleanup to complete ... "; \
	wait; \
	echo 'Done';

clean: destroy-all

list-active-workspaces:
	@set -e; \
	tr ' ' '\n' <<<"$(WORKSPACES)"

# Lint _all_ the directories (including modules)
# terraform fmt will always exit 0, so we need to check to see if the diff
# returns anything in order to determine if lint fails
lint:
	@set -e; \
	LINT_OUTPUT=$$(terraform fmt --recursive --diff --list --write=false ./); \
	if test -n "$$LINT_OUTPUT"; then \
		echo "$$LINT_OUTPUT"; \
		exit 1; \
	fi

.PHONY: create-resource-group create-chef-server show-resource-group show-chef-server destroy-resource-group destroy-chef-server verify-arm verify-scenario init plan show apply apply-all destroy destroy-all clean list-active-workspaces lint
