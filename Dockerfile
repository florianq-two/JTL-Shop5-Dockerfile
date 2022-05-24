FROM composer:latest

ADD https://gitlab.com/jtl-software/jtl-shop/core/-/archive/v5.1.2/core-v5.1.2.tar.gz /app
RUN sh -c "tar -xzf *.tar.gz"
RUN sh -c "rm *.tar.gz"
RUN sh -c "mv core* core"


COPY install core/install

WORKDIR /app/core/includes

RUN ["composer", "--ignore-platform-req=ext-bcmath", "--ignore-platform-req=ext-gd", "--ignore-platform-req=ext-intl", "--ignore-platform-req=ext-soap", "update"]
RUN ["composer", "--ignore-platform-req=ext-bcmath", "--ignore-platform-req=ext-gd", "--ignore-platform-req=ext-intl", "--ignore-platform-req=ext-soap", "install"]


FROM php:8.0-rc-apache-bullseye

RUN apt update && apt upgrade -y && apt autoremove -y && apt install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev\
    libicu-dev libxml2-dev libzip-dev zip libmagickwand-dev

COPY php.ini /usr/local/etc/php/php.ini
RUN a2enmod rewrite && service apache2 restart

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl pdo_mysql soap bcmath zip

RUN pecl install imagick && docker-php-ext-enable imagick

COPY --from=0 /app/core ./

RUN ["chown", "-R", "www-data:www-data", "../html"]

EXPOSE 80