# Quick Start Guide

## Prerequisites

- A Git repository for SSH keys
- Two Ubuntu 22.04 servers (or compatible)
- SSH access to servers from your control machine
- Ansible installed locally

## 1. Clone and Setup Repository

```bash
git clone git@github.com:your-org/ssh-keys.git
cd ssh-keys

# Verify structure
ls -la
# Should show: servers.yml, groups.yml, access-mapping.yml, groups/, ansible/
```

## 2. Update Configuration Files

### Update `servers.yml` with your servers

Replace IP addresses with your production servers:

```yaml
servers:
  digitalocean-web-01:
    ip_address: YOUR_IP_1
    provider: your_provider
    region: region1
    environment: production
    os: ubuntu-22.04

  hetzner-db-01:
    ip_address: YOUR_IP_2
    provider: your_provider
    region: region2
    environment: production
    os: ubuntu-22.04
```

### Keep `groups.yml` as-is

Currently manages the `devops` user (root privileges).

### Keep `access-mapping.yml` as-is

Grants `devops_team` access to all servers.

## 3. Add SSH Keys

Create team directories and add employee keys:

```bash
# Ensure directory exists
mkdir -p groups/devops_team

# Add an employee's public key
cp /path/to/alice.pub groups/devops_team/
cp /path/to/bob.pub groups/devops_team/

# Verify
ls -la groups/devops_team/
```

## 4. Test the Playbook (Dry Run)

```bash
cd ansible

# Test with static inventory (requires manual editing of inventory file)
ansible-playbook playbook.yml -i inventory --check

# Or test with dynamic inventory
ansible-playbook playbook.yml -i dynamic_inventory.py --check
```

## 5. Run the Playbook

```bash
cd ansible

# Execute the playbook
ansible-playbook -i dynamic_inventory.py playbook.yml

# Monitor output
ansible-playbook -i dynamic_inventory.py playbook.yml -v
```

## 6. Verify Deployment

SSH into a server and check:

```bash
ssh ubuntu@206.189.142.129

# Switch to devops user
sudo su - devops

# View authorized SSH keys
cat ~/.ssh/authorized_keys

# Should list all keys from groups/devops_team/*.pub
```

## 7. Setup CI/CD (GitHub Actions)

1. **Store SSH private key as secret:**
   - Go to GitHub repo → Settings → Secrets and variables → Actions
   - Create new secret: `SSH_PRIVATE_KEY` (paste your private key)

2. **Commit and push:**
   ```bash
   git add .
   git commit -m "Initial SSH key setup"
   git push origin main
   ```

3. **Workflow triggers automatically:**
   - Check Actions tab to see the pipeline run
   - Logs show deployment status

## 8. Onboard an Employee

```bash
# Add their public key
cp ~/Downloads/new_employee.pub groups/devops_team/

# Commit and push (this triggers the pipeline)
git add groups/devops_team/new_employee.pub
git commit -m "Onboard new_employee to devops_team"
git push origin main

# Within 1-2 minutes, they can SSH to all servers
```

## 9. Offboard an Employee

```bash
# Remove their public key
rm groups/devops_team/departing_employee.pub

# Commit and push
git add -A
git commit -m "Offboard departing_employee"
git push origin main

# Access is revoked immediately
```

## 10. Troubleshooting

### Playbook fails with "key not found"
- Verify `inventory_hostname` matches a server ID in `servers.yml`
- Check that server ID exists in `access-mapping.yml`
- Ensure `groups/<groupname>/` directory exists

### SSH connection timeout
- Verify IP addresses in `servers.yml` are correct
- Check firewall rules allow SSH (port 22)
- Ensure SSH key has access to both servers

### authorized_keys not updated
- Check playbook output for errors
- Verify file permissions: `ls -la ~/.ssh/`
- Manually test with: `ansible-playbook playbook.yml -l digitalocean-web-01 -vv`

### Dynamic inventory returns empty
```bash
python3 dynamic_inventory.py --list
# Should return server information from servers.yml
```

---

For full documentation, see [README.md](../README.md)
