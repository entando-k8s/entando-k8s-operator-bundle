set -e
export RELEASE_VERSION=$(yq eval '.spec.version' manifests/k8s-116-and-later/rh-cert-deployment/entando-k8s-operator.v6.3.x.clusterserviceversion.yaml)
docker build . -f Dockerfile.rh-cert -t entando/entando-k8s-operator-bundle:${RELEASE_VERSION}
docker push entando/entando-k8s-operator-bundle:${RELEASE_VERSION}
operator-sdk bundle validate docker.io/entando/entando-k8s-operator-bundle:${RELEASE_VERSION}
docker tag entando/entando-k8s-operator-bundle:${RELEASE_VERSION} scan.connect.redhat.com/ospid-dc63077a-911b-4318-a3e3-4bea601d8e45/entando-k8s-operator-bundle:${RELEASE_VERSION}
docker push  scan.connect.redhat.com/ospid-dc63077a-911b-4318-a3e3-4bea601d8e45/entando-k8s-operator-bundle:${RELEASE_VERSION}
