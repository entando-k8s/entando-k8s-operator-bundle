export RELEASE_VERSION=6.3.1
docker build . -f Dockerfile.rh-cert -t entando/entando-k8s-operator-bundle:${RELEASE_VERSION} \
      && docker push entando/entando-k8s-operator-bundle:${RELEASE_VERSION} \
      && operator-sdk bundle validate docker.io/entando/entando-k8s-operator-bundle:${RELEASE_VERSION}