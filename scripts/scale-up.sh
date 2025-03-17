#!/bin/bash

RG_NAME=k8s-distributed-inference
AKS_NAME=distributed-inference
NP_NAME=gpunp

az aks nodepool scale \
    --resource-group "$RG_NAME" \
    --cluster-name "$AKS_NAME" \
    --name "$NP_NAME" \
    --node-count 0
