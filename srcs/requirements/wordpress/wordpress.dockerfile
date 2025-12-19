FROM debian:oldstable

RUN apt-get update && apt-get install -y php8.2 php8.2-fpm php8.2-mysql curl mariadb-client && \
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp && \
	mkdir -p /var/www/html && \
	rm -rf /etc/php/8.2/fpm/pool.d/www.conf

COPY /conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY /tools/entrypoint.sh script.sh

RUN chmod +x script.sh

ENTRYPOINT ["./script.sh"]