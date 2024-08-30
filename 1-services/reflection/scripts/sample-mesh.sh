#!/bin/bash

truncate --size 0 ../manifests/sample-mesh-manifest.yaml 

./reflection.sh "alpha" "beta,gamma" "carlosflor25/reflection:v2" "default" "sample-mesh-manifest.yaml"
./reflection.sh "beta" "" "carlosflor25/reflection:v2"  "default" "sample-mesh-manifest.yaml"
./reflection.sh "gamma" "delta" "carlosflor25/reflection:v2"  "default" "sample-mesh-manifest.yaml"
./reflection.sh "delta" "" "carlosflor25/reflection:v2"  "default" "sample-mesh-manifest.yaml"
