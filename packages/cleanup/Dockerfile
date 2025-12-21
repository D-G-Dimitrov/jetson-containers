ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN apt-get update -y || true ; \
    apt-get upgrade -y || true ; \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN rm -rf /tmp/* /opt/wheels /opt/vllm /root/.cache/ /root/.triton/ /root/.rustup

RUN find /opt -maxdepth 1 ! -name 'venv' ! -name '.' ! -name 'opt' -type d -exec rm -rf {} \;

RUN find / -name "*.deb" -exec rm {} \;

RUN find / -name "*.whl" -exec rm {} \;

#ENTRYPOINT ["/bin/bash"]

#CMD [ "bash", "start.sh"]
