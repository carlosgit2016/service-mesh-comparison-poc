#!/bin/bash

set -x

SERVICE_NAME="$1"
DOWNSTREAM_SERVICES="$2"
IMAGE="$3"
NAMESPACE="$4"
MANIFEST="$5"

kubectl create deployment "$SERVICE_NAME" "-n$NAMESPACE" \
    --image="$IMAGE" \
    --port=80 \
    --replicas=1

kubectl wait --for=condition=Available "-n$NAMESPACE" --timeout=1s deploy "$SERVICE_NAME"

kubectl patch deployment "$SERVICE_NAME" "-n$NAMESPACE" --type='json' -p="[
  {
    \"op\": \"add\",
    \"path\": \"/spec/template/spec/containers/0/env\",
    \"value\": [
      {
        \"name\": \"HTTP_CODE\",
        \"value\": \"200\"
      },
      {
        \"name\": \"METADATA_NAME\",
        \"valueFrom\": {
          \"fieldRef\": {
            \"fieldPath\": \"metadata.name\"
          }
        }
      },
      {
        \"name\": \"METADATA_NAMESPACE\",
        \"valueFrom\": {
          \"fieldRef\": {
            \"fieldPath\": \"metadata.namespace\"
          }
        }
      },
      {
        \"name\": \"NODE_NAME\",
        \"valueFrom\": {
          \"fieldRef\": {
            \"fieldPath\": \"spec.nodeName\"
          }
        }
      },
      {
        \"name\": \"SERVICE_ACCOUNT\",
        \"valueFrom\": {
          \"fieldRef\": {
            \"fieldPath\": \"spec.serviceAccountName\"
          }
        }
      },
      {
        \"name\": \"HOST_IP\",
        \"valueFrom\": {
          \"fieldRef\": {
            \"fieldPath\": \"status.hostIP\"
          }
        }
      },
      {
        \"name\": \"POD_IP\",
        \"valueFrom\": {
          \"fieldRef\": {
            \"fieldPath\": \"status.podIP\"
          }
        }
      },
      {
        \"name\": \"DOWNSTREAM_SERVICES\",
        \"value\": \"$DOWNSTREAM_SERVICES\"
      }
    ]
  }
]"

# kubectl patch deployment "$SERVICE_NAME" "-n$NAMESPACE" --type='json' -p='[
#   {
#     "op": "add", "path": "/spec/template/spec/tolerations", "value": [{
#       "key": "kubernetes.azure.com/scalesetpriority",
#       "operator": "Equal",
#       "value": "spot",
#       "effect": "NoSchedule"
#     }]
#   },
#   {
#     "op": "add", "path": "/spec/template/spec/affinity", "value": {
#       "nodeAffinity": {
#         "requiredDuringSchedulingIgnoredDuringExecution": {
#           "nodeSelectorTerms": [{
#             "matchExpressions": [{
#               "key": "agentpool",
#               "operator": "NotIn",
#               "values": ["default"]
#             }]
#           }]
#         }
#       }
#     }
#   }
# ]'

{
  echo "---"
  kubectl create service clusterip "-n$NAMESPACE" "$SERVICE_NAME" --tcp 8080:80  -oyaml --dry-run=client
  echo "---"
  kubectl get "-n$NAMESPACE" "deploy/$SERVICE_NAME" -oyaml 
  echo "..."
} >> "../manifests/$MANIFEST" 

kubectl delete "-n$NAMESPACE" "deploy/$SERVICE_NAME"
kubectl wait --for=delete "deploy/$SERVICE_NAME" "-n$NAMESPACE" --timeout=60s
