#!/bin/bash

# should create a cluster first: ../raycluster/raycluster.yaml

# ref: https://docs.ray.io/en/latest/cluster/kubernetes/getting-started/raycluster-quick-start.html#method-2-submit-a-ray-job-to-the-raycluster-using-ray-job-submission-sdk

ray job submit --address http://localhost:8265 -- python -c "import ray; ray.init(); print(ray.cluster_resources())"
