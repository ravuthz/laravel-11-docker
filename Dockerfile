ARG PHP_VERSION=8.3
ARG NODE_VERSION=20

FROM node:${NODE_VERSION}-alpine AS node

FROM php:${PHP_VERSION}-alpine

ENV SERVER_NAME="http://"

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/composer
ENV PATH=$PATH:/composer/vendor/bin

RUN echo "UTC" > /etc/timezone

RUN apk add --update --no-cache git zip bash sudo shadow openrc

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd zip pcntl sockets pdo_sqlite pdo_mysql pdo_pgsql @composer

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/bin /usr/local/bin
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/include /usr/local/include

RUN chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

COPY . .

RUN composer install

RUN ls -lah

RUN apk add jq

RUN node -v && npm -v

ADD --chmod=0755 "https://github.com/dunglas/frankenphp/releases/download/v1.2.2/frankenphp-linux-x86_64" /usr/local/bin/frankenphp

EXPOSE 9000

ENTRYPOINT ["frankenphp", "php-server", "--listen", ":9000", "--root", "/var/www/html/public/"]
