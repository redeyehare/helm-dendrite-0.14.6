#!/bin/sh

# Set the config file path
CONFIG_FILE="/etc/dendrite/dendrite-leapcell.yaml"
KEY_FILE="/etc/dendrite/matrix_key.pem"

echo "Using config file: $CONFIG_FILE"

# 1. Generate matrix key if it doesn't exist
if [ ! -f "$KEY_FILE" ]; then
    echo "Generating new matrix key at $KEY_FILE..."
    /usr/bin/generate-keys --private-key "$KEY_FILE"
else
    echo "Matrix key already exists at $KEY_FILE"
fi

# 2. Inject Database Connection String from Environment Variable
if [ -n "$LEAPCELL_DB_CONNECTION_STRING" ]; then
    echo "Injecting LEAPCELL_DB_CONNECTION_STRING into config..."
    # Use | as delimiter for sed to avoid issues with / in urls
    sed -i "s|LEAPCELL_DB_CONNECTION_STRING|$LEAPCELL_DB_CONNECTION_STRING|g" "$CONFIG_FILE"
else
    echo "WARNING: LEAPCELL_DB_CONNECTION_STRING environment variable is not set!"
fi

# 3. Exec the CMD passed to the docker container (which calls dendrite)
exec "$@"
