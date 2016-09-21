#!/bin/bash

yum -q -y install git &> /dev/null

mkdir /tmp/citsmart

git clone https://github.com/emanuelflp/autoInstallCitsmart.git /tmp/citsmart/autoInstallCitsmart

bash /tmp/citsmart/autoInstallCitsmart/autoInstallCitsmart.sh