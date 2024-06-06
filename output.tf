output "windows_client_ip" {
    value = aws_instance.local_windows_machine.public_ip

}

output "dns_ip" {
    value = aws_instance.dns_server.public_ip
}

resource "local_file" "ips" {
  content  = "Windows Client IP: ${aws_instance.local_windows_machine.public_ip}\nLinux Client IP: ${aws_instance.dns_server.public_ip}\n"
  filename = "${path.module}/ips.txt"
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
