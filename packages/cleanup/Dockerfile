ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN apt-get update -y || true ; \
    apt-get upgrade -y || true ; \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN rm -rf /tmp/* /opt/*

RUN find / -name "*.deb" -exec rm {} \;

RUN find / -name "*.whl" -exec rm {} \;
