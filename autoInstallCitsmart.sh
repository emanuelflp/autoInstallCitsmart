#!/bin/bash

# Script para Instalação automatizada do CitSmart ITSM no Centos 7 ou Centos 6

# Declaração das variaveis Gerais
TMPDIR="/tmp/citsmart";
INSTALLDIR="/opt/citsmart";

# Variaveis do JBoss
JBOSSDIR="/opt/jboss";
JBOSSADMINPASSWORD=`openssl rand -hex 10`;
URLDOWNLOADJBOSS="http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip"
URLDOWNLOADPSQLDRIVER="https://jdbc.postgresql.org/download/postgresql-9.3-1103.jdbc41.jar"

# Variaveis do PostgreSQL
PGSQLDIR="/var/lib/pgsql/9.3/data";
CTSMRTSQLUSER="citsmartuser";
CTSMRTSQLDB="citsmartdb";
CTSMRTSQLPASSWD=`openssl rand -hex 10`;

fail() { log "\nERRO: $*\n" ; exit 1 ; }
# Verifica Se é Centos nas versões 6 ou 7.
verificaDistro() {

	if [[ -f /etc/centos-release ]]; then
		
		versaodistro=`rpm -q --queryformat '%{VERSION}' centos-release`

		if [[ $versaodistro -eq 7 ]]; then

				VERSAOSO=7

		elif [[ $versaodistro -eq 6 ]]; then
			
				VERSAOSO=6
		else
			fail "Este script é compativel somente o CentOS nas Versões 6 ou 7";

		fi

	else

		fail "Este script é compativel somente o CentOS nas Versões 6 ou 7";

	fi

}

# Primeiro faça o download e instalação dos  Softwares Requisitos.
prereq() {

	if [[ `getenforce` = "Enforcing" ]]; then

			setenforce 0

	fi

	sed -i '/^#/!s/disabled/enforcing/g' /etc/selinux/config

	# Instalação do Repositório do PostgreSQL

	if [[ $VERSAOSO -eq 7 ]]; then
		
		rpm --quiet -ih https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-7-x86_64/pgdg-centos93-9.3-2.noarch.rpm &> /dev/null;

	elif [[ $VERSAOSO -eq 6 ]]; then

		rpm --quiet -ih https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm &> /dev/null;

	fi

	# Instalação dos Requisitos Iniciais do Sistema
	yum -q -y update &> /dev/null;

	yum -q -y install wget unzip postgresql93-server postgresql93-contrib &> /dev/null || fail "Erro ao fazer a instalação dos pacotes necessários"

	# Download do JBOSS
	wget -P $TMPDIR $URLDOWNLOADJBOSS &> /dev/null || fail "Erro ao fazer o Download do JBoss"

	# Download do Driver JDBC do PostgreSQL
	wget -P $TMPDIR $URLDOWNLOADPSQLDRIVER &> /dev/null fail "Erro ao fazer o Download do Driver do Banco de dados"

	# Download do JRE 7.0.40
	wget -P $TMPDIR/ --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u40-b43/jre-7u40-linux-x64.rpm" &> /dev/null || fail "Erro ao fazer o download do JDK do JAVA."
	# Download do JDK 7.0.40
	wget -P $TMPDIR/ --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u40-b43/jdk-7u40-linux-x64.rpm" &> /dev/null || fail "Erro ao fazer o download do JRE do JAVA."

	# Instalação do JDK
	yum -q -y install $TMPDIR/jdk-7u40-linux-x64.rpm &> /dev/null;

	yum -q -y install $TMPDIR/jre-7u40-linux-x64.rpm &> /dev/null;

}

