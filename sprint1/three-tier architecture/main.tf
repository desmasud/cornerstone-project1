provider "aws" {
  region = "us-east-1"
}
data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }
}


# Create VPC
resource "aws_vpc" "aws-3-tier-vpc" {
  cidr_block = "10.0.0.0/16"
tags = {
  "Name" = "aws-3-tier-vpc"
}
}

# Create 2 public subnet for web-tier 2 private subnet for app-tier and 2 for database-tier. A total of 6 subnet

# Public subnet at AZ1
resource "aws_subnet" "web-tier-az1-subnet" {
    vpc_id = aws_vpc.aws-3-tier-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "az1-web-tier subnet"
  }
}

# Public subnet at AZ2
resource "aws_subnet" "web-tier-az2-subnet" {
    vpc_id = aws_vpc.aws-3-tier-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "az2-web-tier subnet"
  }
}

# Private subnet at AZ1
resource "aws_subnet" "app-tier-az1-subnet" {
    vpc_id = aws_vpc.aws-3-tier-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "az1-app-tier subnet"
  }
}

# Private subnet at AZ2
resource "aws_subnet" "app-tier-az2-subnet" {
    vpc_id = aws_vpc.aws-3-tier-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "az2-app-tier subnet"
  }
}

# Private subnet for database at AZ1
resource "aws_subnet" "DB-tier-az1-subnet" {
    vpc_id = aws_vpc.aws-3-tier-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "az1-DB-tier subnet"
  }
}

# Private subnet at AZ2
resource "aws_subnet" "DB-tier-az2-subnet" {
    vpc_id = aws_vpc.aws-3-tier-vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "az2-DB-tier subnet"
  }
}

# Create one Internet gateway and 2 NAT gateway for webtier and apptier respectively
# Internet Gateway (IG)
resource "aws_internet_gateway" "three-tier-ig" {
  vpc_id = aws_vpc.aws-3-tier-vpc.id

  tags = {
    Name = "Three-tier-ig"
  }
}

# Create eip for nat gateway
resource "aws_eip" "three-tier-eip1" {
  vpc = true
  tags = {
    "Name" = "nat-eip"
  }
 
}
# Nat gateway
resource "aws_nat_gateway" "natgateway-az1" {
  allocation_id = aws_eip.three-tier-eip1.id
  subnet_id = aws_subnet.app-tier-az1-subnet.id

  tags = {
    "Name" = "NAT-Gateway-az1"
  }

}
resource "aws_eip" "three-tier-eip2" {
  vpc = true
  tags = {
    "Name" = "nat-eip"
  }
 
}
resource "aws_nat_gateway" "natgateway-az2" {
  allocation_id = aws_eip.three-tier-eip2.id
  subnet_id = aws_subnet.app-tier-az2-subnet.id

  tags = {
    "Name" = "NAT-Gateway-az2"
  }

}

# Create routetable for internet gateway and nat gateway and associate it with the respect subnet id
resource "aws_route_table" "web-tier-rtb" {
  vpc_id = aws_vpc.aws-3-tier-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three-tier-ig.id
  }
  tags = {
    "Name" = "Public-routetable"
  }
}

# Create association between route table and public subnet inorder the internate to work.
resource "aws_route_table_association" "az1-association" {
  subnet_id = aws_subnet.web-tier-az1-subnet.id
  route_table_id = aws_route_table.web-tier-rtb.id
}
resource "aws_route_table_association" "az2-association" {
  subnet_id = aws_subnet.web-tier-az2-subnet.id
  route_table_id = aws_route_table.web-tier-rtb.id
}

