#!/bin/sh
set -e
cd /app

if [ ! -f "/var/lib/brick-x-auth/data/users.json" ]; then
  echo "Importing initial data from /app/init..."
  /app/seeder -data /app/init
fi

exec /app/auth 