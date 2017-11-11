#!/bin/sh

if ! [ -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld
    chown mysql:mysql /run/mysqld
fi

if ! [ -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db
    chown -R mysql:mysql /var/lib/mysql
    [ -z "$MYSQLROOTPWD" ] && MYSQLROOTPWD=mysqlroot
    [ -z "$MYSQLPWD" ] && MYSQLPWD=mysqluser
    sqlcontent="USE mysql;
        FLUSH PRIVILEGES;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQLROOTPWD' WITH GRANT OPTION;
        UPDATE user SET password=PASSWORD('') WHERE user='root' AND host='localhost';"
    [ -n "$MYSQLDB" ] && sqlcontent="$(echo "$sqlcontent"; echo "CREATE DATABASE IF NOT EXISTS \`$MYSQLDB\` CHARACTER SET utf8 COLLATE utf8_general_ci;")" 
    if [ -n "$MYSQLUSER" ]; then
        if [ -n "$MYSQLDB" ]; then
            sqlcontent="$(echo "$sqlcontent"; echo "GRANT ALL ON \`$MYSQLDB\`.* to '$MYSQLUSER'@'%' IDENTIFIED BY '$MYSQLPWD';"; echo "GRANT ALL ON \`$MYSQLDB\`.* to '$MYSQLUSER'@'localhost' IDENTIFIED BY '$MYSQLPWD';")"
        else
            sqlcontent="$(echo "$sqlcontent"; echo "CREATE USER IF NOT EXISTS '$MYSQLUSER'@'%' IDENTIFIED BY '$MYSQLPWD';"; echo "CREATE USER IF NOT EXISTS '$MYSQLUSER'@'localhost' IDENTIFIED BY '$MYSQLPWD';")"
        fi
    fi
    sname=`date +%s`
    echo "$sqlcontent" > /tmp/$sname.sql
    echo "FLUSH PRIVILEGES;" >> /tmp/$sname.sql
    sudo -u mysql mysqld --bootstrap < /tmp/$sname.sql
    rm /tmp/$sname.sql
    if [ -n "$1" ]; then
        if [ -f "$1" ]; then
            sudo -u mysql mysqld --bootstrap --user=root < "$1"
        fi
    fi
fi

sudo -u mysql mysqld_safe
