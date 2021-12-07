#!/usr/bin/env bash

version="$1"
oc get configmap -o yaml -n entando "entando-docker-image-info-v${1}" > versions.yaml
rm valuesRelatedImages.yaml
IFS=$'\n'
rows=($(yq eval '.data' versions.yaml))
for row in "${rows[@]}"; do
  key=${row%: *}
  value=${row#*: }
  #strip single quotes
  value="$(eval echo $value)"
  echo "$value" > image-info.yaml
  version=$(yq eval  ".version" image-info.yaml)
  echo "processing $key"
  if  [[ $key =~ ^entando-k8s-.* ]]; then
    skopeo_result=$(skopeo inspect "docker://docker.io/entando/${key}:${version}" )
    name=$(echo $skopeo_result | jq '.Name')
    name=$(eval echo $name)
    digest=$(echo $skopeo_result | jq '.Digest')
    digest=$(eval echo $digest)
    env_var=$(echo ${key^^} | tr '-' '_')
    echo "    ${env_var,,}:" >> valuesRelatedImages.yaml
    echo "      sha256: ${digest#*:}" >> valuesRelatedImages.yaml
    echo "      version: ${version}" >> valuesRelatedImages.yaml
  fi
done