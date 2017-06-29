FROM ubuntu:16.04

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ARG OSRM_VERSION
ENV OSRM_VERSION ${OSRM_VERSION:-mt-release-5.5-1-1}

ARG OSRM_REPOSITORY
ENV OSRM_REPOSITORY ${OSRM_REPOSITORY:-https://github.com/Mapotempo/osrm-backend.git}

# OSRM part
###########

# Install needed packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git cmake \
        libboost-all-dev libbz2-dev liblua5.1.0-dev libxml2-dev libluabind-dev \
        libstxxl-dev libosmpbf-dev libprotobuf-dev libtbb-dev ca-certificates && \
    \
# Clone OSRM Backend
    git clone ${OSRM_REPOSITORY} --branch ${OSRM_VERSION} && \
    \
# Build and install
    mkdir -p osrm-backend/build && cd osrm-backend/build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && make install && \
# Install needed LUA libraries
    mkdir -p /usr/share/lua/5.2 && \
    cp -r ../profiles/lib /usr/share/lua/5.2 && \
    \
# Cleanup build directory
    cd / && rm -rf osrm-backend &&\
    \
# Cleanup Debian packages
    apt-get remove -y git build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

VOLUME /srv/osrm/data

# Isochrone part
################

ARG OSRM_ISOCHRONE_VERSION
ENV OSRM_ISOCHRONE_VERSION ${OSRM_ISOCHRONE_VERSION:-5.5}

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

# Services part
###############

# Copy service files

COPY service/routed/run /etc/service/routed/run
COPY service/routed/log/run /etc/service/routed/log/run

COPY service/isochrone/run /etc/service/isochrone/run
COPY service/isochrone/log/run /etc/service/isochrone/log/run

# Copy startup and load scripts

COPY osrm-start.sh /usr/bin/osrm-start.sh
COPY osrm-load.sh /usr/bin/osrm-load.sh

ENV NODE_CONFIG "{ \"maxspeed\": 115 }"
ENV PROFILE ""
ENV REGION ""

# Define entry point
CMD [ "/usr/bin/osrm-start.sh" ]
