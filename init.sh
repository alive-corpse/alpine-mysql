#!/bin/sh

if ! [ -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld
    chown mysql:mysql /run/mysqld
fi

[ -d "/var/lib/mysql/etc" ] ||  mkdir -p /var/lib/mysql/etc
[ -f "/var/lib/mysql/etc/my.cnf" ] || echo '[mysqld]
bind-address = 0.0.0.0' > /var/lib/mysql/etc/my.cnf

if ! [ -d "/var/lib/mysql/mysql" ]; then
    touch /tmp/init
    mysql_install_db -u mysql --datadir=/var/lib/mysql
    chown -R mysql:mysql /var/lib/mysql
    [ -z "$MYSQLROOTPWD" ] && MYSQLROOTPWD=mysqlroot
    [ -z "$MYSQLPWD" ] && MYSQLPWD=mysqluser
    [ -z "$MYSQLDB" ] && MYSQLDB=mysql
    sqlcontent="CREATE DATABASE IF NOT EXISTS \`$MYSQLDB\` CHARACTER SET utf8 COLLATE utf8_general_ci;
        USE $MYSQLDB;
        FLUSH PRIVILEGES;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQLROOTPWD' WITH GRANT OPTION;"
    if [ -n "$MYSQLUSER" ]; then
        if [ -n "$MYSQLDB" ]; then
            sqlcontent="$(echo "$sqlcontent"; echo "CREATE USER IF NOT EXISTS '$MYSQLUSER'@'%' IDENTIFIED BY '$MYSQLPWD';"; echo "CREATE USER IF NOT EXISTS '$MYSQLUSER'@'localhost' IDENTIFIED BY '$MYSQLPWD';")"
            sqlcontent="$(echo "$sqlcontent"; echo "GRANT ALL ON \`$MYSQLDB\`.* to '$MYSQLUSER'@'%' IDENTIFIED BY '$MYSQLPWD';"; echo "GRANT ALL ON \`$MYSQLDB\`.* to '$MYSQLUSER'@'localhost' IDENTIFIED BY '$MYSQLPWD';")"
        fi
    fi
    sname=`date +%s`
    echo "$sqlcontent" > /tmp/$sname.sql
    echo "FLUSH PRIVILEGES;" >> /tmp/$sname.sql
    mysqld --user=mysql --skip-networking &

    count=15; failed=1
    while [ $failed != 0 ]; do
        mysqladmin ping 2>/dev/null
        failed="$?"
        [ $failed -eq 0 ] && break || count=$(( $count - 1 ))
        [ $count -lt 1 ] && break 
        sleep 1
    done
    [ $failed -ne 0 ] && echo "Fail to connect to mysql for creating tables" && exit 1

    cat /tmp/$sname.sql | mysql -u root
    rm /tmp/$sname.sql
    if [ -n "$1" ]; then
        if [ -f "$1" ]; then
            cat /tmp/$sname.sql | mysql -u root
        fi
    fi

    mysqladmin -u root shutdown
    [ -f /tmp/init ] && rm /tmp/init 
fi

sudo -u mysql mysqld_safe --defaults-file=/var/lib/mysql/etc/my.cnf
