#!/bin/bash

# ref: https://docs.ray.io/en/latest/cluster/kubernetes/getting-started/rayservice-quick-start.html

# # Step 6.1: Run a curl Pod.
# # If you already have a curl Pod, you can use `kubectl exec -it <curl-pod> -- sh` to access the Pod.
# kubectl run curl --image=radial/busyboxplus:curl -i --tty

# # Step 6.2: Send a request to the fruit stand app.
# curl -X POST -H 'Content-Type: application/json' rayservice-sample-serve-svc:8000/fruit/ -d '["MANGO", 2]'
# # [Expected output]: 6

# # Step 6.3: Send a request to the calculator app.
# curl -X POST -H 'Content-Type: application/json' rayservice-sample-serve-svc:8000/calc/ -d '["MUL", 3]'
# # [Expected output]: "15 pizzas please!"

echo "Forwarding the Ray dashboard..."
echo "http://localhost:8265"
# dont forget to forward grafana!
kubectl port-forward svc/core-raycluster-head-svc 8265:8265 &
# forward grafana
kubectl port-forward -n prometheus-system  svc/prometheus-grafana 3000:80 &
wait

kubectl run curl --image=radial/busyboxplus:curl --restart=Never --rm -it -- sh -c '
  while true; do
    echo "Sending request to fruit stand app...";
    curl -X POST -H "Content-Type: application/json" rayservice-sample-serve-svc:8000/fruit/ -d "[\"MANGO\", 2]";
    echo "";
    echo "Sending request to calculator app...";
    curl -X POST -H "Content-Type: application/json" rayservice-sample-serve-svc:8000/calc/ -d "[\"MUL\", 3]";
    echo "";
    echo "Requests completed. Sleeping for 1 second...";
    sleep 1;
  done
'
