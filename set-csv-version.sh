old_version=$(cat manifests/entando-k8s-operator.v0.3.x.clusterserviceversion.yaml | grep "name: entando-k8s-operator.v" | sed 's/.*v\(.*\)/\1/')
sed -i "s/$old_version/$VERSION/g" manifests/entando-k8s-operator.v0.3.x.clusterserviceversion.yaml
#old_version=${operator_name}
#export major_minor=${old_version%.*}
#echo $major_minor
#export build=${old_version#*"${major_minor}."}
#echo $((build + 1))
