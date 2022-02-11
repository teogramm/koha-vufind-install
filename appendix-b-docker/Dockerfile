FROM debian:buster

RUN apt-get  update \
    && apt-get install -y \
            wget \
            supervisor \
            apache2 \
            gnupg2 \
            apt-transport-https \
            memcached \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO /etc/apt/trusted.gpg.d/koha.asc https://debian.koha-community.org/koha/gpg.asc && \
    echo "deb https://debian.koha-community.org/koha stable main" | tee /etc/apt/sources.list.d/koha.list

# Install Koha
RUN apt-get update \
         && apt-get install -y koha-common \
         && rm -rf /var/cache/apt/archives/* \
         && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite \
    && a2enmod headers \
    && a2enmod proxy_http \
    && a2enmod cgi \
    && a2dissite 000-default \
    && echo "Listen 8081\nListen 8080" > /etc/apache2/ports.conf

RUN mkdir /docker

COPY files/run.sh /docker/run.sh
COPY templates /docker/templates
COPY files/rabbitmq.sh /docker/
COPY files/rabbitmq.conf /etc/supervisor/conf.d

WORKDIR /docker

EXPOSE 2100 6001 8080 8081

CMD [ "./run.sh" ]
