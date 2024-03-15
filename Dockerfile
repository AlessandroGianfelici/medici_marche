FROM debian:bullseye-slim as builder
ARG DOCKER_TAG
ARG BUILD_CONCURRENCY
RUN mkdir -p /src  && mkdir -p /opt


RUN apt-get update && \
    apt-get -y --no-install-recommends install ca-certificates cmake make git gcc g++ libbz2-dev libxml2-dev wget \
    libzip-dev libtbb2 libboost1.74-all-dev lua5.4 liblua5.4-dev pkg-config -o APT::Install-Suggests=0 -o APT::Install-Recommends=0

RUN NPROC=${BUILD_CONCURRENCY:-$(nproc)} && \
    ldconfig /usr/local/lib && \
    git clone --branch v2021.3.0 --single-branch https://github.com/oneapi-src/oneTBB.git && \
    cd oneTBB && \
    mkdir build && \
    cd build && \
    cmake -DTBB_TEST=OFF -DCMAKE_BUILD_TYPE=Release ..  && \
    cmake --build . && \
    cmake --install .


RUN apt-get update && \
    apt-get install -y --no-install-recommends libboost-program-options1.74.0 libboost-regex1.74.0 \
        libboost-date-time1.74.0 libboost-chrono1.74.0 libboost-filesystem1.74.0 \
        libboost-iostreams1.74.0 libboost-system1.74.0 libboost-thread1.74.0 \
        expat liblua5.4-0 libtbb2

RUN git clone https://github.com/Project-OSRM/osrm-backend.git
WORKDIR /osrm-backend

RUN NPROC=${BUILD_CONCURRENCY:-$(nproc)} && \
    echo "Building OSRM ${DOCKER_TAG}" && \
    git show --format="%H" | head -n1 > /opt/OSRM_GITSHA && \
    echo "Building OSRM gitsha $(cat /opt/OSRM_GITSHA)" && \
    mkdir -p build && \
    cd build && \
    BUILD_TYPE="Release" && \
    ENABLE_ASSERTIONS="Off" && \
    BUILD_TOOLS="On" && \
    case ${DOCKER_TAG} in *"-debug"*) BUILD_TYPE="Debug";; esac && \
    case ${DOCKER_TAG} in *"-assertions"*) BUILD_TYPE="RelWithDebInfo" && ENABLE_ASSERTIONS="On" && BUILD_TOOLS="On";; esac && \
    echo "Building ${BUILD_TYPE} with ENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} BUILD_TOOLS=${BUILD_TOOLS}" && \
    cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DENABLE_ASSERTIONS=${ENABLE_ASSERTIONS} -DBUILD_TOOLS=${BUILD_TOOLS} -DENABLE_LTO=On && \
    make install && apt-get clean

WORKDIR /

COPY "requirements.txt" .
COPY "osm_dumps/centro-latest.osm.pbf" .

RUN osrm-extract -p osrm-backend/profiles/car.lua centro-latest.osm.pbf && \
    osrm-partition centro-latest.osrm && \
    cp /usr/local/lib/libtbb.so.12 /usr/lib/libtbb.so.12 && \
    osrm-customize centro-latest.osrm && \
    osrm-contract centro-latest.osrm && \
    apt install -y pip && pip install -r requirements.txt && \
    rm -rf centro-latest.osm.pbf

COPY "trova_medico.py" .
COPY "run.sh" .

#CMD ["bash", "run.sh"]