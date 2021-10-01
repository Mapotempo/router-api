# Building images
```
export REGISTRY='registry.mapotempo.com/'
```

### OSRM

```
cd ./docker/osrm/
export OSRM_VERSION=v5.21.0
export OSRM_ISOCHRONE_VERSION=5.12.1
docker build --build-arg OSRM_VERSION=${OSRM_VERSION} \
  --build-arg OSRM_ISOCHRONE_VERSION=${OSRM_ISOCHRONE_VERSION} \
  -f Dockerfile -t ${REGISTRY}mapotempo/osrm-server:${OSRM_VERSION} .
```

### OTP
```
cd ./docker/otp/
export OTP_VERSION=1.5.0
docker build --build-arg OTP_VERSION=${OTP_VERSION} \
  -f Dockerfile -t ${REGISTRY}mapotempo/otp-server:${OTP_VERSION} .
```

### ROUTER
```
docker build -f ./docker/Dockerfile -t ${REGISTRY}mapotempo/router-api:latest .
```

# Requirement
  apt-get install -y jq

## OTP

### Build OTP graphs

    # cd router-wrapper/docker/otp
    ./otp-rebuild-all.sh

### Build a single OTP graph

The following script will build `bordeaux` graph from `./otp/data/graphs` in `/srv/docker`

    # cd router-wrapper/docker/otp
    ./otp-rebuild.sh bordeaux

Finally run the services:

    docker-compose -p router up -d
