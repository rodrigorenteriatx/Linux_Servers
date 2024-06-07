data "http" "myip" {
  url = "https://api.ipify.org/"
}

# Variable for key pair
data "tls_public_key" "dns_key" {
    depends_on = [ terraform_data.ssh_keygen ]
    private_key_pem = file("~/.ssh/dns_key")
}

resource "aws_key_pair" "dns_key" {
  depends_on  = [terraform_data.ssh_keygen]
  key_name    = "dns_key"
  public_key  = data.tls_public_key.dns_key.public_key_openssh
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnets
resource "aws_subnet" "main_server_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "client_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

# Internet Gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

# Route Table Associations
resource "aws_route_table_association" "main_server_assoc" {
  subnet_id      = aws_subnet.main_server_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_route_table_association" "client_assoc" {
  subnet_id      = aws_subnet.client_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# Security Groups
resource "aws_security_group" "dns_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]  # Replace with your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [ aws_vpc.main ]
}

resource "aws_security_group" "local_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]  # Replace with your IP (RDP)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]  # Replace with your IP (SSH)
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instances
# resource "aws_instance" "dns_server" {
#   ami             = "ami-00beae93a2d981137" # Amazon Linux 2 AMI
#   instance_type   = "t2.micro"
#   subnet_id       = aws_subnet.main_server_subnet.id
#   key_name        = aws_key_pair.dns_key.key_name
#   vpc_security_group_ids = [ aws_security_group.dns_sg.id ]
#   tags = {
#     Name = "DNS Server"
#   }
#   associate_public_ip_address = true
#   depends_on = [aws_security_group.dns_sg]
# }

resource "aws_instance" "dns_server" {
  ami             = "ami-00beae93a2d981137" # Amazon Linux 2 AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_server_subnet.id
  key_name        = aws_key_pair.dns_key.key_name
  vpc_security_group_ids = [ aws_security_group.dns_sg.id ]
  tags = {
    Name = "DNS Server"
  }
  associate_public_ip_address = true
  depends_on = [aws_security_group.dns_sg]

}



resource "aws_instance" "local_windows_machine" {
  ami             = "ami-0069eac59d05ae12b" # Replace with the latest Windows Server AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.client_subnet.id
  key_name        = aws_key_pair.dns_key.key_name
  vpc_security_group_ids = [aws_security_group.local_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "Local Windows Machine"
  }
  get_password_data = true
  depends_on = [aws_security_group.local_sg]

#   provisioner "file" {
#     source      = resource.local_file.configure-dns.filename
#     destination = "C:\\Windows\\Temp\\configure-dns.ps1"

#     connection {
#       type     = "winrm"
#       user     = "Administrator"
#       password = rsadecrypt(self.password_data, file("~/.ssh/dns_key"))
#       host     = aws_instance.local_windows_machine.public_ip
#     }
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "powershell -ExecutionPolicy Unrestricted -File C:\\Windows\\Temp\\configure-dns.ps1"
#     ]

#     connection {
#       type     = "winrm"
#       user     = "Administrator"
#       password = "${rsadecrypt(aws_instance.local_windows_machine.password_data, file("~/.ssh/dns_key"))}"
#       host     = aws_instance.local_windows_machine.public_ip
#     }
#   }
}
