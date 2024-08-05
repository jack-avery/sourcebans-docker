FROM composer:2.5.8 AS composer

RUN git clone https://github.com/sbpp/sourcebans-pp.git && \
    git -C sourcebans-pp checkout ${CHECKOUT}

# Build the actual image
FROM php:8.1-apache

ARG CHECKOUT=1.7.0
ENV INSTALL=false

RUN savedAptMark="$(apt-mark showmanual)" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libgmp-dev \
    && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure gmp && \
    docker-php-ext-install gmp mysqli pdo_mysql bcmath && \
    apt-mark auto '.*' > /dev/null && \
    apt-mark manual $savedAptMark && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

RUN mkdir /docker/ && \
    mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf && \
    sed -i 's/80/8080/g' /etc/apache2/sites-enabled/000-default.conf


# this sucks!
RUN apt update && apt install -y --no-install-recommends git unzip

COPY --from=composer /app/sourcebans-pp/web /usr/src/sourcebans
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --no-interaction --no-progress --no-suggest --optimize-autoloader --working-dir=/usr/src/sourcebans
RUN chown -R www-data:www-data /var/www/html

COPY docker-sourcebans-entrypoint.sh /docker/docker-sourcebans-entrypoint.sh
COPY sourcebans.ini /usr/local/etc/php/conf.d/sourcebans.ini

RUN chmod +x /docker/docker-sourcebans-entrypoint.sh

ENTRYPOINT ["/docker/docker-sourcebans-entrypoint.sh"]
CMD ["apache2-foreground"]
