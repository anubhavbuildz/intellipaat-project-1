#!/bin/bash

apt-get update -y
apt-get install -y mysql-server
systemctl enable mysql
systemctl start mysql