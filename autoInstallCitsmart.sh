#!/bin/bash

# Script para Instalação automatizada do CitSmart ITSM no Centos 7 ou Centos 6

# Declaração das variaveis

TMPDIR="/tmp/citsmart";

INSTALLDIR="/opt/citsmart";

JBOSSDIR="/opt/jboss";

JBOSSADMINPASSWORD=`openssl rand -hex 10`;

PGSQLDIR="/var/lib/pgsql/9.3/data";
CTSMRTSQLUSER="citsmartuser";
CTSMRTSQLDB="citsmartdb";
CTSMRTSQLPASSWD=`openssl rand -hex 10`;

fail() { log "\nERRO: $*\n" ; exit 1 ; }

verificaDistro() {

if [[ -f /etc/centos-release ]]; then
	
	versaodistro=`rpm -q --queryformat '%{VERSION}' centos-release`

	if [[ ! $versaodistro -eq 7 || ! $versaodistro -eq 6 ]]; then
		fail "Este script é compativel somente o CentOS nas Versões 6 ou 7";
	fi

else
	
	fail "Este script é compativel somente o CentOS nas Versões 6 ou 7";

fi


}

# Primeiro faça o download e instalação dos  Softwares Requisitos.
prereq() {

	mkdir $TMPDIR &> /dev/null;
	# Download do JBOSS
	wget -P $TMPDIR http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip &> /dev/null;
	# Download do Driver JDBC do PostgreSQL
	wget -P $TMPDIR https://jdbc.postgresql.org/download/postgresql-9.3-1103.jdbc41.jar &> /dev/null;
	# Instalação do Repositório do PostgreSQL
	rpm --quiet -ih https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-7-x86_64/pgdg-centos93-9.3-2.noarch.rpm &> /dev/null;
	# Instalação dos Requisitos Iniciais do Sistema
	yum -q -y install epel-release &> /dev/null;

	yum -q -y update &> /dev/null;

	yum -q -y install vim wget unzip postgresql93-server postgresql93-contrib &> /dev/null;
	# Download do JRE 7.0.40
	wget -P $TMPDIR/ --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u40-b43/jre-7u40-linux-x64.rpm" &> /dev/null;
	# Download do JDK 7.0.40
	wget -P $TMPDIR/ --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u40-b43/jdk-7u40-linux-x64.rpm" &> /dev/null;
	# Instalação do JDK
	yum -q -y install $TMPDIR/jdk-7u40-linux-x64.rpm &> /dev/null;

	yum -q -y install $TMPDIR/jre-7u40-linux-x64.rpm &> /dev/null;

}
# Iniciando configuração do Banco de dados Postgresql

dbconfig() {
{
	systemctl enable postgresql-9.3 &> /dev/null;

	su - postgres -c "/usr/pgsql-9.3/bin/initdb -D $PGSQLDIR/" &> /dev/null;

	echo "host    all             all             127.0.0.1/32               md5" >> $PGSQLDIR/pg_hba.conf &> /dev/null;

	systemctl start postgresql-9.3 &> /dev/null;

	su - postgres -c "psql -c \"create user $CTSMRTSQLUSER with password '$CITSMARTSQLPASSWD';\"" &> /dev/null;

	su - postgres -c "psql -c \"create database $CTSMRTSQLDB with owner $CTSMRTSQLUSER encoding 'UTF8' tablespace pg_default;\"" &> /dev/null;

} || {

}

}

# Configuração do JBOSS para o Citsmart
jbossconfig() {

	unzip $TMPDIR/jboss-as-7.1.1.Final.zip -d /opt/;

	ln -s /opt/jboss-as-7.1.1.Final/ $JBOSSDIR;

	adduser -d $JBOSSDIR jboss;

	chown -fR jboss.jboss /opt/jboss-as-7.1.1.Final/;

	su - jboss -s "$JBOSSDIR/bin/add-user.sh admin $JBOSSADMINPASSWORD";

	mkdir -p $JBOSSDIR/modules/org/postgresql/main;

		cp $TMPDIR/postgresql-9.3-1103.jdbc41.jar $JBOSSDIR/modules/org/postgresql/main/;

}

prereq

dbconfig