#! /bin/bash
sudo yum update -y
amazon-linux-extras install -y java-openjdk11
cd /opt
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.49/bin/apache-tomcat-8.5.49.tar.gz

tar -xvzf apache-tomcat-8.5.49.tar.gz
mv apache-tomcat-8.5.49 tomcat
sudo su --
cd /opt/tomcat/bin/
./startup.sh
