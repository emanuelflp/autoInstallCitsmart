#!/bin/bash

# Script para Instalação automatizada do CitSmart ITSM no Centos 7

# Declaração das variaveis

TMPDIR="/tmp/citsmart";

INSTALLDIR="/opt/citsmart";

JBOSSDIR="/opt/jboss";

JBOSSADMINPASSWORD=`openssl rand -hex 10`;

PGSQLDIR="/var/lib/pgsql/9.3/data/";
CTSMRTSQLUSER="citsmartuser";
CTSMRTSQLDB="citsmartdb";
CTSMRTSQLPASSWD=`openssl rand -hex 10`;

# Primeiro faça o download e instalação dos  Softwares Requisitos.
prereq() {

	mkdir $TMPDIR;
	# Download do JBOSS
	wget -P $TMPDIR http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip;
	# Download do Driver JDBC do PostgreSQL
	wget -P $TMPDIR https://jdbc.postgresql.org/download/postgresql-9.3-1103.jdbc41.jar;
	# Instalação do Repositório do PostgreSQL
	rpm --quiet -ih https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-7-x86_64/pgdg-centos93-9.3-2.noarch.rpm;
	# Instalação dos Requisitos Iniciais do Sistema
	yum -q -y install epel-release;

	yum -q -y update;

	yum -q -y install vim wget unzip postgresql93-server postgresql93-contrib;
	# Download do JRE 7.0.40
	wget -P $TMPDIR/ --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u40-b43/jre-7u40-linux-x64.rpm";
	# Download do JDK 7.0.40
	wget -P $TMPDIR/ --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u40-b43/jdk-7u40-linux-x64.rpm";
	# Instalação do JDK
	yum -q -y install $TMPDIR/jdk-7u40-linux-x64.rpm;

	yum -q -y install $TMPDIR/jre-7u40-linux-x64.rpm;

}
# Iniciando configuração do Banco de dados Postgresql

dbconfig() {

	systemctl enable postgresql-9.3;

	su - postgres -c "/usr/pgsql-9.3/bin/initdb -D $POSTGRESQLDIR";

	echo "host    all             all             127.0.0.1/32               md5" >> /var/lib/pgsql/9.3/data/pg_hba.conf;

	systemctl start postgresql-9.3;

	su - postgres -c "psql -c \"create user $CTSMRTSQLUSER with password '$CITSMARTSQLPASSWD';\"";

	su - postgres -c "psql -c \"create database $CTSMRTSQLDB with owner $CTSMRTSQLUSER encoding 'UTF8' tablespace pg_default;\"";

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

dbconfig