# Use an official Alpine Linux runtime as a parent image
FROM alpine:3.16

# Set the maintainer label
LABEL maintainer="Taylor Otwell"

# Define arguments for the Dockerfile
ARG WWWGROUP
ARG NODE_VERSION=20
ARG POSTGRES_VERSION=15

# Set the working directory
WORKDIR /var/www/html

# Set environment variables
ENV TZ=UTC
ENV SUPERVISOR_PHP_COMMAND="/usr/bin/php -d variables_order=EGPCS /var/www/html/artisan serve --host=0.0.0.0 --port=80"
ENV SUPERVISOR_PHP_USER="sail"

# Set the timezone
RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# Install system dependencies and PHP 8.2
RUN apk add --no-cache curl ca-certificates zip unzip git \
    && wget -q -O /etc/apk/keys/ppa_ondrej_php.rsa.pub https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c \
    && echo "https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apk/repositories \
    && apk add --no-cache php8.2-cli php8.2-dev php8.2-pgsql php8.2-sqlite3 php8.2-gd php8.2-imagick php8.2-curl php8.2-redis \
    && wget -q -O composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/bin --filename=composer \
    && rm composer-setup.php

# Install Node.js and NPM packages
RUN wget -q -O - https://deb.nodesource.com/setup_$NODE_VERSION.x | sh \
    && apk add --no-cache nodejs \
    && npm install -g npm

# Install PostgreSQL client and Nginx
RUN wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apk key add - \
    && echo "https://dl.postgresql.org/alpine/repos/edge/main" > /etc/apk/repositories \
    && apk add --no-cache postgresql-client=$POSTGRES_VERSION nginx

# Set capabilities for PHP
RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.2

# Create the sail user and group
RUN addgroup -g $WWWGROUP sail \
    && adduser -u 1337 -G sail -s /bin/sh -D sail

# Copy configuration files
COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.2/cli/conf.d/99-sail.ini
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN chmod +x /usr/local/bin/start-container

# Expose the default Laravel port
EXPOSE 80

# Set the entrypoint
ENTRYPOINT ["start-container"]
