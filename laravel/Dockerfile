FROM php:8.2.8-apache

# install the php extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd pdo_mysql zip intl soap pcntl bcmath calendar mysqli opcache sockets apcu

# set webroot
ENV APACHE_DOCUMENT_ROOT /var/app/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && sed -ri 's|80|8080|g' /etc/apache2/sites-available/*.conf
RUN sed -ri 's|80|8080|g' /etc/apache2/ports.conf && sed -ri 's|443|8081|g' /etc/apache2/ports.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# enable apache mods
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod ssl

# install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# setup vault stuff
RUN mkdir /etc/vault
COPY .infrastructure/vault /etc/vault
RUN chmod 777 /etc/vault
VOLUME ["/etc/vault"]

# copy the resources
COPY . /var/app

# use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# utc time
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo "date.timezone=$TZ" > $PHP_INI_DIR/conf.d/timezone.ini

# php settings
RUN echo "memory_limit=8192M" >> $PHP_INI_DIR/conf.d/memory.ini
RUN echo "display_errors=1" >> $PHP_INI_DIR/conf.d/errors.ini
RUN echo "display_startup_errors=1" >> $PHP_INI_DIR/conf.d/errors.ini
RUN echo "error_reporting=E_ALL" >> $PHP_INI_DIR/conf.d/errors.ini
RUN echo "upload_max_filesize=100M" >> $PHP_INI_DIR/conf.d/upload.ini
RUN echo "post_max_size=100M" >> $PHP_INI_DIR/conf.d/postsize.ini
RUN echo "opcache.enable=1" >> $PHP_INI_DIR/conf.d/opcache.ini
RUN echo "opcache.enable_cli=1" >> $PHP_INI_DIR/conf.d/opcache.ini
RUN echo "opcache.jit=tracing" >> $PHP_INI_DIR/conf.d/opcache.ini
RUN echo "opcache.jit_buffer_size=100M" >> $PHP_INI_DIR/conf.d/opcache.ini

# www data owns this stuff below and can run apache, provided we fix the port
RUN chown -R www-data:www-data /var/app && chown -R www-data:www-data /etc/vault

# run it as user www-data and not root
USER www-data

# install composer dependencies
RUN cd /var/app && composer install -n --prefer-dist --optimize-autoloader --no-scripts --apcu-autoloader

# set permissions
RUN chmod -R 777 /var/app/storage

#  run on 8080 for no root
EXPOSE 8080

# run apache
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
