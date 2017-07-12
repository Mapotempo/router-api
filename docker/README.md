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
