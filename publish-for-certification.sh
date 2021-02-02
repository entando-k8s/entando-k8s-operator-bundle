export MY_VERSION=0.3.34
docker build . -t entando/entando-k8s-operator-bundle:${MY_VERSION} \
      && docker push entando/entando-k8s-operator-bundle:${MY_VERSION} \
      && operator-sdk bundle validate docker.io/entando/entando-k8s-operator-bundle:${MY_VERSION}