# Create route table for each app layer private subnet and associate them with the respect subnet group
resource "aws_route_table" "privateRT-az1" {
  vpc_id = aws_vpc.aws-3-tier-vpc.id
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgateway-az1.id
}
tags = {
  "Name" = "privateRT-az1"
}
}
# Create association b/n route table and private subnet
resource "aws_route_table_association" "private-az1" {
  subnet_id = aws_subnet.app-tier-az1-subnet.id
  route_table_id = aws_route_table.privateRT-az1.id
}
# create route table for availability zone 2
resource "aws_route_table" "privateRT-az2" {
  vpc_id = aws_vpc.aws-3-tier-vpc.id
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgateway-az2.id
}
tags = {
  "Name" = "privateRT-az2"
}
}
# Create association b/n route table and private subnet
resource "aws_route_table_association" "private-az2" {
  subnet_id = aws_subnet.app-tier-az2-subnet.id
  route_table_id = aws_route_table.privateRT-az2.id
}

# Create security groups for each tier and loud balance
# Security group for internet facing load balancing
resource "aws_security_group" "internet-facing-lb-sg" {
  name = "internet facing lb"
  description = "allow connection between my ip address"
  vpc_id = aws_vpc.aws-3-tier-vpc.id
/*ingress {
    description = "allow http "
    from_port = 80
    to_port = 80
    protocol = "tcp"
  
}*/
egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
tags = {
  "Name" = "Internate-facing-LB-sg"
}
}

