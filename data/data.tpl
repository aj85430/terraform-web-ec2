#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1> Welcome to the web-app </h1>" > /var/www/html/index.html
echo "<h2>Instance ID: $(curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '(?<="instanceId" : ")[^"]*')</h2>" >> /var/www/html/index.html
echo "<h2>IP Address: $(curl http://169.254.169.254/latest/meta-data/public-ipv4)</h2>" >> /var/www/html/index.html
echo "<h2>MAC Address: $(curl http://169.254.169.254/latest/meta-data/mac)</h2>" >> /var/www/html/index.html
