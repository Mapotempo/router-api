# Modified from Docker file from OSRM tu use Lua 5.3 in place of 5.4
# Beacause lua-sql-postgres not capataible with lua-redis Lua 5.4 in debian:bullseye
# https://github.com/Project-OSRM/osrm-backend/blob/master/docker/Dockerfile
FROM debian:bullseye-slim as builder
ARG DOCKER_TAG
ARG BUILD_CONCURRENCY
RUN mkdir -p /src  && mkdir -p /opt

RUN apt-get update && \
    apt-get -y --no-install-recommends install ca-certificates cmake make git gcc g++ libbz2-dev libxml2-dev wget \
    libzip-dev libboost1.74-all-dev lua5.3 liblua5.3-dev pkg-config -o APT::Install-Suggests=0 -o APT::Install-Recommends=0

# libtbb-dev

RUN NPROC=${BUILD_CONCURRENCY:-$(nproc)} && \
    ldconfig /usr/local/lib && \
    git clone --branch v2021.3.0 --single-branch https://github.com/oneapi-src/oneTBB.git && \
    cd oneTBB && \
    mkdir build && \
    cd build && \
    cmake -DTBB_TEST=OFF -DCMAKE_BUILD_TYPE=Release ..  && \
    cmake --build . && \
    cmake --install .

ARG OSRM_VERSION
ENV OSRM_VERSION ${OSRM_VERSION:-v5.27.1}


ARG OSRM_REPOSITORY
ENV OSRM_REPOSITORY ${OSRM_REPOSITORY:-https://github.com/Project-OSRM/osrm-backend.git}

RUN git clone ${OSRM_REPOSITORY} --branch ${OSRM_VERSION} src
WORKDIR /src

# RUN NPROC=${BUILD_CONCURRENCY:-$(nproc)} && \
RUN NPROC=1 && \
    echo "Building OSRM ${DOCKER_TAG}" && \
    git show --format="%H" | head -n1 > /opt/OSRM_GITSHA && \
    echo "Building OSRM gitsha $(cat /opt/OSRM_GITSHA)" && \
    mkdir -p build && \
    cd build && \
    BUILD_TYPE="Release" && \
    ENABLE_ASSERTIONS="Off" && \
    BUILD_TOOLS="Off" && \
    case ${DOCKER_TAG} in *"-debug"*) BUILD_TYPE="Debug";; esac && \
    case ${DOCKER_TAG} in *"-assertions"*) BUILD_TYPE="RelWithDebInfo" && ENABLE_ASSERTIONS="On" && BUILD_TOOLS="On";; esac && \
    echo "Building ${BUILD_TYPE} with ENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} BUILD_TOOLS=${BUILD_TOOLS}" && \
    cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} -DBUILD_TOOLS=${BUILD_TOOLS} -DENABLE_LTO=On && \
    make -j${NPROC} install && \
    cd ../profiles && \
    cp -r * /opt && \
    strip /usr/local/bin/* && \
    rm -rf /src


# Multistage build to reduce image size - https://docs.docker.com/engine/userguide/eng-image/multistage-build/#use-multi-stage-builds
# Only the content below ends up in the image, this helps remove /src from the image (which is large)
FROM debian:bullseye-slim as runstage

COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt /opt

RUN apt-get update && \
    apt-get install -y --no-install-recommends libboost-program-options1.74.0 libboost-regex1.74.0 \
        libboost-date-time1.74.0 libboost-chrono1.74.0 libboost-filesystem1.74.0 \
        libboost-iostreams1.74.0 libboost-system1.74.0 libboost-thread1.74.0 \
        expat liblua5.3-0 && \
    rm -rf /var/lib/apt/lists/* && \
# add /usr/local/lib to ldconfig to allow loading libraries from there
    ldconfig /usr/local/lib

RUN /usr/local/bin/osrm-extract --help && \
    /usr/local/bin/osrm-routed --help && \
    /usr/local/bin/osrm-contract --help && \
    /usr/local/bin/osrm-partition --help && \
    /usr/local/bin/osrm-customize --help

WORKDIR /opt

EXPOSE 5000

############ END of Dockerfile from OSRM

# ARG OSRM_VERSION
# FROM ghcr.io/project-osrm/osrm-backend:${OSRM_VERSION:-v5.27.1}

VOLUME /srv/osrm/data

# Build
RUN apt update && \
    apt install -y --no-install-recommends \
        lua-sql-postgres \
        lua-redis \
        osmosis \
        osmium-tool \
        wget \
        curl

# Runtime
RUN apt update && \
    apt install -y runit nodejs npm curl

# Add missing files in installed OSM. v5.27.1. Fixed on OSRM PR https://github.com/Project-OSRM/osrm-backend/pull/6699
RUN mkdir -p /usr/local/share/osrm/data/ && \
    curl https://raw.githubusercontent.com/Project-OSRM/osrm-backend/master/data/driving_side.geojson > /usr/local/share/osrm/data/driving_side.geojson && \
    curl https://raw.githubusercontent.com/Project-OSRM/osrm-backend/master/data/maxheight.geojson > /usr/local/share/osrm/data/maxheight.geojson

# Isochrone part
################

ARG OSRM_ISOCHRONE_VERSION
ENV OSRM_ISOCHRONE_VERSION ${OSRM_ISOCHRONE_VERSION:-5.12.1}

# Install osrm-isochrone-server
RUN echo "{\"dependencies\":{\"osrm\":\"file:////osrm-backend\",\"osrm-isochrone-server\":\"git+https://github.com/Mapotempo/osrm-isochrone-server.git#v${OSRM_ISOCHRONE_VERSION}\"}}" > package.json && \
    npm install

# Services part
###############

# Copy service files

COPY service/routed/run /etc/service/routed/run
# COPY service/routed/log/run /etc/service/routed/log/run

COPY service/isochrone/run /etc/service/isochrone/run
# COPY service/isochrone/log/run /etc/service/isochrone/log/run

# Copy startup and load scripts

COPY osrm-start.sh /usr/bin/osrm-start.sh
COPY osrm-load.sh /usr/bin/osrm-load.sh
COPY osrm-build.sh /usr/bin/osrm-build.sh

ENV NODE_CONFIG "{ \"maxspeed\": 115 }"
ENV PROFILE ""
ENV REGION ""

# Define entry point
CMD [ "/usr/bin/osrm-start.sh" ]

# Monkey patch of isochrone
RUN sed -i "s/true, distance_table:/true, algorithm: argv['algorithm'], distance_table:/" node_modules/osrm-isochrone-server/server.js
