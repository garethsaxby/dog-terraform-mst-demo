#!/usr/bin/env bash

echo 'Running: terraform init -backend=false'
terraform init -backend=false
echo ''

echo 'Running: terraform validate'
terraform validate
