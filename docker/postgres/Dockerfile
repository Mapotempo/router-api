FROM postgres:9.6

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

# Install app
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-9.6-postgis-2.3 && \
    \
# Cleanup Debian packages
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
