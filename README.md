# OpenShift/OKD on Proxmox with Ansible

This repository contains Ansible playbooks to automate the deployment of OpenShift/OKD clusters on Proxmox VE infrastructure.

## Summary

### What You Should Have
Before starting this automation, ensure you have:

**Infrastructure Requirements:**
- A working Proxmox VE 6.x+ hypervisor with sufficient resources
- At least 64GB RAM and 500GB storage available for the cluster
- A dedicated bastion/helper VM (8GB RAM, 4 vCPU, 100GB disk minimum)
- Network subnet with DHCP range available for cluster VMs

**Access Requirements:**
- Root or administrative access to your Proxmox host
- SSH access to your bastion/helper VM
- Network connectivity between all components

**Knowledge Requirements:**
- Basic understanding of Ansible playbooks
- Familiarity with OpenShift/OKD concepts
- Basic Linux system administration skills
- Understanding of virtualization and networking concepts

### What You Will Get
Upon successful completion, you will have:

**A Fully Operational OpenShift/OKD Cluster:**
- 3 control plane nodes (highly available master nodes)
- Configurable number of worker nodes (default: 2, can be scaled)
- Bootstrap node automatically provisioned and cleaned up
- All VMs running CoreOS/RHCOS with proper ignition configs

**Complete Infrastructure Services:**
- DNS server (BIND) with proper cluster records
- DHCP server with reserved IP assignments for all cluster nodes
- Load balancer (HAProxy) for API and ingress traffic
- All services configured for high availability

**Ready-to-Use Cluster:**
- OpenShift/OKD web console accessible via browser
- kubectl/oc command-line access configured
- All cluster operators installed and operational
- Ready for application deployments and day-2 operations

**Automation Benefits:**
- Repeatable, idempotent deployments
- Consistent cluster configurations
- Automated cleanup and rollback capabilities
- Infrastructure as code approach for cluster lifecycle management

## Security Notice

**This repository has been secured and uses Ansible Vault for sensitive data protection.**

Before using this repository:
1. Read the [SECURITY.md](SECURITY.md) file carefully
2. Set up your secrets and inventory files properly
3. Never commit unencrypted sensitive data

## Architecture

This automation handles the complete OpenShift/OKD deployment pipeline on Proxmox VE:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Proxmox VE Hypervisor                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────────────────────────────────────┐  │
│  │   Bastion VM    │  │              OpenShift/OKD Cluster               │  │
│  │                 │  │                                                  │  │
│  │ • DNS (BIND)    │  │  ┌────────────┐  ┌──────────────────────────┐    │  │
│  │ • DHCP          │  │  │ Bootstrap  │  │     Control Plane        │    │  │
│  │ • HAProxy (LB)  │  │  │    VM      │  │                          │    │  │
│  │ • Ansible       │  │  │            │  │  ┌─────┐ ┌─────┐ ┌─────┐ │    │  │
│  │ • OC Client     │  │  └────────────┘  │  │CP-1 │ │CP-2 │ │CP-3 │ │    │  │
│  │                 │  │                  │  └─────┘ └─────┘ └─────┘ │    │  │
│  └─────────────────┘  │                  └──────────────────────────┘    │  │
│                       │                                                  │  │
│  ┌─────────────────┐  │  ┌──────────────────────────────────────────┐    │  │
│  │ CoreOS Template │  │  │          Worker Nodes                    │    │  │
│  │      VM         │  │  │                                          │    │  │
│  │                 │  │  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐         │    │  │
│  │ • QCOW2 Import  │  │  │  │WN-1 │ │WN-2 │ │WN-3 │ │WN-N │         │    │  │
│  │ • Cloud-Init    │  │  │  └─────┘ └─────┘ └─────┘ └─────┘         │    │  │
│  │ • Template      │  │  └──────────────────────────────────────────┘    │  │
│  └─────────────────┘  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘

                              Network Flow
        ┌─────────────────┐           ┌─────────────────┐
        │   Ansible       │    SSH    │    Proxmox      │
        │  Controller     │ ◄────────►│   VE Host       │
        │  (Local/CI)     │    API    │                 │
        └─────────────────┘           └─────────────────┘
                │                              │
                │ Playbooks                    │ VM Management
                ▼                              ▼
        ┌─────────────────┐           ┌─────────────────┐
        │   Bastion VM    │   DHCP    │  OpenShift VMs  │
        │ • DNS Server    │ ◄────────►│ • Bootstrap     │
        │ • DHCP Server   │  Network  │ • Control Plane │
        │ • Load Balancer │  Services │ • Worker Nodes  │
        └─────────────────┘           └─────────────────┘
