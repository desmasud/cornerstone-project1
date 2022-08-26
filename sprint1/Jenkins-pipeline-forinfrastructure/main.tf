provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Docker-Tomcat-server" {
  ami = "ami-05fa00d4c63e32376"
  instance_type = "t2.micro"
  security_groups = [ "launch-wizard-1" ]

  user_data = <<EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install git -y
  sudo amazon-linux-extras install -y docker
  sudo service docker start
  sudo systemctl enable docker
  sudo usermod -a -G docker ec2-user
  sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo amazon-linux-extras install -y java-openjdk11
  cd /opt
  wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.49/bin/apache-tomcat-8.5.49.tar.gz
  tar -xvzf apache-tomcat-8.5.49.tar.gz
  mv apache-tomcat-8.5.49 tomcat
  cd /opt/tomcat/bin/
  ./startup.sh
  EOF

  tags = {
    "Name" = "Docker-Tomcat-Server1"
  }
}
