ARG OSRM_VERSION

FROM mapotempo/osrm:${OSRM_VERSION}

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ARG OSRM_ISOCHRONE_VERSION
ENV OSRM_ISOCHRONE_VERSION ${OSRM_ISOCHRONE_VERSION:-5.5}

# Isochrone part
################

# Install needed packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl pkg-config && \
    \
# Install NodeJS and osrm-isochrone-server
    curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g https://github.com/Mapotempo/osrm-isochrone-server/tarball/v${OSRM_ISOCHRONE_VERSION} && \
    \
# Install runit
    apt-get install -y --no-install-recommends runit && \
    \
# Cleanup Debian packages
    apt-get autoremove -y curl && \
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Copy service files

COPY service/routed/run /etc/service/routed/run
COPY service/routed/log/run /etc/service/routed/log/run

COPY service/isochrone/run /etc/service/isochrone/run
COPY service/isochrone/log/run /etc/service/isochrone/log/run

# Copy startup script

COPY osrm-start.sh /usr/bin/osrm-start.sh
COPY osrm-load.sh /usr/bin/osrm-load.sh

VOLUME /srv/osrm/isochrone

ENV NODE_CONFIG "{ \"maxspeed\": 115 }"
ENV PROFILE ""
ENV REGION ""

# Define entry point
ENTRYPOINT [ "/usr/bin/osrm-start.sh" ]