```

### Deployment Process

1. **Downloads and Setup** - OCP/OKD clients and CoreOS images
2. **VM Template Creation** - Import and configure CoreOS template
3. **VM Deployment** - Clone VMs for bootstrap, control plane, and compute nodes
4. **Network Configuration** - DNS, DHCP, and load balancer setup
5. **Cluster Installation** - Bootstrap and complete cluster deployment

### Technical Details: Ignition Configuration Delivery

This automation uses QEMU's [Firmware Configuration (fw_cfg) device](https://www.qemu.org/docs/master/specs/fw_cfg.html) to deliver ignition files to RHCOS VMs. When each VM is created, the playbooks automatically configure the following QEMU argument:

```
-fw_cfg name=opt/com.coreos/config,file=/path/to/ignition/file.ign
```

**How it Works:**

1. **Ignition File Generation** - OpenShift installer creates ignition files (bootstrap.ign, master.ign, worker.ign)
2. **fw_cfg Configuration** - Each VM gets the appropriate ignition file via QEMU's firmware configuration interface
3. **RHCOS Boot Process** - During boot, RHCOS automatically reads the ignition configuration from fw_cfg
4. **System Configuration** - RHCOS applies the ignition config to set up networking, certificates, and services

**Per VM Type:**
- **Bootstrap VM**: Uses `bootstrap.ign` for temporary cluster initialization
- **Control Plane VMs**: Use `master.ign` for etcd and control plane configuration  
- **Worker VMs**: Use `worker.ign` for compute node configuration

This method eliminates the need for external configuration servers or manual intervention during the boot process. The ignition files contain all necessary configuration including network settings, certificates, and systemd units required for the OpenShift cluster.

**Reference**: [Proxmox ignition file howto](https://forum.proxmox.com/threads/howto-startup-vm-using-an-ignition-file.63782/)

## Prerequisites

- Proxmox VE 6.x+
- Ansible 2.9+
- Python 3.6+
- A bastion host for DNS/DHCP/HAProxy services
- Network access to download OpenShift/OKD resources

## Quick Setup

### 1. Configure Secrets (IMPORTANT!)

```bash
# Copy and configure secrets
cp vars/secrets.yml.example vars/secrets.yml
vim vars/secrets.yml  # Add your actual credentials

# Encrypt the secrets file
ansible-vault encrypt vars/secrets.yml
```

### 2. Configure Inventory

```bash
# Copy and configure inventory
cp inventory/hosts.example inventory/hosts
vim inventory/hosts  # Add your actual IP addresses
```

### 3. Update Configuration

Copy and customize the configuration files:
```bash
# Core configuration
cp vars/config.yml.example vars/config.yml
cp vars/proxmox.yml.example vars/proxmox.yml
cp vars/vm_info.yml.example vars/vm_info.yml

# Edit with your environment details
vim vars/config.yml      # OpenShift cluster configuration
vim vars/proxmox.yml     # Proxmox node details  
vim vars/vm_info.yml     # VM and network configuration
```

**Note**: The `files/install-config.yaml` is auto-generated from templates - don't edit it directly!

### 4. Run the Deployment

```bash
# Run complete deployment
ansible-playbook main.yml --ask-vault-pass

