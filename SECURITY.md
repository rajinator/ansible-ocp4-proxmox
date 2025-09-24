# Security Guidelines

This repository has been configured to protect sensitive data using Ansible Vault and secure configuration practices.

## Setting Up Secrets

### 1. Configure Secrets File

```bash
# Copy the example secrets file
cp vars/secrets.yml.example vars/secrets.yml

# Edit with your actual values
vim vars/secrets.yml

# Encrypt the file with Ansible Vault
ansible-vault encrypt vars/secrets.yml
```

### 2. Configure Inventory

```bash
# Copy the example inventory
cp inventory/hosts.example inventory/hosts

# Edit with your actual IP addresses and hostnames
vim inventory/hosts
```

## Working with Ansible Vault

### Encrypting Files
```bash
# Encrypt a file
ansible-vault encrypt vars/secrets.yml

# Encrypt multiple files
ansible-vault encrypt vars/secrets.yml inventory/hosts
```

### Editing Encrypted Files
```bash
# Edit encrypted file (will prompt for vault password)
ansible-vault edit vars/secrets.yml
```

### Running Playbooks with Encrypted Files
```bash
# Method 1: Prompt for password
ansible-playbook main.yml --ask-vault-pass

# Method 2: Use password file (secure the password file!)
echo "your-vault-password" > .vault-password
chmod 600 .vault-password
ansible-playbook main.yml --vault-password-file .vault-password

# Method 3: Use environment variable
export ANSIBLE_VAULT_PASSWORD=your-vault-password
ansible-playbook main.yml
```

## Security Checklist

### Before First Commit
- [ ] All sensitive values replaced with placeholders
- [ ] `vars/secrets.yml` is encrypted with ansible-vault
- [ ] Real inventory file is not committed (use `inventory/hosts.example`)
- [ ] `.gitignore` includes sensitive file patterns
- [ ] No SSH private keys in repository

### Regular Security Practices
- [ ] Rotate Proxmox credentials regularly
- [ ] Use strong, unique passwords
- [ ] Keep vault passwords secure and separate from code
- [ ] Review `.gitignore` before adding new files
- [ ] Use separate SSH keys for different environments

### Sensitive Files (Should NOT be committed)
- `vars/secrets.yml` (should be encrypted)
- `inventory/hosts` (contains real IPs)
- `*.key`, `*.pem` (SSH/TLS keys)
- `.vault-password` (vault password file)

### Safe to Commit
- `vars/secrets.yml.example`
- `inventory/hosts.example`
- Encrypted `vars/secrets.yml` (after `ansible-vault encrypt`)

## If Secrets Are Exposed

If sensitive data was accidentally committed:

1. **Immediately rotate all exposed credentials**
   - Change Proxmox passwords
   - Generate new API tokens
   - Generate new SSH keys

2. **Clean git history**
   ```bash
   # Remove sensitive files from git history
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch vars/secrets.yml' \
   --prune-empty --tag-name-filter cat -- --all
   
   # Force push (coordinate with team!)
   git push origin --force --all
   ```

3. **Update repository protection**
   - Review who has access
   - Enable branch protection
   - Add pre-commit hooks

## Environment Variables

For CI/CD pipelines, use environment variables instead of files:

```bash
# Set in your CI/CD system
PROXMOX_API_TOKEN_ID=your-token-id
PROXMOX_API_TOKEN_SECRET=your-token-secret
PROXMOX_API_PASSWORD=your-password
OPENSHIFT_SSH_KEY=your-ssh-public-key
```

## Auditing

Regularly audit the repository:

```bash
# Search for potential secrets
grep -r "password\|secret\|key\|token" . --exclude-dir=.git

# Check for IP addresses
grep -r "192\.168\|10\.\|172\." . --exclude-dir=.git

# Verify encrypted files
file vars/secrets.yml  # Should show "data" not "text"
```
