#!/usr/bin/env bash

set -euo pipefail

namespace="3scale"

if ! oc get namespace "$namespace" &>/dev/null; then
    echo "Creating namespace $namespace..."
    oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: "$namespace"
  labels:
    argocd.argoproj.io/managed-by: openshift-gitops
EOF
fi

# Extract existing cluster pull secret
PULL_SECRET=$(oc extract secret/pull-secret -n openshift-config --keys=.dockerconfigjson --to=- | base64 -w 0)

# Create secret using HEREDOC
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: threescale-registry-auth
  namespace: ${namespace}
  annotations:
    argocd.argoproj.io/sync-options: "Prune=false"
    argocd.argoproj.io/compare-options: "IgnoreExtraneous"
  labels:
    rhoai-example: maas
    rhoai-example-component: ${namespace}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${PULL_SECRET}
EOF

echo "Secret created successfully"