# Or run individual steps
ansible-playbook 01_dloads.yml --ask-vault-pass
ansible-playbook 02_ocp_preinstall.yml --ask-vault-pass
ansible-playbook 03_vm_template.yml --ask-vault-pass
ansible-playbook 04_create_vms.yml --ask-vault-pass
```

## Project Structure

```
├── vars/
│   ├── secrets.yml.example    # Template for sensitive data
│   ├── config.yml            # OpenShift configuration
│   ├── proxmox.yml           # Proxmox settings
│   └── vm_info.yml           # VM and network details
├── inventory/
│   └── hosts.example         # Template for inventory
├── roles/                    # Ansible roles
├── playbooks/               # Additional playbooks
├── templates/               # Jinja2 templates
└── SECURITY.md             # Security guidelines
```

## Deployment Steps

### 1. Downloads (`01_dloads.yml`)
- Downloads OpenShift/OKD clients
- Downloads CoreOS QCOW2 images
- Sets up local file structure

### 2. Pre-installation (`02_ocp_preinstall.yml`)
- Generates ignition files
- Configures install-config.yaml
- Prepares installation artifacts

### 3. VM Template (`03_vm_template.yml`)
- Imports CoreOS QCOW2 to Proxmox
- Creates and configures VM template
- Optimizes template for cloning

### 4. VM Creation (`04_create_vms.yml`)
- Clones VMs from template
- Configures bootstrap, control plane, and compute nodes
- Updates network services (DNS, DHCP, HAProxy)

### 5. Cluster Installation
- Manual monitoring of bootstrap process
- Cleanup of bootstrap resources
- Completion of worker node setup

## Configuration Files

### Core Variables

- **`vars/config.yml`**: Main cluster configuration (domain, networking, versions)
- **`vars/vm_info.yml`**: VM specifications and IP assignments
- **`vars/proxmox.yml`**: Proxmox connection details

### Sensitive Variables (Encrypted)

- **`vars/secrets.yml`**: Proxmox credentials, SSH keys, pull secrets

### Templates

- **`templates/ocp/install-config.yaml.j2`**: OpenShift install-config template
- **`templates/ocp/install-config-okd.yaml.j2`**: OKD install-config template  
- **`templates/dhcpd/`**: DHCP configuration templates
- **`templates/haproxy/`**: Load balancer configuration

#### Template Features

The install-config templates support:
- **Dynamic registry mirrors**: Configure custom registry mirrors in `vars/config.yml`
- **Flexible cluster sizing**: Override default master/worker replica counts
- **Additional trust bundles**: Add custom CA certificates
- **Environment-specific configuration**: Different settings for dev/prod

#### Customizing Registry Mirrors

To use custom registry mirrors, add this to your `vars/config.yml`:

```yaml
openshift:
  registry:
    mirrors:
      - mirror_registry: "your-registry.example.com"
        path: "ocp4/openshift"  # or "okd4/okd" for OKD
        source: "quay.io/openshift-release-dev/ocp-release"
      - mirror_registry: "your-registry.example.com"
        path: "ocp4/openshift" 
        source: "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
```

If not specified, defaults to the existing nexus-local configuration.

## Monitoring and Troubleshooting

### Check Bootstrap Progress
```bash
# Monitor bootstrap
ssh core@bootstrap-node-ip
sudo journalctl -b -f -u release-image.service -u bootkube.service

# Check cluster operators
oc get clusteroperators
```

### Common Issues

1. **Network connectivity**: Ensure proper DHCP/DNS configuration
2. **Certificate issues**: Check system time synchronization
3. **Resource constraints**: Verify VM memory/CPU allocations
4. **Storage**: Ensure adequate disk space on Proxmox

## Cleanup

```bash
# Clean up VMs and resources
ansible-playbook site.yml --tags cleanup --ask-vault-pass
```

## References

- [OpenShift Documentation](https://docs.openshift.com/)
- [OKD Documentation](https://docs.okd.io/)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Ansible Documentation](https://docs.ansible.com/)

## Important Notes

- **Always encrypt sensitive files** with `ansible-vault`
- **Never commit real credentials** to version control
- **Test in non-production** environments first
- **Backup Proxmox** before major operations
- **Review security settings** regularly

## Contributing

1. Follow security guidelines in `SECURITY.md`
2. Test changes in isolated environments
3. Update documentation for new features
4. Never commit sensitive data

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

## About

Automated OpenShift/OKD deployment on Proxmox VE using Ansible playbooks.

### Resources

* Readme
* [Security Guide](SECURITY.md)

### License

Apache-2.0 license

---

For detailed security information, see [SECURITY.md](SECURITY.md)
