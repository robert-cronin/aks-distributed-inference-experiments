#!/bin/bash

helm upgrade --install --create-namespace \
    --namespace=ns-vllm test-vllm . \
    -f values.yaml \
    --set secrets.s3endpoint=$ACCESS_POINT \
    --set secrets.s3bucketname=$BUCKET \
    --set secrets.s3accesskeyid=$ACCESS_KEY \
    --set secrets.s3accesskey=$SECRET_KEY
