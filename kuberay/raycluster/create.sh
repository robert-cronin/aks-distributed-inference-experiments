#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# kubectl apply -f $DIR/raycluster.yaml

# echo "Waiting for the Ray cluster to be ready..."
# kubectl wait --for=condition=ready pod -l ray.io/cluster=core-raycluster --timeout=300s

echo "Forwarding the Ray dashboard..."
echo "http://localhost:8265"
# dont forget to forward grafana!
kubectl port-forward svc/core-raycluster-head-svc 8265:8265 &
# forward grafana
kubectl port-forward -n prometheus-system  svc/prometheus-grafana 3000:80 &
wait