#This script searches for the previous version of the CSV in the CSV manifests and replaces it with the latest
#version as determined by the pipeline.
new_version=$1
if [[ -z "$new_version" ]]; then
  new_version=$VERSION
fi
if [[ -z "$new_version" ]]; then
  new_version=$(cat ./VERSION)
fi
new_version=${new_version,,}
old_version=$(cat manifests/k8s-116-and-later/community-deployment/entando-k8s-operator.v6.3.x.clusterserviceversion.yaml | grep "name: entando-k8s-operator.v" | sed 's/.*v\(.*\)/\1/')
sed -i "s/$old_version/$new_version/g" manifests/k8s-116-and-later/community-deployment/entando-k8s-operator.v6.3.x.clusterserviceversion.yaml
#old_version=${operator_name}
#export major_minor=${old_version%.*}
#echo $major_minor
#export build=${old_version#*"${major_minor}."}
#echo $((build + 1))
