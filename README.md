---

# Provisioning VPC, Instances, BIND DNS, and Ansible Automation with Terraform

This project automates the provisioning of a Virtual Private Cloud (VPC) along with essential network resources using Terraform. It includes setting up two instances: a Linux server and a Windows Server 2022, with the Linux server configured as the DNS server for the Windows client using BIND. Additionally, the setup ensures necessary network configurations such as allowing ports for Windows console access (RDP, SSH) and DNS.

## Features

- Automated provisioning of AWS VPC and associated network resources using Terraform.
- Configuration of a Linux server as a DNS server for a Windows Server 2022 client using BIND.
- Setup of security group rules to allow ports for console access (RDP, SSH) and DNS communication.
- Utilization of Ansible for automating configuration management across provisioned instances.

## Details

- **Network Infrastructure**: Provisioned a complete VPC setup including subnets, route tables, and internet gateway.
- **Instances**: Deployed two instances on AWS: a Linux server and a Windows Server 2022.
- **DNS Configuration**: Configured BIND on the Linux server to act as the DNS server for the Windows client.
- **Security**: Implemented security group rules to allow specific ports required for console access and DNS operations.
- **Automation**: Developed an Ansible script to automate configuration tasks across the provisioned instances.
