#!/bin/bash

truncate --size 0 ../manifests/big-mesh-manifest.yaml

declare -A services
services=(
    ["user"]="order,payment"
    ["order"]="inventory,shipping"
    ["payment"]="invoice,fraud"
    ["inventory"]="warehouse,supplier"
    ["shipping"]="courier,tracking"
    ["invoice"]=""
    ["fraud"]=""
    ["warehouse"]=""
    ["supplier"]=""
    ["courier"]=""
    ["tracking"]="location"
    ["location"]=""
    ["customer"]="support,loyalty"
    ["support"]=""
    ["loyalty"]=""
)

for service in "${!services[@]}"; do
    ./reflection.sh "$service" "${services[$service]}" "carlosflor25/reflection:v3" "mesh-example" "big-mesh-manifest.yaml"
done
