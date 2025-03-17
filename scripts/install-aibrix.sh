#!/bin/bash

# ref: https://aibrix.readthedocs.io/latest/getting_started/installation/installation.html

RG_NAME=k8s-distributed-inference
AKS_NAME=distributed-inference
LOCATION=southeastasia
CPU_NP_NAME=cpunp
GPU_NP_NAME=gpunp

# get directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

set -o pipefail

# get credentials
az aks get-credentials --resource-group $RG_NAME --name $AKS_NAME

# Install component dependencies
kubectl create -f $DIR/aibrix/aibrix-dependency-v0.2.1.yaml

# Install aibrix components
kubectl create -f $DIR/aibrix/aibrix-core-v0.2.1.yaml

# Install component dependencies
kubectl create -k $DIR/aibrix/config/dependency
kubectl create -k $DIR/aibrix/config/default

# create base model
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    model.aibrix.ai/name: deepseek-r1-distill-llama-8b
    model.aibrix.ai/port: "8000"
  name: deepseek-r1-distill-llama-8b
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      model.aibrix.ai/name: deepseek-r1-distill-llama-8b
  template:
    metadata:
      labels:
        model.aibrix.ai/name: deepseek-r1-distill-llama-8b
    spec:
      tolerations:
        - key: "sku"
          operator: "Equal"
          value: "gpu"
          effect: "NoSchedule"
      containers:
        - command:
            - python3
            - -m
            - vllm.entrypoints.openai.api_server
            - --host
            - "0.0.0.0"
            - --port
            - "8000"
            - --uvicorn-log-level
            - warning
            - --model
            - deepseek-ai/DeepSeek-R1-Distill-Llama-8B
            - --served-model-name
            - deepseek-r1-distill-llama-8b
            - --max-model-len
            - "12288"
          image: vllm/vllm-openai:v0.7.1
          imagePullPolicy: IfNotPresent
          name: vllm-openai
          ports:
            - containerPort: 8000
              protocol: TCP
          resources:
            limits:
              nvidia.com/gpu: "1"
            requests:
              nvidia.com/gpu: "1"
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
              scheme: HTTP
            failureThreshold: 3
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
              scheme: HTTP
            failureThreshold: 5
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          startupProbe:
            httpGet:
              path: /health
              port: 8000
              scheme: HTTP
            failureThreshold: 30
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
---
apiVersion: v1
kind: Service
metadata:
  labels:
    model.aibrix.ai/name: deepseek-r1-distill-llama-8b
    prometheus-discovery: "true"
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
  name: deepseek-r1-distill-llama-8b
  namespace: default
spec:
  ports:
    - name: serve
      port: 8000
      protocol: TCP
      targetPort: 8000
    - name: http
      port: 8080
      protocol: TCP
      targetPort: 8080
  selector:
    model.aibrix.ai/name: deepseek-r1-distill-llama-8b
  type: ClusterIP
EOF


# try it out 
kubectl port-forward svc/deepseek-r1-distill-llama-8b 8000:8000
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
        "model": "deepseek-r1-distill-llama-8b",
        "prompt": "here is a beautiful poem about a strawberry called mr red: there once was a strawberry, his name was mr red.",
        "max_tokens": 700,
        "temperature": 0
      }'