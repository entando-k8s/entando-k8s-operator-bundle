#!/bin/bash

. .ent/enp-prereq.sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_log_i "Running publication"

docker login registry.hub.docker.com \
  --username "$ENTANDO_OPT_DOCKER_USERNAME" \
  --password-stdin <<< "$ENTANDO_OPT_DOCKER_PASSWORD"

OPM_CONTAINER_TOOL=docker ./local-dev-publish.sh
echo "~~~"
cat ./tmp/catalog-source.yaml
