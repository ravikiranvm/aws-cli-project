#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras enable nginx1
sudo yum install nginx -y
echo "Hello, World!" | sudo tee /usr/share/nginx/html/index.html
sudo systemctl start nginx
sudo systemctl enable nginx