# Create security group for web-tier instance
resource "aws_security_group" "web-tier-sg" {
  name = "web-tier-sg"
  description = "sg for the web tier"
  vpc_id = aws_vpc.aws-3-tier-vpc.id
  /*ingress {
    description = "allow traffic from my ip"
    from_port = 80
    to_port = 80
    protocol = "tcp"
   
  }*/
ingress {
    description = "allow traffic from my internetfacing laodbalace"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [ aws_security_group.internet-facing-lb-sg.id ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  tags = {
    "Name" = "web-tier-sg"
  }
}
# Create security group for internal laod balancing
resource "aws_security_group" "internal-lb-sg" {
  name = "internal-lb-sg"
  description = "sg for internal load balancing"
  vpc_id = aws_vpc.aws-3-tier-vpc.id
ingress {
    description = "allow traffic from web tier sg"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [ aws_security_group.web-tier-sg.id ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  tags = {
    "Name" = "internal-lb-sg"
  }
}
 # Create security group for app tier private subnet group

resource "aws_security_group" "app-tier-sg" {
  name = "app-tier-sg"
  description = "sg for the app tier"
  vpc_id = aws_vpc.aws-3-tier-vpc.id
  /*ingress {
    description = "allow traffic from my ip"
    from_port = 4000
    to_port = 4000
    protocol = "tcp"
    
  }*/
ingress {
    description = "allow traffic from my internetfacing laodbalace"
    from_port = 4000
    to_port = 4000
    protocol = "tcp"
    security_groups = [ aws_security_group.internal-lb-sg.id ]
  }
  tags = {
    "Name" = "app-tier-sg"
  }
}

# Create security group for DB tier
resource "aws_security_group" "DB-tier-sg" {
  name = "DB-tier-sg"
  description = "sg for the DB tier"
  vpc_id = aws_vpc.aws-3-tier-vpc.id
  ingress {
    description = "allow traffic from my ip"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [ aws_security_group.app-tier-sg.id ]
  }
  tags = {
    "Name" = "DB-tier-sg"
  }
}

# Create Database subnet group
resource "aws_db_subnet_group" "three-tier-db-subnet" {
  name = "db-sg"
  subnet_ids = [ aws_subnet.DB-tier-az1-subnet.id, aws_subnet.DB-tier-az2-subnet.id ]

tags = {
  "Name" = "MY db subnet group"
}
}
# Create Database tier
resource "aws_db_instance" "db-masud" {
   allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  multi_az = true
  name                 = "db_masud"
  username             = "username"
  password             = "password"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.three-tier-db-subnet.id

  vpc_security_group_ids = [ aws_security_group.DB-tier-sg.id ]
tags = {
  "Name" = "My-three-tier-Database"
}
}

# Create app tier instance
resource "aws_instance" "app-tier1" {
  ami = "ami-05fa00d4c63e32376"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.app-tier-sg.id ]
  subnet_id = aws_subnet.app-tier-az1-subnet.id
  user_data = <<EOF
  sudo yum install mysql -y
EOF
tags = {
  "Name" = "app-tier1"
}
}


# Create target group and internal load balance
# Create target goup
resource "aws_lb_target_group" "internal-lb-target-group" {
  name = "ILB-TG"
  protocol = "HTTP"
  port = 4000
  vpc_id = aws_vpc.aws-3-tier-vpc.id
 
}

# Create internal load balancer
resource "aws_lb" "internal-lb" {
  name = "interanl-lb"
  internal = true 
  load_balancer_type = "application"
  security_groups = [ aws_security_group.internal-lb-sg.id ]
  subnets = [ aws_subnet.app-tier-az2-subnet.id, aws_subnet.app-tier-az1-subnet.id]
enable_deletion_protection = false 

tags = {
  "Name" = "Internal-lb"
}
}
# Create load balance listener
resource "aws_lb_listener" "ILN-listner" {
  load_balancer_arn = aws_lb.internal-lb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal-lb-target-group.arn
  }

}


# Create auto scaling group from launch template (launch template will have configured databased address and all the necessary software )

# Create lauch configration
resource "aws_launch_configuration" "apptier" {
  name_prefix     = "auto-scaling-apptier"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.micro"
  user_data       = <<EOF
  sudo yum install mysql -y
EOF
  security_groups = [aws_security_group.app-tier-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

# Create auto scaling group for app tier
resource "aws_autoscaling_group" "IASG" {
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.apptier.name
  vpc_zone_identifier  = [aws_subnet.app-tier-az2-subnet.id, aws_subnet.app-tier-az1-subnet.id]
}

# create attachment between auto scaling group and target group
resource "aws_autoscaling_attachment" "ILB-IASG" {
  autoscaling_group_name = aws_autoscaling_group.IASG.id
  alb_target_group_arn = aws_lb_target_group.internal-lb-target-group.arn
}

resource "aws_instance" "web-tier" {
   ami = "ami-05fa00d4c63e32376"
   instance_type = "t2.micro"
   security_groups = [ aws_security_group.web-tier-sg.id ]
   user_data = file("userdata.sh")
   subnet_id = aws_subnet.web-tier-az1-subnet.id
   tags = {
     "Name" = "Web-tier"
   }
}

# Create external load balance and auto resource group
# Create external load balance
resource "aws_lb_target_group" "ELB-group" {
  name     = "External-lb"
  protocol = "HTTP"
   port     = 80
  vpc_id   = aws_vpc.aws-3-tier-vpc.id
  
}

# Create external load balancer
resource "aws_lb" "ELB" {
  name = "external-lb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [ aws_security_group.internet-facing-lb-sg.id ]
  subnets = [ aws_subnet.web-tier-az2-subnet.id, aws_subnet.web-tier-az1-subnet.id]
enable_deletion_protection = false 
tags = {
  "Name" = "External-lb"
}
}

# Create listner for external load balancer
resource "aws_lb_listener" "ELB-listner" {
  load_balancer_arn = aws_lb.ELB.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ELB-group.arn
  }
}

# Create auto scaling configration and template image
resource "aws_launch_configuration" "webtier" {
  name_prefix     = "autoscaling-webtier"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.micro"
  user_data = file("userdata.sh")
  security_groups = [aws_security_group.web-tier-sg.id]

  lifecycle {
    create_before_destroy = true
  }
  
}

resource "aws_autoscaling_group" "EASG" {
  min_size             = 3
  max_size             = 6
  desired_capacity     = 4
  launch_configuration = aws_launch_configuration.webtier.name
  vpc_zone_identifier  = [aws_subnet.web-tier-az2-subnet.id, aws_subnet.web-tier-az1-subnet.id]

}

resource "aws_autoscaling_attachment" "ELB-EASG" {
  autoscaling_group_name = aws_autoscaling_group.EASG.id
  alb_target_group_arn = aws_lb_target_group.ELB-group.arn
}