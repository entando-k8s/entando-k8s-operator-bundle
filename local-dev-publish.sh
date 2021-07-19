#!/usr/bin/env bash
export MY_VERSION=$(yq eval '.spec.version' manifests/k8s-116-and-later/olm-deployment/entando-k8s-operator.v6.3.x.clusterserviceversion.yaml)
echo $MY_VERSION
export PREVIOUS_VERSIONS=("6.4.0-pr1-32" "6.4.0-pr1-33" "6.4.0-pr1-34")
for V in ${PREVIOUS_VERSIONS[@]}; do
  BUNDLES="${BUNDLES}docker.io/entandobuilduser/entando-k8s-operator-bundle:${V},"
done
BUNDLES="${BUNDLES}docker.io/entandobuilduser/entando-k8s-operator-bundle:${MY_VERSION}"
echo $BUNDLES
docker build . -f Dockerfile.internal -t entandobuilduser/entando-k8s-operator-bundle:${MY_VERSION} \
      && docker push entandobuilduser/entando-k8s-operator-bundle:${MY_VERSION} \
      && operator-sdk bundle validate docker.io/entandobuilduser/entando-k8s-operator-bundle:${MY_VERSION} \
      && opm index add --bundles "${BUNDLES}" --tag docker.io/entandobuilduser/entando-k8s-index:latest \
      && podman push docker.io/entandobuilduser/entando-k8s-index:latest