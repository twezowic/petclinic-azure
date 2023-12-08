#! /bin/bash

DATABASE_PORT=$1
DATABASE_USER=$2
DATABASE_PASSWORD=$3

MY_SQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"
INIT_DATABASE="https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/master/src/main/resources/db/mysql/initDB.sql"
POPULATE_DATABASE="https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/master/src/main/resources/db/mysql/populateDB.sql"

cd /~

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

sudo apt-get install mysql-server -y
sudo apt-get install wget -y

# Download config files

echo "CREATE USER '$DATABASE_USER'@'%' IDENTIFIED BY '$DATABASE_PASSWORD';" >>user.sql
echo "GRANT ALL PRIVILEGES ON *.* TO '$DATABASE_USER'@'%' WITH GRANT OPTION;" >>user.sql

wget $INIT_DATABASE
wget $POPULATE_DATABASE

sudo echo "log_bin = /var/log/mysql/mysql-bi.log" >>$MY_SQL_CONFIG

sudo sed -i "s/127.0.0.1/0.0.0.0/g" $MY_SQL_CONFIG
sudo sed -i "s/3306/$DATABASE_PORT/" $MY_SQL_CONFIG
sudo sed -i "s/.*server-id.*/server-id = 1/" $MY_SQL_CONFIG
sudo sed -i "s/.*log_bin.*/log_bin = \\/var\\/log\\/mysql\\/mysql-bi.log/" $MY_SQL_CONFIG
sudo sed -i "1s/^/USE petclinic;\n/" ./populateDB.sql

cat $MY_SQL_CONFIG

cat ./user.sql | sudo mysql -f
sudo mysql -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepassword';"
sudo mysql -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';"
cat ./initDB.sql | sudo mysql -f
cat ./populateDB.sql | sudo mysql -f

sudo mysql -v -e "FLUSH PRIVILEGES;"

sudo service mysql restart