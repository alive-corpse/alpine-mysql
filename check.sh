#!/bin/sh

[ -d "/var/lib/mysql/mysql" ] || exit 1
[ -f "/tmp/init" ] || exit 1
mysqladmin ping 2>/dev/null
[ $? -ne 0 ] && exit 1

