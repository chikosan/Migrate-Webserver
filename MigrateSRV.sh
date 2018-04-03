#!/bin/bash
#***********************************************************
#Migrate your wordpress server with Nginx and Mysql server #
#***********************************************************


main_start () {

echo "Relax we are ready to go in a few sec"
echo "What is your new server ip, i'm going to update it and install Nginx,mysql,php"
read srvnewip
echo "What is your server root password?"
read srvnewpass
echo "what is your root SQL password"
read sqloldpass
##### Backup ####

# Website Data Backup
if [ ! -f /tmp/12allwebsites.tar.xz ]; then
        tar --xz -cvpf /tmp/12allwebsites.tar.xz /var/www/
        sshpass -p $srvnewpass scp -P 22 /tmp/12allwebsites.tar.xz root@1.1.1.1:/home/backupm/
#else
#       sshpass -p $srvnewpass scp -P 22 /tmp/12allwebsites.tar.xz root@1.1.1.1:/home/backupm/
fi
# MySQL BD Backup
if [ ! -f /tmp/12mysqlsrvbackup.sql ]; then
        mysqldump -u root -p"$sqloldpass" --all-databases > /tmp/12mysqlsrvbackup.sql
        tar --xz -cvf /tmp/12mysqlsrvbackup.sql.tar.xz /tmp/12mysqlsrvbackup.sql
        sshpass -p $srvnewpass scp -P 22 /tmp/12mysqlsrvbackup.sql.tar.xz root@1.1.1.1:/home/backupm/
#else
#       sshpass -p $srvnewpass scp -P 22 /tmp/12mysqlsrvbackup.sql.tar.xz root@1.1.1.1:/home/backupm/
fi

# NginX Backup
if [ ! -f /tmp/12Nginx.tar.xz ]; then
        tar --xz -cvf /tmp/12Nginx.tar.xz /etc/nginx/sites-available/* /etc/nginx/nginx.conf
        sshpass -p $srvnewpass scp -P 22 /tmp/12Nginx.tar.xz root@1.1.1.1:/home/backupm/
#else
#        sshpass -p $srvnewpass scp -P 22 /tmp/12Nginx.tar.xz root@1.1.1.1:/home/backupm/
fi


###### Remote setup ###
if [ ! -f /usr/bin/sshpass ]; then sudo apt-get install sshpass -y; fi

## connect to the remote server
sshpass -p $srvnewpass ssh $srvnewip -l root -t -o StrictHostKeyChecking=no -p 22  <<EOSSH
sudo apt-get update 2>&1 >2
sudo apt upgrade -y 2>&1 >2
sudo apt install sshpass nginx mysql-server php7.0 php7.0-cgi php-mysql php-fpm -y >2
if [ ! -d /home/migrate ]; then mkdir /home/migrate; fi
rm -rf /etc/nginx/sites-enabled/*
if [ -f /etc/nginx/nginx.conf]; then mv /etc/nginx/nginx.conf /etc/nginx/nginx.original ; fi
tar --xz -xvf /home/backupm/12mysqlsrvbackup.sql.tar.xz -C /home/backupm/
mysql -u root -p"$sqloldpass" < /home/backupm/tmp/12mysqlsrvbackup.sql
tar --xz -xvf /home/backupm/12Nginx.tar.xz -C /home/backupm/
tar --xz -xvf /home/backupm/12allwebsites.tar.xz -C /home/backupm/
cp /home/backupm/etc/nginx/sites-available/* /etc/nginx/sites-available
ln -s /etc/nginx/sites-available/* /etc/nginx/sites-enabled/
rm -rf /var/www/*
mv /home/backupm/var/www/* /var/www/
rm -rf /var/www/ShaiChikorel/wp-content/plugins/googleanalytics/
systemctl restart nginx mysql php*
# rm -rf /home/backupm/

EOSSH

echo "ALL DONE!"
}


# ###################################################################################
echo "Hello you are now about migtare for a new server, are you ready?"
read readyans

if [ $readyans != "yes" ]; then
        echo "Good bye"
else
        main_start
fi

echo "end of script"

