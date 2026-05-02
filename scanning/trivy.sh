#!/usr/bin/env bash

echo "Running Trivy cluster scan..."

trivy k8s kind-dev-cluster \
  --report summary \
  --severity HIGH,CRITICAL \
  --timeout 10m