# Iniciando configuração do Banco de dados Postgresql.
dbconfig() {

	su - postgres -c "/usr/pgsql-9.3/bin/initdb -D $PGSQLDIR/" &> /dev/null;

	echo "host    all             all             127.0.0.1/32               md5" >> $PGSQLDIR/pg_hba.conf &> /dev/null;

	if [[ $VERSAOSO -eq 7 ]]; then

		systemctl enable postgresql-9.3 &> /dev/null;		
		systemctl start postgresql-9.3 &> /dev/null;

	elif [[ $VERSAOSO -eq 6 ]]; then

		chkconfig enable postgresql-9.3
		service postgresql-9.3 start

	fi

	su - postgres -c "psql -c \"create user $CTSMRTSQLUSER with password '$CITSMARTSQLPASSWD';\"" &> /dev/null;

	su - postgres -c "psql -c \"create database $CTSMRTSQLDB with owner $CTSMRTSQLUSER encoding 'UTF8' tablespace pg_default;\"" &> /dev/null;

}

# Configuração do JBOSS para o Citsmart.
jbossconfig() {

	unzip $TMPDIR/jboss-as-7.1.1.Final.zip -d /opt/;

	ln -s /opt/jboss-as-7.1.1.Final/ $JBOSSDIR;

	adduser -d $JBOSSDIR jboss;

	chown -fR jboss.jboss /opt/jboss-as-7.1.1.Final/;

	su - jboss -s "$JBOSSDIR/bin/add-user.sh admin $JBOSSADMINPASSWORD";

	mkdir -p $JBOSSDIR/modules/org/postgresql/main;

	cp $TMPDIR/postgresql-9.3-1103.jdbc41.jar $JBOSSDIR/modules/org/postgresql/main/;
	cp $TMPDIR/autoinstallCitsmart/files/module.xml $JBOSSDIR/modules/org/postgresql/main/;
	cp -R $TMPDIR/autoinstallCitsmart/files/standalone.xml $JBOSSDIR/standalone/configuration/;
	cp -R $TMPDIR/autoinstallCitsmart/files/standalone.conf $JBOSSDIR/bin/;
	cp -R $TMPDIR/autoinstallCitsmart/files/citsmart.cfg $JBOSSDIR/standalone/configuration/;

}

citsmartconfig(){

	mkdir -p $INSTALLDIR/Lucene/AnexosBaseConhecimento
	mkdir -p $INSTALLDIR/Lucene/BaseConhecimento
	mkdir -p $INSTALLDIR/Lucene/PalavraGemea
	mkdir -p $INSTALLDIR/gedCitsmart
	mkdir -p $INSTALLDIR/Upload

	chown -fR jboss.jboss $INSTALLDIR/

	sed -i -e 's/CITSMARTSQLUSER/$CTSMRTSQLUSER/g' $JBOSSDIR/standalone/configuration/standalone.xml;
	sed -i -e 's/CITSMARTSQLPASSWORD/$CTSMRTSQLPASSWD/g' $JBOSSDIR/standalone/configuration/standalone.xml;
	sed -i -e 's/CITSMARTSQLDB/$CTSMRTSQLPASSWD/g' $JBOSSDIR/standalone/configuration/standalone.xml;

}


installpackage(){

	verificaDistro;
	prereq;
	dbconfig;
	jbossconfig;
	citsmartconfig;
	if [[ $? -eq 0 ]]; then
		clear
		echo "Instalação Realizada com Sucesso"
		echo "Dados de acesso ao JBOSS e ao Banco estão logo abaixo"
		echo "Guarde esses dados caso precise acessa-los"
		echo
		echo
		echo "Para acessar a interface de gerenciamento do JBoss acesse http://IP-SERVIDOR:9990/"
		echo "Usuario JBoss: admin"
		echo "Senha JBoss: $JBOSSADMINPASSWORD"
		echo
		echo "Usuario Postgresql CitSmart: $CITSMARTSQLUSER"
		echo "Senha Postgresql CitSmart: $CITSMARTSQLPASSWORD"
		echo "Nome do Banco CitSmart: $CITSMARTSQLDB"
		echo
	fi
}

installpackage;