FROM ljfranklin/terraform-resource:0.12.29

RUN apk update && \
    apk add \
        jq \
        sshpass \
        sudo \
        curl \
        curl-dev

RUN apk add --no-cache \
        python3 \
        py3-pip \
    && pip3 install --upgrade pip \
    && pip3 install \
        awscli \
    && rm -rf /var/cache/apk/*

RUN curl -L https://github.com/vmware/govmomi/releases/download/v0.23.0/govc_linux_amd64.gz | gunzip > /usr/local/bin/govc && \
    chmod +x /usr/local/bin/govc
    
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
