---

# VPC Setup with DNS Configuration using BIND

This project automates the setup of a Virtual Private Cloud (VPC) on AWS, including essential network resources, two instances (Linux and Windows Server 2022), and configuration of BIND as the DNS server for the Windows client. Additionally, the project ensures necessary ports are open for Windows Remote Desktop Protocol (RDP), SSH, and DNS communication. An Ansible script is utilized to automate the configuration process.

## Features

- Automated provisioning of a complete VPC setup on AWS.
- Configuration of network resources, including subnets, route tables, and security groups.
- Deployment of Linux and Windows Server 2022 instances within the VPC.
- Utilization of BIND to configure the Linux server as the DNS server for the Windows client.
- Setup of security group rules to allow RDP, SSH, and DNS traffic between instances.
- Ansible script for automating the configuration and setup process.
