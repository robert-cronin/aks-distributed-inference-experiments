#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

helm repo add kuberay https://ray-project.github.io/kuberay-helm/

helm upgrade --install kuberay-operator kuberay/kuberay-operator --version 1.3.0

# # amd64
# helm install raycluster kuberay/ray-cluster --version 1.3.0

# # make sure its running
# export HEAD_POD=$(kubectl get pods --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers)
# echo $HEAD_POD
# kubectl exec -it $HEAD_POD -- python -c "import ray; ray.init(); print(ray.cluster_resources())"

# ======================== Ray Job ========================
# create the config map first from DIR/rayjob/sample_code.py, give the file a name of sample_code.py
kubectl create configmap ray-job-code-sample --from-file=sample_code.py=$DIR/rayjob/sample_code.py --dry-run=client -o yaml | kubectl apply -f -

# create the job
kubectl apply -f $DIR/rayjob/rayjob.yaml

# ======================== Ray Service ========================
# create the service
kubectl apply -f $DIR/rayservice/rayservice.yaml
