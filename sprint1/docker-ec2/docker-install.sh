sudo su
yum update
yum install update -y
yum install docker -y
yum service docker start
systemctl enable docker

