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
    model.aibrix.ai/name: deepseek-r1-distill-llama-8b # Note: The label value model.aibrix.ai/name here must match with the service name.
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
            # Note: The --served-model-name argument value must also match the Service name and the Deployment label model.aibrix.ai/name
            - deepseek-r1-distill-llama-8b
            - --max-model-len
            - "12288" # 24k length, this is to avoid "The model's max seq len (131072) is larger than the maximum number of tokens that can be stored in KV cache" issue.
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
  name: deepseek-r1-distill-llama-8b # Note: The Service name must match the label value $(model.aibrix.ai/name) in the Deployment
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
