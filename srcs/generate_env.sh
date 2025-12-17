#!/bin/bash
# Script to generate .env file from .env.example with random passwords
# This ensures NO credentials are stored in Git

set -e

ENV_EXAMPLE="srcs/.env.example"
ENV_FILE="srcs/.env"

# Function to generate a random strong password
generate_password() {
    # Generate 16 character password with letters, numbers, and symbols
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-16
}

echo "Generating .env file with random passwords..."

# Read .env.example and replace GENERATE_RANDOM with actual random passwords
while IFS= read -r line; do
    if [[ "$line" == *"GENERATE_RANDOM"* ]]; then
        # Extract the variable name
        var_name=$(echo "$line" | cut -d'=' -f1)
        # Generate random password
        random_pw=$(generate_password)
        # Write to .env with random password
        echo "${var_name}='${random_pw}'"
    else
        # Keep the line as is (comments, non-password variables)
        echo "$line"
    fi
done < "$ENV_EXAMPLE" > "$ENV_FILE"

echo ".env file created successfully with randomly generated passwords!"
echo "All passwords are strong (16 characters, alphanumeric)."
