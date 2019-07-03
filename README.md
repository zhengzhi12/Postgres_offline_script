# PostgreSQL一键离线安装脚本
## 功能简述：
* 脚本能在完全断网的情况下安装postgreSQL数据库。

* **脚本只支持CentOS 6/7**，通过读取`/etc/centos-release`来获取版本号，进而影响部分安装命令。

* PostgreSQL需要postgres用户来启动，此脚本将会新建postgres用户，**但不会新建postgres用户组**。

* 脚本会自动创建自启动。CentOS 6是利用`/etc/rc.d/rc.local`来执行脚本创建的`/usr/local/pgsql/pgsql.sh`；CentOS 7中将在systemd中创建postgresql服务。

* 默认使用5432端口，并在防火墙中开启此端口。

* 脚本将自动创建mydb数据库。

## 使用指南
* 使用脚本需要3个核心文件（夹）：
  * install_postgres.sh（脚本文件）
  * dependencies_pgsql（安装所需的依赖包）
  * postgresql-xxx.tar.gz（postgreSQL源文件，下载地址https://www.postgresql.org/ftp/source/ ）
    
  postgres_install_kit.rar压缩包中已经包含这三个文件（夹），解压并把它们放在**同级目录**下用root用户运行`./install_postgres.sh`进行安装。
  
* 依赖文件夹的rpm包可以在可以联网的CentOS 6/7系统中使用以下命令进行下载：

  `sudo yum install yum-plugin-downloadonly`

  `sudo yum install --downloadonly --downloaddir=/root/dependencies_pgsql/ gcc readline-devel zlib-devel`
  
* 安装时会提示当前系统时间，请务必进行核对。
* 执行脚本会提示输入postgres系统用户密码，和postgres数据库用户的登陆密码，以供后续设置使用。可以通过编辑脚本中的`postgres_user_password`和`pg_db_password`两个变量来跳过这一步。
