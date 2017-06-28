FROM ubuntu:16.04

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ARG OSRM_VERSION
ENV OSRM_VERSION ${OSRM_VERSION:-5.5.2}

ARG OSRM_REPOSITORY
ENV OSRM_REPOSITORY ${OSRM_REPOSITORY:-https://github.com/Project-OSRM/osrm-backend.git}

# Install needed packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git cmake \
        libboost-all-dev libbz2-dev liblua5.1.0-dev libxml2-dev libluabind-dev \
        libstxxl-dev libosmpbf-dev libprotobuf-dev libtbb-dev ca-certificates && \
    \
# Clone OSRM Backend
    git clone ${OSRM_REPOSITORY} --branch v${OSRM_VERSION} && \
    \
# Build and install
    mkdir -p osrm-backend/build && cd osrm-backend/build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && make install && \
# Install needed LUA libraries
    mkdir -p /usr/share/lua/5.2 && \
    cp -r osrm-backend/profiles/lib /usr/share/lua/5.2 && \
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
