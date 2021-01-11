FROM phusion/passenger-ruby25

ARG BUNDLE_WITHOUT="development test"

# Set correct environment variables.
ENV LANG C.UTF-8
ENV HOME /root

LABEL maintainer="Mapotempo <tech@mapotempo.com>"

ENV REDIS_HOST redis-cache

ADD . /srv/app
WORKDIR /srv/app
# Install app
RUN apt-get update  > /dev/null && \
    apt-get install -y git build-essential zlib1g-dev zlib1g  > /dev/null
RUN gem install bundler --version 1.17.3
RUN bundle install --path vendor/bundle --full-index --without ${BUNDLE_WITHOUT}

# Cleanup Debian packages
RUN apt-get remove -y git build-essential zlib1g-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

# Enable app
ADD docker/env.d/* /etc/nginx/main.d/
ADD docker/snippets/* /etc/nginx/snippets/
ADD docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf
