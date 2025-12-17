FROM debian:oldstable AS builder

COPY tools/script.sh tmp/script.sh

RUN apt-get update && \
	apt-get install --no-install-recommends openssl -y && \
	rm -rf /var/lib/apt/lists/* && \
	chmod +x /tmp/script.sh && \
	bash /tmp/script.sh && \
	apt-get purge openssl -y && apt-get autoremove -y

FROM debian:oldstable

RUN apt-get update && \
	apt-get install --no-install-recommends nginx  -y && \
	rm -rf /var/lib/apt/lists/* \
	/etc/nginx/nginx.conf \
	/etc/nginx/sites-available/default \
	/etc/nginx/sites-enabled/default && \
	mkdir /etc/nginx/ssl

COPY --from=builder /tmp/nginx.key /etc/nginx/ssl/nginx.key
COPY --from=builder /tmp/nginx.crt /etc/nginx/ssl/nginx.crt
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/site.conf /etc/nginx/sites-available/site.conf

RUN ln -s /etc/nginx/sites-available/site.conf /etc/nginx/sites-enabled/site.conf && \
	chown -R www-data:www-data /var/www/ && \
	chmod -R 755 /var/www/

EXPOSE 443

CMD [ "nginx", "-g", "daemon off;" ]
