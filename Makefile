# Makefile for SSH key management

.PHONY: help validate test deploy check-config show-inventory verify-keys

help:
	@echo "SSH Key Management - Available Commands"
	@echo ""
	@echo "Configuration:"
	@echo "  make check-config        Validate YAML configuration files"
	@echo "  make show-inventory      Display dynamic inventory"
	@echo ""
	@echo "Testing (Dry Run):"
	@echo "  make test                Run playbook in check mode"
	@echo "  make validate            Validate playbook syntax only"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy              Deploy SSH keys to all servers"
	@echo "  make deploy-server=NAME  Deploy to a specific server"
	@echo "  make verify-keys         Verify keys on all servers"
	@echo ""
	@echo "Troubleshooting:"
	@echo "  make debug               Run playbook with debug output"
	@echo ""

check-config:
	@echo "Validating configuration files..."
	@python3 -c "import yaml; yaml.safe_load(open('servers.yml')); print('✓ servers.yml valid')"
	@python3 -c "import yaml; yaml.safe_load(open('groups.yml')); print('✓ groups.yml valid')"
	@python3 -c "import yaml; yaml.safe_load(open('access-mapping.yml')); print('✓ access-mapping.yml valid')"
	@echo "All configuration files are valid!"

show-inventory:
	@echo "Current inventory (from servers.yml):"
	@cd ansible && python3 dynamic_inventory.py --list | python3 -m json.tool

validate:
	@echo "Validating playbook syntax..."
	@cd ansible && ansible-playbook playbook.yml --syntax-check

test: validate
	@echo "Running playbook in check mode (dry run)..."
	@cd ansible && ansible-playbook -i dynamic_inventory.py playbook.yml --check -v

deploy: check-config validate
	@echo "Deploying SSH keys to all servers..."
	@cd ansible && ansible-playbook -i dynamic_inventory.py playbook.yml

ifdef deploy-server
deploy-server: check-config validate
	@echo "Deploying SSH keys to $(deploy-server)..."
	@cd ansible && ansible-playbook -i dynamic_inventory.py playbook.yml -l $(deploy-server)
endif

verify-keys:
	@echo "Verifying SSH keys on all servers..."
	@cd ansible && ansible -i dynamic_inventory.py servers -m command -a "find /home/*/\.ssh/authorized_keys -exec wc -l {} \; 2>/dev/null || echo 'No keys found'"

debug: check-config validate
	@echo "Running playbook with debug output..."
	@cd ansible && ansible-playbook -i dynamic_inventory.py playbook.yml -vvv

.DEFAULT_GOAL := help
