FROM debian:oldstable

EXPOSE 3306

ARG DB_NAME
ARG DB_USER
ARG DB_PW
ARG DB_ROOT_PW

RUN apt-get update && \
	apt-get install mariadb-server -y && \
	service mariadb start && \
	chown -R mysql:mysql /var/run/mysqld && \
	chmod 755 -R /var/run/mysqld && \
	rm -rf /var/lib/apt/lists/* 

COPY tools/script.sh /tmp/script.sh

RUN chmod +x /tmp/script.sh && \
	bash /tmp/script.sh && \
	rm -rf /tmp/script.sh

ENTRYPOINT [\ 
				"mysqld_safe", \
				"--skip-networking=0", \
				"--bind-address=0.0.0.0" \
			]