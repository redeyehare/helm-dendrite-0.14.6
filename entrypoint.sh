#!/bin/sh

# Detect environment to set paths correctly
# If running in our Docker container, we use /etc/dendrite and /usr/bin
if [ -f "/etc/dendrite/dendrite-leapcell.yaml" ]; then
    CONFIG_FILE="/etc/dendrite/dendrite-leapcell.yaml"
    KEY_FILE="/etc/dendrite/matrix_key.pem"
    GEN_KEYS_CMD="/usr/bin/generate-keys"
else
    # Fallback to current directory for Source Build or local testing
    CONFIG_FILE="./dendrite-leapcell.yaml"
    KEY_FILE="./matrix_key.pem"
    GEN_KEYS_CMD="./generate-keys"
fi

echo "Using config file: $CONFIG_FILE"

# 1. Generate matrix key if it doesn't exist
if [ ! -f "$KEY_FILE" ]; then
    echo "Generating new matrix key at $KEY_FILE..."
    if [ -x "$GEN_KEYS_CMD" ]; then
        "$GEN_KEYS_CMD" --private-key "$KEY_FILE"
    elif command -v generate-keys >/dev/null 2>&1; then
        generate-keys --private-key "$KEY_FILE"
    else
         echo "WARNING: generate-keys binary not found. Key generation skipped."
    fi
else
    echo "Matrix key already exists at $KEY_FILE"
fi

# 2. Inject Database Connection String from Environment Variable
# Use DATABASE_CONNECTION_STRING instead of LEAPCELL_DB_CONNECTION_STRING
if [ -n "$DATABASE_CONNECTION_STRING" ]; then
    echo "Injecting DATABASE_CONNECTION_STRING into config..."
    # Use | as delimiter for sed to avoid issues with / in urls
    sed -i "s|LEAPCELL_DB_CONNECTION_STRING|$DATABASE_CONNECTION_STRING|g" "$CONFIG_FILE"
else
    echo "WARNING: DATABASE_CONNECTION_STRING environment variable is not set!"
fi

# 3. Exec the CMD passed to the script
exec "$@"
