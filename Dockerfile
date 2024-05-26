FROM madebytimo/scripts AS builder

WORKDIR /root/builder

RUN download.sh --name scripts-infrastructure.tar.gz \
        https://github.com/mbT-Infrastructure/scripts-infrastructure/archive/refs/heads/\
main.tar.gz \
    && compress.sh --decompress scripts-infrastructure.tar.gz \
    && mv scripts-infrastructure-*/scripts scripts-infrastructure \
    && rm -r scripts-infrastructure-*/ scripts-infrastructure.tar.gz

FROM madebytimo/meshcentral
RUN ln --symbolic /app /opt/meshcentral

RUN install-autonomous.sh install Basics Scripts \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/builder/scripts-infrastructure/* /usr/local/bin
COPY meshcentral-device-scripts/* /usr/local/bin

ENV SERVER_PASSWORD=""
ENV SERVER_URL=""
ENV SERVER_USERNAME=""

COPY entrypoint.sh /entrypoint.sh
WORKDIR /media/workdir

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "test-connection.sh" ]
