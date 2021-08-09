* clone laravel.io
  * edit .env file
    ```
    $>mv .env.example .env
    $>vim .env
    APP_CODE_PATH_HOST=../projects/laravel-test
    PHP_VERSION=7.4
    MYSQL_VERSION=5.7
    MYSQL_DATABASE=smartcloud
    MYSQL_USER=smart
    MYSQL_PASSWORD=cloud
    DATA_PATH_HOST=/var/lib/mysql

    ```
  * build images and install laravel latest version
    ```
    # download image and build env
    $>docker-compose up -d --build nginx mysql workspace

    # Get into workspace and install laravel framework
    $>docker-compose exec workspace bash
    root@68437517565e:/var/www# composer create-project laravel/laravel --prefer-dist

    # Suspeng there is a minor bug, permission issue on storage/ folder
    root@68437517565e:/var/www#  cd laravel/ && chown -R laradock -R storage
    ```
  * add nginx site file (nginx/site/smartcloud.site):
    ```
    server {

        listen 80;
        listen [::]:80;

        # For https
        # listen 443 ssl;
        # listen [::]:443 ssl ipv6only=on;
        # ssl_certificate /etc/nginx/ssl/default.crt;
        # ssl_certificate_key /etc/nginx/ssl/default.key;

        # tweak these 2 lines
        server_name smartcloud.site;
        root /var/www/laravel/public;
        index index.php index.html index.htm;

        location / {
            try_files $uri $uri/ /index.php$is_args$args;
        }

        location ~ \.php$ {
            try_files $uri /index.php =404;
            fastcgi_pass php-upstream;
            fastcgi_index index.php;
            fastcgi_buffers 16 16k;
            fastcgi_buffer_size 32k;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            #fixes timeouts
            fastcgi_read_timeout 600;
            include fastcgi_params;
        }

        location ~ /\.ht {
            deny all;
        }

        location /.well-known/acme-challenge/ {
            root /var/www/letsencrypt/;
            log_not_found off;
        }

        error_log /var/log/nginx/laravel_error.log;
        access_log /var/log/nginx/laravel_access.log;
    }

    ```
  * add site into `/etc/hosts`    
    ```
    127.0.0.1   localhost localhost.localdomain smartcloud.site

    ```
  * restartup service and make sure everything is running well as expected:
    ```
    $> docker-compose down && docker-compose up -d  nginx mysql workspace
    Stopping laradock_nginx_1            ... done
    Stopping laradock_php-fpm_1          ... done
    Stopping laradock_workspace_1        ... done
    Stopping laradock_docker-in-docker_1 ... done
    Removing laradock_nginx_1            ... done
    Removing laradock_php-fpm_1          ... done
    Removing laradock_workspace_1        ... done
    Removing laradock_mysql_1            ... done
    Removing laradock_docker-in-docker_1 ... done
    Removing network laradock_frontend
    Removing network laradock_backend
    Removing network laradock_default
    Creating network "laradock_frontend" with driver "bridge"
    Creating network "laradock_backend" with driver "bridge"
    Creating network "laradock_default" with the default driver
    Creating laradock_mysql_1            ... done
    Creating laradock_docker-in-docker_1 ... done
    Creating laradock_workspace_1        ... done
    Creating laradock_php-fpm_1          ... done
    Creating laradock_nginx_1            ... done

    $> docker-compose ps
              Name                          Command               State                                Ports
    -----------------------------------------------------------------------------------------------------------------------------------
    laradock_docker-in-docker_1   dockerd-entrypoint.sh            Up      2375/tcp, 2376/tcp
    laradock_mysql_1              docker-entrypoint.sh mysqld      Up      0.0.0.0:3306->3306/tcp,:::3306->3306/tcp, 33060/tcp
    laradock_nginx_1              /docker-entrypoint.sh /bin ...   Up      0.0.0.0:443->443/tcp,:::443->443/tcp,
                                                                          0.0.0.0:80->80/tcp,:::80->80/tcp,
                                                                          0.0.0.0:81->81/tcp,:::81->81/tcp
    laradock_php-fpm_1            docker-php-entrypoint php-fpm    Up      9000/tcp, 0.0.0.0:9003->9003/tcp,:::9003->9003/tcp
    laradock_workspace_1          /sbin/my_init                    Up      0.0.0.0:2222->22/tcp,:::2222->22/tcp,
                                                                          0.0.0.0:3000->3000/tcp,:::3000->3000/tcp,
                                                                          0.0.0.0:3001->3001/tcp,:::3001->3001/tcp,
                                                                          0.0.0.0:4200->4200/tcp,:::4200->4200/tcp,
                                                                          0.0.0.0:8001->8000/tcp,:::8001->8000/tcp,
                                                                          0.0.0.0:8080->8080/tcp,:::8080->8080/tcp


    ```
  * test service
    ```
    $> curl smartcloud.site/ -s |grep -i title
        <title>Laravel</title>

    ```


* mysqlbackup
  * clone and import data from repo
  ```
  $>cd /var/lib/mysql
  $>git clone https://github.com/datacharmer/test_db db/ db/
  $>docker-compose exec  mysql bash
  root@74a2429ee823:/# cd /var/lib/mysql/db/
  root@74a2429ee823:/var/lib/mysql/db# ls
  Changelog                      images                  load_salaries1.dump  sakila                  test_versions.sh
  README.md                      load_departments.dump   load_salaries2.dump  show_elapsed.sql
  employees.sql                  load_dept_emp.dump      load_salaries3.dump  sql_test.sh
  employees_partitioned.sql      load_dept_manager.dump  load_titles.dump     test_employees_md5.sql
  employees_partitioned_5.1.sql  load_employees.dump     objects.sql          test_employees_sha.sql

  mysql> source ./employees.sql
  #### Too long, skip
  Query OK, 0 rows affected (0.02 sec)
    
  Query OK, 7671 rows affected (0.04 sec)
  Records: 7671  Duplicates: 0  Warnings: 0

  +---------------------+
  | data_load_time_diff |
  +---------------------+
  | 00:00:23            |
  +---------------------+
  1 row in set (0.05 sec)

  * Write a script to do daily backup && housekeeping ,see [Source](https://github.com/abelyang999/laradock/blob/master/crontab/mysql_backup.sh)

  * Put it in crontab
  ```
  00 12 * * * ~root/laradock/crontab/mysql_backup.sh
  ```
