provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAVRUVPMRC2S2QUFNG"
  secret_key = "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"
}

# Create VPC

resource "aws_vpc" "myvpc1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc1"
  }
}

# Create Subnet 

resource "aws_subnet" "mysubnet1" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "mysubnet1"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "mygw1" {
  vpc_id = aws_vpc.myvpc1.id

  tags = {
    Name = "mygw1"
  }
}

# Route Table

resource "aws_route_table" "myrt1" {
  vpc_id = aws_vpc.myvpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw1.id
  }

  tags = {
    Name = "myrt1"
  }
}

# Route Table Association

resource "aws_route_table_association" "myrta1" {
  subnet_id      = aws_subnet.mysubnet1.id
  route_table_id = aws_route_table.myrt1.id
}

# Security Groups

resource "aws_security_group" "mysg1" {
  name        = "mysg1"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
   description = "HTTPS traffic"
   from_port = 443
   to_port = 443
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
   description = "HTTP traffic"
   from_port = 0
   to_port = 65000
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mysg1"
  }
}

#Creating a new network interface
resource "aws_network_interface" "myni1" {
 subnet_id = aws_subnet.mysubnet1.id
 private_ips = ["10.0.0.10"]
 security_groups = [aws_security_group.mysg1.id]
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "myeip1" {
 vpc = true
 network_interface = aws_network_interface.myni1.id
 associate_with_private_ip = "10.0.0.1"
}

# Create Instance

resource "aws_instance" "testserver" {
  ami           = "ami-04f8d7ed2f1a54b14"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.mysubnet1.id
  vpc_security_group_ids = [aws_security_group.mysg1.id]
  key_name = "ss"
  network_interface {
 device_index = 0
 network_interface_id = ws_network_interface.myni1.id
 }
 user_data  = <<-EOF
 #!/bin/bash
     sudo apt-get update -y
 EOF

  tags = {
    Name = "TF-PROJECT"
  }
}