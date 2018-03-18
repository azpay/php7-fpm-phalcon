FROM php:7.0-fpm
STOPSIGNAL WINCH

RUN \
    apt-get update && \
    apt-get install -y libmemcached-dev git vim locate ntp ntpdate nginx supervisor cron libxml2-dev libwebp-dev libjpeg62-turbo-dev libpng12-dev libfreetype6-dev libmcrypt-dev libssl-dev libgmp-dev libicu-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/list/*

RUN \
    cd ${HOME} && \
    git clone https://github.com/phalcon/cphalcon.git && \
    cd cphalcon/build/php7/64bits && \
    phpize && \
    export CFLAGS="-O1 -g" && \
    ./configure && \
    make && make install && \
    docker-php-ext-enable phalcon && \
    rm -rf ${HOME}/cphalcon


RUN \
    docker-php-ext-configure pdo_mysql && \
    docker-php-ext-configure mbstring && \
    docker-php-ext-configure sockets && \
    docker-php-ext-configure opcache && \
    docker-php-ext-configure exif && \
    docker-php-ext-configure mcrypt && \
    docker-php-ext-configure bcmath && \
    docker-php-ext-configure intl && \
    docker-php-ext-install soap pdo_mysql mbstring sockets opcache exif mcrypt bcmath intl


RUN curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" \
    && mkdir -p /usr/src/php/ext/memcached \
    && tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && docker-php-ext-configure memcached \
    && docker-php-ext-install memcached \
    && rm /tmp/memcached.tar.gz

RUN pecl install apcu-5.1.3 \
    && pecl install apcu_bc-1.0.3 \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

RUN \
    mkdir -p ${HOME}/php-default-conf && \
    cp -R /usr/local/etc/* ${HOME}/php-default-conf


RUN echo "America/Sao_Paulo" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata


RUN usermod -u 1000 www-data
RUN echo 'date.timezone="America/Sao_Paulo"' >> /usr/local/etc/php/conf.d/date.ini
RUN echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/opcache.conf
RUN echo 'opcache.validate_timestamps=0' >> /usr/local/etc/php/conf.d/opcache.conf
RUN echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache.conf


RUN rm /etc/localtime && \
    ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    "date"

CMD ["/usr/bin/supervisord"]
