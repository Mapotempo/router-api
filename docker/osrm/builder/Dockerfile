FROM debian:stretch

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

# Builder part
##############

# Install needed packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends lua-sql-postgres lua-redis osmosis osmium-tool wget curl && \
    \
# Cleanup Debian packages
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Copy stxxl configuration file.
COPY stxxl .stxxl
COPY osrm-build.sh /usr/bin/osrm-build.sh
COPY osm-manage.sh /usr/bin/osm-manage.sh

VOLUME /srv/osrm/profiles

VOLUME /srv/osm

ENV REGION ""
ENV PROFILE ""
ENV ADDITIONAL_PARAMS ""

CMD /usr/bin/osrm-build.sh -p ${PROFILE} -r ${REGION} ${ADDITIONAL_PARAMS}
