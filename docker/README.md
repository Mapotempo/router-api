Using Docker Compose to deploy Mapotempo Router environment
===========================================================

Building images
---------------

The following commands will get the source code and build the router-wrapper
and needed images:

    git clone https://github.com/mapotempo/router-wrapper
    cd router-wrapper/docker
    docker-compose build

Publishing images
-----------------

To pull them from another host, we need to push the built images to
hub.docker.com:

    docker login
    docker-compose push

Running on a docker host
------------------------

First, we need to retrieve the source code and the prebuilt images:

    git clone https://github.com/mapotempo/router-wrapper
    cd router-wrapper/docker
    docker-compose pull

Then use the configuration file and edit it to match your needs:

    # Copy production configuration file
    cp ../config/environments/production.rb ./

Finally run the services:

    docker-compose -p router up -d

Using builder with Docker
=========================

Building images
---------------

The following commands will get the source code and build the OSRM builder
and needed images:

    git clone https://github.com/mapotempo/router-wrapper
    cd router-wrapper/docker
    docker-compose -f docker-compose.builder.yml build

Publishing images
-----------------

To pull them from another host, we need to push the built images to
hub.docker.com:

    docker login
    docker-compose push

Running on a docker host
------------------------

First, we need to retrieve the source code and the prebuilt images:

    git clone https://github.com/mapotempo/router-wrapper
    cd router-wrapper/docker
    docker-compose -f docker-compose.builder.yml pull

Run the services:

    docker-compose -f docker-compose.builder.yml -p router up -d

The builder service will not stay, it is normal, the `db` and `redis-cache`
services must be running.

Initializing the builder database
---------------------------------

Before running the builder on profile `car`, we need to initialize the
database:

    TODO Alexis Lahouze 2017-06-30 

Running the builder
-------------------

In the following, `${PROFILE}` must be replaced by the profile name,
`${REGION}` by the region name like `france`, and `${REGION_PATH}` by the
region path on Geofrabrik like `europe/france`.

Before running the builder we also need a profile in `docker/osrm/profiles/`.
The profile must follow the name scheme: `profile-${PROFILE}.lua`.

To run a build, enter the following command:

    docker-compose -p builder -f docker-compose.builder.yml run builder \
        /usr/bin/osrm-build.sh -p ${PROFILE} -r ${REGION_PATH}

The data will be generated in `/srv/osrm/data`.

Reload the data
---------------

Once the data has been built you need to reload it in the corresponding
container:

    docker-compose -p router exec osrm-${PROFILE}-${REGION} /usr/bin/osrm-load.sh ${PROFILE} ${REGION}
    docker-compose -p router exec osrm-${PROFILE}-${REGION} sv restart router
    docker-compose -p router exec osrm-${PROFILE}-${REGION} sv restart isochrone

You can check if the data has been loaded in the host daemon logs:

    grep ${REGION}-${PROFILE} /var/log/daemon.log
