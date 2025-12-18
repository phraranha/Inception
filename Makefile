# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: paranha <paranha@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/02/28 12:33:11 by paranha           #+#    #+#              #
#    Updated: 2025/12/17 00:00:00 by paranha          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

.PHONY: all up environment check_database_directory check_wordpress_directory \
	check_data_directory check_domain_in_hosts check_docker check_env start \
	stop clean_containers clean_images clean_volumes clean_network clean_system \
	clean_directory clean_all re_all

VOLUME_WORDPRESS=/home/paranha/data/wordpress-volume
VOLUME_DATABASE=/home/paranha/data/database-volume
VOLUME_DATA=/home/paranha/data

all: \
	check_env \
	environment \
	up

up:
	docker compose -f ./srcs/docker-compose.yml up -d;

environment: \
	check_data_directory \
	check_database_directory \
	check_wordpress_directory \
	check_domain_in_hosts

check_database_directory:
	@if [ ! -d $(VOLUME_DATABASE) ]; then \
		sudo mkdir -p $(VOLUME_DATABASE) ;\
		sudo chown -R ${USER}:${USER} $(VOLUME_DATABASE) ;\
	fi

check_wordpress_directory:
	@if [ ! -d $(VOLUME_WORDPRESS) ]; then \
		sudo mkdir -p $(VOLUME_WORDPRESS) ;\
		sudo chown -R ${USER}:${USER} $(VOLUME_WORDPRESS) ;\
	fi

check_data_directory:
	@if [ ! -d $(VOLUME_DATA) ]; then \
		sudo mkdir -p $(VOLUME_DATA) ;\
		sudo chown -R ${USER}:${USER} $(VOLUME_DATA) ;\
	fi

check_domain_in_hosts:
	@if ! grep -q "paranha.42.fr" /etc/hosts; then \
		sudo sh -c "echo 127.0.0.1	paranha.42.fr >> /etc/hosts "; \
	fi

check_docker:
	@if ! docker --version >/dev/null 2>&1; then \
		echo "Docker not found. Installing..."; \
		sudo sh -c "apt-get update"; \
		sudo sh -c "apt-get upgrade -y"; \
		sudo sh -c "apt-get install -y ./docker-desktop-amd64.deb"; \
		sudo sh -c "systemctl --user start docker-desktop"; \
	else \
		echo "Docker is already installed"; \
	fi

check_env:
	@if [ ! -f srcs/.env ]; then \
		echo ".env file not found. Generating with random passwords..."; \
		./srcs/generate_env.sh; \
	fi

start:
	docker start mariadb
	docker start wordpress
	docker start nginx

stop:
	docker stop -t 0 $(shell docker ps -aq)

clean_containers:
	@if [ -n "$$(docker ps -aq)" ]; then \
		docker rm $$(docker ps -aq); \
	else \
		echo "No containers to remove"; \
	fi

clean_images:
	@if [ -n "$$(docker images -q)" ]; then \
		docker rmi $$(docker images -q); \
	else \
		echo "No images to remove"; \
	fi

clean_volumes:
	@if [ -n "$$(docker volume ls -q)" ]; then \
		docker volume rm $$(docker volume ls -q); \
	else \
		echo "No volumes to remove"; \
	fi

clean_network:
	@docker network prune -f

clean_system:
	@docker system prune -f

clean_directory:
	echo "Deleting directories from volumes on the host"
	sudo sh -c "rm -Rf $(VOLUME_WORDPRESS)";
	sudo sh -c "rm -Rf $(VOLUME_DATABASE)";
	sudo sh -c "rm -Rf $(VOLUME_DATA)";

clean_all: \
	stop \
	clean_containers \
	clean_images \
	clean_volumes \
	clean_network \
	clean_system \
	clean_directory 


re_all: clean_all all
	