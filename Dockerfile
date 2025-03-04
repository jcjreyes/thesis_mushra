# Use the official Python image as the base
FROM python:3.6-slim

# Install necessary packages
RUN apt-get update && \
    apt-get install -y nginx && \
    pip install uwsgi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the application code
COPY . /app

# Install Python dependencies
RUN python -m venv /app/venv && \
    /app/venv/bin/pip install --upgrade pip && \
    /app/venv/bin/pip install -r requirements.txt

# Configure uWSGI
RUN echo "[uwsgi]" > /app/uwsgi.ini && \
    echo "module = wsgi:application" >> /app/uwsgi.ini && \
    echo "virtualenv = /app/venv" >> /app/uwsgi.ini && \
    echo "socket = /tmp/webmushra.sock" >> /app/uwsgi.ini && \
    echo "chmod-socket = 666" >> /app/uwsgi.ini && \
    echo "manage-script-name = true" >> /app/uwsgi.ini && \
    echo "mount = /webmushra=wsgi:application" >> /app/uwsgi.ini

# Configure Nginx
RUN rm /etc/nginx/sites-enabled/default && \
    echo "server {" > /etc/nginx/sites-available/webmushra && \
    echo "    listen 80;" >> /etc/nginx/sites-available/webmushra && \
    echo "    server_name localhost;" >> /etc/nginx/sites-available/webmushra && \
    echo "    location /webmushra {" >> /etc/nginx/sites-available/webmushra && \
    echo "        include uwsgi_params;" >> /etc/nginx/sites-available/webmushra && \
    echo "        uwsgi_pass unix:/tmp/webmushra.sock;" >> /etc/nginx/sites-available/webmushra && \
    echo "    }" >> /etc/nginx/sites-available/webmushra && \
    echo "}" >> /etc/nginx/sites-available/webmushra && \
    ln -s /etc/nginx/sites-available/webmushra /etc/nginx/sites-enabled/

# Expose port 80
EXPOSE 80

# Start uWSGI and Nginx
CMD /app/venv/bin/uwsgi --ini /app/uwsgi.ini & nginx -g 'daemon off;'

