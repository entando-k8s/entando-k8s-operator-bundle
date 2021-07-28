#!/usr/bin/env bash
#This scripts take the currently used version of the entando-k8s-controller-coordinator and generates the
# four typical deployment profiles for the operator:
# 1. K8S 1.16 and later
# 1.1. Namespace scoped deployment
# 1.2. Cluster scoped deployment
# 2. K8S before 1.16 (Openshift 3.11)
# 2.1. Namespace scoped deployment
# 2.2. Cluster scoped deployment
#This script should ideally be executed when releasing the Entando Operator so that we can ensure that
#all the different deployments and quickstarts using the Operator use exactly the same combination of image versions

function writeClusterResourceToFile {
  for f in ./manifests/$1/cluster-resources/*.yaml ; do
    cat $f >> $2
    echo -e "\n---" >> $2
  done
}
function writeAllResourcesForVersion {
  local k8s_version=$1
  local output_dir=./manifests/${k8s_version}/namespace-scoped-deployment
  rm $output_dir/*.yaml 2>/dev/null
  if [ $k8s_version == "k8s-before-116" ]; then
    support_openshift_311="true"
  else
    support_openshift_311="false"
  fi
  writeClusterResourceToFile ${k8s_version} ${output_dir}/cluster-resources.yaml
  helm template --name=entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=false,bundle.olmDisabled=true ./  >> ${output_dir}/namespace-resources.yaml
  writeClusterResourceToFile ${k8s_version} ${output_dir}/all-in-one.yaml
  helm template --name=entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=false,bundle.olmDisabled=true ./  >> ${output_dir}/all-in-one.yaml
  output_dir=./manifests/${k8s_version}/cluster-scoped-deployment
  rm $output_dir/*.yaml 2>/dev/null
  writeClusterResourceToFile ${k8s_version} ${output_dir}/all-in-one.yaml
  helm template --name=entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=true,bundle.olmDisabled=true ./  >> ${output_dir}/all-in-one.yaml
}

writeAllResourcesForVersion k8s-116-and-later
writeAllResourcesForVersion k8s-before-116
rm out -rf 2>/dev/null
mkdir out
helm template --set bundle.containerRegistry=docker.io,bundle.communityOnly=true,bundle.olmDisabled=false ./ --output-dir=out
mv ./out/entando-k8s-operator-bundle/templates/*.yaml ./manifests/k8s-116-and-later/community-deployment/ -f
helm template --set bundle.containerRegistry=registry.connect.redhat.com,bundle.communityOnly=false,bundle.olmDisabled=false ./ --output-dir=out
mv ./out/entando-k8s-operator-bundle/templates/*.yaml ./manifests/k8s-116-and-later/rh-cert-deployment/ -f
