FROM ljfranklin/terraform-resource

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]