#!/usr/bin/env bash
sudo yum install docker git rsync -y
sudo usermod -a -G docker ec2-user

sudo systemctl enable docker.service
sudo systemctl start docker.service

git clone https://github.com/dezeroku/network_layout
