#!/bin/bash

WHOAMI=`whoami`

if [[ ! $WHOAMI = "root" ]]; then
	echo "Este script deve ser executado pelo root";
	exit 1;
fi

yum -q -y install git &> /dev/null

mkdir /tmp/citsmart

git clone -b release/PrimeiraVersao https://github.com/emanuelflp/autoInstallCitsmart.git /tmp/citsmart/autoInstallCitsmart

bash /tmp/citsmart/autoInstallCitsmart/autoInstallCitsmart.sh