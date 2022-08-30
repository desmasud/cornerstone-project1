provider "aws" {
  region = "us-east-1"
  

# Creat vpc and security group for our instance
resource "aws_vpc" "docker-vpc" {
  cidr_block = "10.0.0.0/25"
  tags = {
    "Name" = "docker-vpc"
  }
}

resource "aws_subnet" "docker-subnet1" {
  vpc_id = aws_vpc.docker-vpc.id
  cidr_block = "10.0.0.0/26"
  availability_zone = "us-east-1b"
  tags = {
    "Name" = "docker-subnet1"
  }
}
resource "aws_security_group" "docker-sg" {
  name = "docker-sg"
  description = "allow http to ec2"
  vpc_id = aws_vpc.docker-vpc.id

   ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/25"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }

  tags = {
    Name = "docker-sg"
  }
}

# Create ec2 instance
resource "aws_instance" "docker-server" {
    subnet_id = aws_subnet.docker-subnet1.id
  ami ="ami-05fa00d4c63e32376"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.docker-sg.id ]
  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo yum service docker start
sudo usermod -a -G docker ec2-user
 EOF

  tags = {
    "Name" = "docker-server"
  }
}