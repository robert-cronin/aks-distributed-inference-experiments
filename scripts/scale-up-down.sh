#!/bin/bash

RG_NAME=k8s-distributed-inference
AKS_NAME=distributed-inference
NP_NAME=gpunp
NODE_COUNT=0

az aks nodepool scale \
    --resource-group "$RG_NAME" \
    --cluster-name "$AKS_NAME" \
    --name "$NP_NAME" \
    --node-count $NODE_COUNT
