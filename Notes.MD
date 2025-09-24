# Notes

What are we automating?

## High Level

1. Get clients and OS - Done
2. Create template VM - Done
3. Import OS QCOW2
   - set bootdisk - Done
   - serial - Done
   - expand disk - WIP
4. Mark VM as template - WIP
5. Clone VMs - WIP
6. Update DNS
7. DHCP mac address update, HAProxy update
8. Kick off Bootstrap (Start Bootstrap and CP VMs)
9. Terminate bootstrap, remove from dhcp, lb and dns
10. Start Compute VMs
11. Wait for Cluster install to finish

## Where will this run?

1. Bastion VM and proxmox node
   - DHCP
   - HAProxy
   - Clients,OS
   - Ansible
   - Proxmox will be used to import OS

**OR**

2. Mix of local, bastion (helper) and proxmox node
   - Local is ansible controller
   - Bastion will have DHCP, HAProxy, Clients, OS
   - Proxmox will be used to import OS - either from local or bastion