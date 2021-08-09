#!/bin/bash
set -e
set -o pipefail
BACKUP_FOLDER=/root/lara/mysql/backup
NAME=laradock_mysql_1
mkdir -p ${BACKUP_FOLDER}

# Password Warning issue
cat <<EOF > ~/.my.cnf
[mysql]
user=root
password=cloud

[mysqldump]
user=root
password=cloud
EOF

# copy my.cnf into container 
docker cp ~/.my.cnf ${NAME}:/root/.my.cnf

# compatibility issue
docker exec -i ${NAME} mysql -u root -s -e "set global show_compatibility_56=on"

for db in `docker exec -i ${NAME} mysql -u root -s -e "show databases" `
do
	docker exec -i ${NAME} mysqldump --single-transaction --add-drop-database  --add-drop-table --add-locks ${db} | gzip > ${BACKUP_FOLDER}/mysql-$(date "+%Y%m%d%H")-${db}.gz 2>/dev/null
	echo "$(date) backup ${db}"
done
find ${BACKUP_FOLDER} -type f -name 'mysql-*.gz' -mtime +10 -delete
rm -f ~/.my.cnf

