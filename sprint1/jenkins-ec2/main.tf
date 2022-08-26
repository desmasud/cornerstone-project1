provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Jenkins-server" {
  ami = "ami-05fa00d4c63e32376"
  instance_type = "t2.micro"
  security_groups = [ "launch-wizard-1" ]
  key_name = "Jenkins"
  user_data = "${file("jenkins-install.sh")}"

  tags = {
    "Name" = "Jenkins-Server"
  }
}
