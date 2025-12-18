#!/bin/bash

# Generate SSL certificate with error handling
openssl ecparam -genkey -name prime256v1 -out /tmp/nginx.key
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate SSL private key"
    exit 1
fi

openssl req -new -x509 -key /tmp/nginx.key\
	-out /tmp/nginx.crt -days 365 \
	-subj "/C=BR/\
			ST=Sao Paulo/\
			L=42SP/\
			OU=42SP/\
			CN=paranha.42.fr\
			emailAddress=paranha@student.42.fr"
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate SSL certificate"
    exit 1
fi

# Verify certificate was created successfully
if [ ! -f /tmp/nginx.crt ]; then
    echo "Error: SSL certificate file not found"
    exit 1
fi

if [ ! -f /tmp/nginx.key ]; then
    echo "Error: SSL private key file not found"
    exit 1
fi

echo "SSL certificate generated successfully"