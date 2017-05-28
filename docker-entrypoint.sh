#!/bin/bash

postgres_ready() {
	echo "Checking postgres at ${PGHOST}"
	python3 /docker/postgres_ready.py
}

until postgres_ready; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - continuing..."

python3 manage.py migrate
python3 /docker/create_admin.py

for f in /docker/docker-entrypoint.d/*; do
	case "$f" in
		*.sh)     echo "$0: running $f"; . "$f" ;;
		*)        echo "$0: ignoring $f" ;;
	esac
done

# Start Gunicorn processes
echo Starting Gunicorn.
gunicorn ${DJANGO_WSGI_MODULE}:application \
	--log-level ${GUNICORN_LOG_LEVEL:-info} \
	--bind 0.0.0.0:8000 \
	--workers ${DJANGO_WORKERS:-4} \
	"$@" &

nginx -t;
nginx -g 'daemon off;'
