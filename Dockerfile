FROM ljfranklin/terraform-resource

RUN apk update && \
    apk add jq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]