output "windows_client_ip" {
    value = aws_instance.local_windows_machine.public_ip

}

output "dns_ip" {
    value = aws_instance.dns_server.public_ip
}

resource "local_file" "hosts_ini" {
    filename = "hosts.ini"
    content = <<EOF
    [dns_server]
    ${aws_instance.dns_server.public_ip}
    [windows_client]
    ${aws_instance.local_windows_machine.public_ip}
    #Youre gonna need to configure winrm
    EOF

}
resource "local_file" "ansible.cfg" {
  filename = "ansible.cfg"
  content =  <<EOF
  [defaults]
  inventory = ${local_file.hosts_ini.filename}
  remote_user = ec2-user
  host_key_checking = False
  retry_files_enabled = False
  command_warnings = False
  roles_path = ./roles
  private_key_file= ~/.ssh/dns_key

  [privilege_escalation]
  become = True
  become_method = sudo
  become_user = root
  become_ask_pass = False
  EOF

}

# output "decrytpted_password" {
#     value = rsadecrypt(aws_instance.local_windows_machine.password_data, file("~/.ssh/dns_key"))
# }

resource "local_file" "named_conf" {
    filename = "named.conf"
    content = <<EOF
options {
        listen-on port 53 { 127.0.0.1; ${aws_instance.dns_server.private_ip}; };
        # listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { localhost; ${aws_subnet.client_subnet.cidr_block}; ${aws_subnet.main_server_subnet.cidr_block} ;};
        forwarders { 10.0.0.2; };

        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;

        dnssec-validation yes;

        managed-keys-directory "/var/named/dynamic";
        geoip-directory "/usr/share/GeoIP";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";

        /* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
        include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

}

resource "local_file" "ip_passwords" {
  content  = "Windows Client IP: ${aws_instance.local_windows_machine.public_ip} : ${rsadecrypt(aws_instance.local_windows_machine.password_data, file("~/.ssh/dns_key"))} : Administrator \nLinux Client IP: ${aws_instance.dns_server.public_ip}\n"
  filename = "${path.module}/ips_passwords.txt"
  depends_on = [ aws_instance.dns_server, aws_instance.local_windows_machine ]
}

resource "terraform_data" "ssh_keygen" {
  provisioner "local-exec" {
    command = "test -f ~/.ssh/dns_key || ssh-keygen -t rsa -f -m PEM ~/.ssh/dns_key -N ''"
  }

}

resource "local_file" "windows_password_data" {
    filename = "${path.module}/windows_password_data.txt"
    depends_on = [ aws_instance.local_windows_machine ]
    content = aws_instance.local_windows_machine.password_data

}

resource "local_file" "configure-dns" {
    filename = "configure-dns.ps1"
    content = <<EOF
    # PowerShell script to configure DNS server on Windows
    $InterfaceName = "Ethernet 2" #
    $PrimaryDNS = "${aws_instance.dns_server.private_ip}"

    # Set the primary DNS server
    netsh interface ip set dns name="$InterfaceName" source=static addr=$PrimaryDNS

EOF

}
