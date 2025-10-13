#!/usr/bin/env bash

# ApplicationSet
echo "Deleting ApplicationSet..."
oc delete appset models-as-a-service-3scale-helm  -n openshift-gitops --wait=false &> /dev/null
oc delete appset models-as-a-service-3scale-kustomize -n openshift-gitops --wait=false &> /dev/null

echo "Deleting Applications..."
oc delete -n openshift-gitops apps 3scale cms-upload minio model-serving models-as-a-service-3scale-maas-bootstrap --wait=false &> /dev/null

echo "Deleting AppProject..."
oc delete appproject models-as-a-service-3scale -n openshift-gitops --wait=false &> /dev/null

# 3scale
echo "Deleting 3scale resources..."
if oc get namespace 3scale &>/dev/null; then
    # Define resources that require both patching and deleting
    patch_and_delete_resources=(
        applicationauth
        application.capabilities.3scale.net
        developeraccount
        developeruser
        activedoc
        proxyconfigpromote
        product
        backend
        apimanager
        custompolicydefinition
        subscription
	    pipeline
        pipelinerun
        taskrun
        tasks
        eventlistener
        pod
        job
        route
        service
        # rolebindings
        # serviceaccount
        # secret
        # configmap
    )

    for item in "${patch_and_delete_resources[@]}"; do
        echo "Removing finalizers from '$item' instances and deleting them..."
        oc get "$item" -n 3scale -o name | xargs oc patch -p '{"metadata":{"finalizers":[]}}' -n 3scale --type=merge
        oc get "$item" -n 3scale -o name | xargs oc delete -n 3scale
    done

    oc wait --for=delete apimanager/apimanager --timeout=60s
    oc delete namespace 3scale || true
fi

# # Keycloak
# echo "Deleting Keycloak resources..."
# if oc get namespace redhat-sso &>/dev/null; then
#     oc get keycloak -n redhat-sso -o name | xargs oc delete -n redhat-sso --wait=false
#     oc get statefulset -n redhat-sso -o name | xargs oc delete -n redhat-sso --wait=false
#     oc get subscription -n redhat-sso -o name | xargs oc delete -n redhat-sso
#     oc delete namespace redhat-sso || true
# fi

# Minio
echo "Deleting Minio resources..."
if oc get namespace minio &>/dev/null; then
    oc get deployment -n minio -o name | xargs oc delete -n minio --wait=false
    oc delete namespace minio || true
fi

# LLM
echo "Deleting LLM resources..."
if oc get namespace llm-hosting &>/dev/null; then
    oc get servingruntime -n llm-hosting -o name | xargs oc delete -n llm-hosting --wait=false
    oc get inferenceservice -n llm-hosting -o name | xargs oc delete -n llm-hosting --wait=false
    oc delete namespace llm-hosting || true
fi

# Helm release information
echo "Deleting Helm release information..."
oc get secret -n openshift-gitops -l name=models-as-a-service-3scale -l owner=helm -o name | xargs oc delete -n openshift-gitops || true
