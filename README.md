# entando-k8s-operator-bundle

This project defines the Operator Lifecycle Manager compliant bundle image that is used to publish a single
version of the Entando Operator.

# Installing this operator
1. Create an Operator CatalogSource in your Openshift environment by deploying the following yaml:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: entando-catalog
  namespace: openshift-marketplace
spec:
  displayName: Entando Catalog
  image: docker.io/ampie/entando-k8s-index:latest
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 2m
```

2. Confirm that a Pod starting with the phrase 'entando-catalog' is running in the `openshift-marketplace` Namespace:
```
watch oc get pods -n openshift-marketplace
```

3. When the new catalog Pod is ready, go to your Openshift web console's Operator Hub and search for the keyword 'Entando'. 
The latest available version should be 0.3.24. Click on the 'Install' button. Use the default 'openshift-operators' namespace
   
4. Confirm that the Entando Operator pod is up and running:
```
watch oc get pods -n openshift-operators
```

5. Once the Entando Operator pod is up and running, navigate to the Operator in your Openshift web console, create
   an EntandoKeycloakServer custom resource using the defaults. 


