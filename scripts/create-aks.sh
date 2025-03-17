#!/bin/bash

# ref: https://learn.microsoft.com/en-us/azure/aks/gpu-cluster?tabs=add-ubuntu-gpu-node-pool

# aks cluster should be created with defaults

RG_NAME=k8s-distributed-inference
AKS_NAME=distributed-inference
LOCATION=southeastasia
CPU_NP_NAME=cpunp
GPU_NP_NAME=gpunp

set -o pipefail

# az group create --name $RG_NAME --location $LOCATION

# az aks create \
#     --resource-group $RG_NAME --name $AKS_NAME --node-count 1 \
#     --node-vm-size Standard_D8ds_v5 \
#     --zones 2 3 \
#     --generate-ssh-keys

# # add a node pool for cpu
# az aks nodepool add --resource-group $RG_NAME \
#     --cluster-name $AKS_NAME \
#     --name $CPU_NP_NAME \
#     --node-count 1 \
#     --node-vm-size Standard_D16s_v4 \
#     --enable-cluster-autoscaler \
#     --min-count 0 \
#     --max-count 2

# # add a gpu node pool for standard_nc24ads_a100_v4
# az aks nodepool add \
#     --resource-group $RG_NAME \
#     --cluster-name $AKS_NAME \
#     --name $GPU_NP_NAME \
#     --node-count 1 \
#     --node-vm-size standard_nc24ads_a100_v4 \
#     --node-taints sku=gpu:NoSchedule \
#     --enable-cluster-autoscaler \
#     --min-count 0 \
#     --max-count 2

# get credentials
az aks get-credentials --resource-group $RG_NAME --name $AKS_NAME

# install gpu operator
kubectl create ns gpu-operator
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia &&
    helm repo update
helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator \
    --version=v24.9.2

# # install nvidia device plugin
# kubectl create namespace gpu-operator
# kubectl apply -f - <<EOF
# apiVersion: apps/v1
# kind: DaemonSet
# metadata:
#   name: nvidia-device-plugin-daemonset
#   namespace: kube-system
# spec:
#   selector:
#     matchLabels:
#       name: nvidia-device-plugin-ds
#   updateStrategy:
#     type: RollingUpdate
#   template:
#     metadata:
#       labels:
#         name: nvidia-device-plugin-ds
#     spec:
#       tolerations:
#       - key: "sku"
#         operator: "Equal"
#         value: "gpu"
#         effect: "NoSchedule"
#       # Mark this pod as a critical add-on; when enabled, the critical add-on
#       # scheduler reserves resources for critical add-on pods so that they can
#       # be rescheduled after a failure.
#       # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
#       priorityClassName: "system-node-critical"
#       containers:
#       - image: nvcr.io/nvidia/k8s-device-plugin:v0.15.0
#         name: nvidia-device-plugin-ctr
#         env:
#           - name: FAIL_ON_INIT_ERROR
#             value: "false"
#         securityContext:
#           allowPrivilegeEscalation: false
#           capabilities:
#             drop: ["ALL"]
#         volumeMounts:
#         - name: device-plugin
#           mountPath: /var/lib/kubelet/device-plugins
#       volumes:
#       - name: device-plugin
#         hostPath:
#           path: /var/lib/kubelet/device-plugins
# EOF
