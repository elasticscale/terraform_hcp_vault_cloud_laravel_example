FROM hashicorp/vault:1.14
RUN mkdir /etc/vault
RUN chmod 777 /etc/vault
# we need to do this otherwise the mount doesnt show up in the ECS containers
VOLUME ["/etc/vault"]
