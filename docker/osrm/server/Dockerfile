FROM ubuntu:16.04

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ARG OSRM_VERSION
ENV OSRM_VERSION ${OSRM_VERSION:-v5.21.0}

ARG OSRM_REPOSITORY
ENV OSRM_REPOSITORY ${OSRM_REPOSITORY:-https://github.com/Project-OSRM/osrm-backend.git}
#ENV OSRM_REPOSITORY ${OSRM_REPOSITORY:-https://github.com/Mapotempo/osrm-backend.git}

# OSRM part
###########

# Install needed packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git cmake \
        libboost-all-dev libbz2-dev liblua5.2-dev libxml2-dev \
        libstxxl-dev libosmpbf-dev libprotobuf-dev libtbb-dev ca-certificates \
        curl pkg-config runit && \
    \
# Install NodeJS for osrm-isochrone-server
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    \
# Clone OSRM Backend
    git clone ${OSRM_REPOSITORY} --branch ${OSRM_VERSION} && \
    \
# Build and install
    cd osrm-backend && npm install && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_NODE_BINDINGS=On -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && make install && \
# Cleanup build directory
    cd .. && rm -rf .git build node_modules

VOLUME /srv/osrm/data

# Isochrone part
################

ARG OSRM_ISOCHRONE_VERSION
ENV OSRM_ISOCHRONE_VERSION ${OSRM_ISOCHRONE_VERSION:-5.12.1}

# Install osrm-isochrone-server
RUN cd / && echo "{\"dependencies\":{\"osrm\":\"file:////osrm-backend\",\"osrm-isochrone-server\":\"git+https://github.com/Mapotempo/osrm-isochrone-server.git#v${OSRM_ISOCHRONE_VERSION}\"}}" > package.json && \
    npm install && \
    \
# Cleanup Debian packages
    apt-get remove -y curl git build-essential && \
    apt-get autoremove -y && \
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
