#!/bin/bash

######################################################
##
##  Purpose:Install Postgresql Offline
## 
##  Author :zzw
##  
##  Created:2019-06-11
## 
##  Version:1.0.0
#####################################################

CentOS_Version=""

DATE=`date +"%Y-%m-%d %H:%M:%S"`
RED_COLOR='\E[1;31m'
YELLOW_COLOR='\E[1;33m' 
GREEN_COLOR='\E[0;32m'
BLUE_COLOR='\E[1;34m'
LIGHTBLUE_WHITE='\033[46;30m'
COLOR_END='\E[0m'

#设置默认的postgres用户密码，为空则需要在安装时手动输入
postgres_user_password=""
#设置默认的postgres数据库密码，为空则需要在安装时手动输入
pg_db_password=""

echo
echo -e "${LIGHTBLUE_WHITE}--------------------Checking CentOS Version---------------------${COLOR_END}\n"
if [ `cat /etc/centos-release | grep CentOS | wc -l` -eq 0 ]; then
	echo -e "${YELLOW_COLOR}--------------该系统不是CentOS,正在退出安装----------------${COLOR_END}\n"
	exit 1
else
	if [ `cat /etc/centos-release | grep "release 6." | wc -l` -gt 0 ]; then
		CentOS_Version="6"
	elif [ `cat /etc/centos-release | grep "release 7." | wc -l` -gt 0 ]; then
		CentOS_Version="7"
	else
		echo -e "${YELLOW_COLOR}--------------该系统不是CentOS 6/7,正在退出安装----------------${COLOR_END}\n"
		exit 1
	fi
	echo -e "${GREEN_COLOR}--------------系统版本为CentOS ${CentOS_Version}----------------${COLOR_END}\n"
fi	
	

echo -e "${LIGHTBLUE_WHITE}--------------------Checking current OS datetime---------------------${COLOR_END}\n"
sleep 1
echo -e "------系统当前时间: ${BLUE_COLOR}$DATE${COLOR_END}-----------------"
echo -e "------确保系统时间不早于实际时间----------\n"
sleep 1
echo -e "\033[43;30m------该脚本仅支持CentOS 6/7----------${COLOR_END}\n"
echo -e "${RED_COLOR}请确保该安装脚本的三个核心组件在同一目录下:${COLOR_END}"
echo -e "	${RED_COLOR}install_postgres.sh${COLOR_END}(安装脚本)"
echo -e "	${RED_COLOR}dependencies_pgsql/${COLOR_END}(依赖组件rpm包)"
echo -e "	${RED_COLOR}postgresql_xxx.tar.gz${COLOR_END}(PGSQL安装包，下载地址https://www.postgresql.org/ftp/source/)"

echo
sleep 1
echo -e "${BLUE_COLOR}------请输入 y 或 n 以继续或取消安装------------------${COLOR_END}\n"
read input

if [ "$input" != "Y" -a "$input" != "y" ]; then
	echo -e "${YELLOW_COLOR}--------------用户取消安装----------------${COLOR_END}\n"
	exit 1
fi
echo -e "${YELLOW_COLOR}----设置密码参数，也可以通过编辑脚本头的两个密码变量来跳过此步骤----${COLOR_END}\n"

if [ ! -n "$postgres_user_password" ]; then
	read -p "请为即将在Linux系统中添加的postgres用户设置密码:" postgres_user_password
fi

if [ ! -n "$pg_db_password" ]; then
	read -p "请为数据库设置密码:" pg_db_password
fi

echo 
echo -e "${LIGHTBLUE_WHITE}--------------Creating User postgres--------------${COLOR_END}"
sleep 1
if [ `grep "postgres" /etc/passwd | wc -l` -eq 0 ];then
	echo "----在系统中添加用户postgres，此用户将会用来启动数据库----"
	useradd postgres
	echo -e $postgres_user_password | passwd --stdin postgres
	else
	echo -e "--------------Postgres用户已经存在，取消添加--------------\n"
fi
sleep 2

echo 
echo -e "${LIGHTBLUE_WHITE}---------------------Installing Denpendencies---------------------${COLOR_END}"
sleep 1

if [ $CentOS_Version == '6' ]; then
	rpm -Uvh --force --nodeps dependencies_pgsql/*el6*.rpm
else
	rpm -Uvh --force --nodeps dependencies_pgsql/*el7*.rpm
fi

echo 
echo -e "${LIGHTBLUE_WHITE}---------------------Installing PostgreSQL----------------${COLOR_END}"
sleep 2
tar -xvf postgre*.tar.gz
cd postgres*
./configure
make
make install
mkdir /usr/local/pgsql/data

echo 
echo -e "${LIGHTBLUE_WHITE}---------------------Setting Up Autoboot----------------${COLOR_END}"
sleep 2
echo -e "PATH=\$PATH:/usr/local/pgsql/bin \nPGDATA=/usr/local/pgsql/data" > /etc/profile.d/pgsql_set_env.sh && chmod 755 /etc/profile.d/pgsql_set_env.sh
source /etc/profile.d/pgsql_set_env.sh

cat > /usr/local/pgsql/pgsql.sh << EOF
#!/bin/bash
su - postgres -c 'pg_ctl -l $PGDATA/logfile start'
EOF
chmod +x /usr/local/pgsql/pgsql.sh
sed -i '$a sh /usr/local/pgsql/pgsql.sh' /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

echo 
echo -e "${LIGHTBLUE_WHITE}---------------------Configure Iptables----------------${COLOR_END}"
sleep 2
if [ $CentOS_Version == '6' ]; then
	service iptables save
	sed -i "/COMMIT/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport 5432 -j ACCEPT" /etc/sysconfig/iptables
	iptables -F
else
	firewall-cmd --zone=public --add-port=5432/tcp --permanent
	firewall-cmd --reload
fi


echo 
echo -e "${LIGHTBLUE_WHITE}---------------------Initiating PostgreSQL----------------${COLOR_END}"
sleep 2
chown -R postgres /usr/local/pgsql
su - postgres -c '/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data'
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /usr/local/pgsql/data/postgresql.conf
sed -i "/# IPv4 local connections:/{n;s#127.0.0.1/32#0.0.0.0/0#;s/trust/md5/}" /usr/local/pgsql/data/pg_hba.conf
cd /usr/local/pgsql/bin
su - postgres -c 'pg_ctl -D /usr/local/pgsql/data -l logfile start'
su - postgres -c 'createdb mydb'
su - postgres -c 'psql' << EOF
alter user postgres with password '$pg_db_password';
\q

EOF

echo -e "\033[42;37m--------------安装完成--------------${COLOR_END}"
