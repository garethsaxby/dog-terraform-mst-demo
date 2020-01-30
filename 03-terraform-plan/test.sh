#!/usr/bin/env bash

echo 'Running: terraform init'
terraform init

echo "Running: terraform plan"
terraform plan
