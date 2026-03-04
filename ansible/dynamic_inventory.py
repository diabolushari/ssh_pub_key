#!/usr/bin/env python3
"""
Dynamic inventory script for Ansible.
Reads servers.yml and generates Ansible inventory format.

Usage:
  ansible-playbook -i ansible/dynamic_inventory.py playbook.yml
"""

import json
import yaml
import sys
import os

def get_inventory():
    """Load servers from servers.yml and return Ansible inventory."""
    
    # Find the repo root or use current directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)  # Go up one level from ansible/
    servers_file = os.path.join(repo_root, 'servers.yml')
    
    inventory = {
        'all': {
            'hosts': {},
            'vars': {
                'ansible_python_interpreter': '/usr/bin/python3',
                'ansible_user': 'ubuntu',
            }
        },
        'servers': {
            'hosts': [],
            'vars': {}
        },
        '_meta': {
            'hostvars': {}
        }
    }
    
    # Read servers.yml if it exists
    if os.path.exists(servers_file):
        try:
            with open(servers_file, 'r') as f:
                config = yaml.safe_load(f)
                servers = config.get('servers', {})
                
                for server_id, server_config in servers.items():
                    ip_address = server_config.get('ip_address')
                    
                    # Add to all.hosts
                    inventory['all']['hosts'][server_id] = {
                        'ansible_host': ip_address
                    }
                    
                    # Add to servers group
                    inventory['servers']['hosts'].append(server_id)
                    
                    # Store host variables
                    inventory['_meta']['hostvars'][server_id] = {
                        'server_id': server_id,
                        'provider': server_config.get('provider'),
                        'region': server_config.get('region'),
                        'environment': server_config.get('environment'),
                        'os': server_config.get('os'),
                        'description': server_config.get('description'),
                        'ansible_host': ip_address
                    }
        except Exception as e:
            sys.stderr.write(f"Error reading {servers_file}: {e}\n")
            return inventory
    
    return inventory

def main():
    """Main entry point."""
    if len(sys.argv) == 2 and sys.argv[1] == '--list':
        # List mode
        inventory = get_inventory()
        print(json.dumps(inventory, indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == '--host':
        # Host mode
        host = sys.argv[2]
        inventory = get_inventory()
        hostvars = inventory.get('_meta', {}).get('hostvars', {}).get(host, {})
        print(json.dumps(hostvars, indent=2))
    else:
        sys.stderr.write("Usage: dynamic_inventory.py --list | --host <hostname>\n")
        sys.exit(1)

if __name__ == '__main__':
    main()
