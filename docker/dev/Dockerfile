# Take car of the latest version containing bundler 1.17
FROM ruby:2.5

ARG BUNDLE_WITHOUT="production"

# Set correct environment variables.
ENV LANG C.UTF-8
ENV HOME /root


ENV REDIS_HOST redis-cache

ADD . /srv/app
WORKDIR /srv/app

# Install app
# because of Certificate verification failed
RUN apt update && apt upgrade -y
RUN apt-get install -y git build-essential zlib1g-dev zlib1g  > /dev/null
RUN gem install bundler --version 1.17.3
RUN bundle install --path vendor/bundle --full-index --without ${BUNDLE_WITHOUT}
