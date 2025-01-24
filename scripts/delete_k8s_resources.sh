#!/bin/bash

NAMESPACE="${1:-default}"
RESOURCES_DIR="$2"

if [ -z "$RESOURCES_DIR" ]; then
    echo "Usage: $0 <namespace> <resources_directory>"
    exit 1
fi

# Delete non-PVC resources first
for dir in "$RESOURCES_DIR"/*/ ; do
    resource_type=$(basename "$dir")
    [ ! -d "$dir" ] && continue
    
    # Skip PVCs for now
    if [ "$resource_type" = "persistentvolumeclaims" ]; then
        continue
    fi
    
    for resource_file in "$dir"/*.yaml; do
        [ ! -f "$resource_file" ] && continue
        
        resource_name=$(basename "$resource_file" .yaml)
        
        # Skip protected resources
        if [ "$resource_type" = "serviceaccounts" ] && [ "$resource_name" = "default" ] || \
           [ "$resource_type" = "configmaps" ] && [ "$resource_name" = "kube-root-ca_crt" ] || \
           [ "$resource_type" = "secrets" ] || \
           [ "$resource_type" = "persistentvolumes" ]; then
            echo "Skipping protected resource: $resource_type/$resource_name"
            continue
        fi
        
        kind=$(grep "^kind:" "$resource_file" | awk '{print $2}')
        name=$(grep "^  name:" "$resource_file" | awk '{print $2}')
        
        if [ "$kind" = "Application" ]; then
            echo "Deleting $kind: $name in namespace argocd"
            kubectl delete -f "$resource_file" -n argocd --force --grace-period=0
        else
            echo "Deleting $kind: $name in namespace $NAMESPACE"
            kubectl delete -f "$resource_file" -n "$NAMESPACE" --force --grace-period=0
        fi
    done
done

# Delete PVCs last
pvc_dir="$RESOURCES_DIR/persistentvolumeclaims"
if [ -d "$pvc_dir" ]; then
    for pvc_file in "$pvc_dir"/*.yaml; do
        [ ! -f "$pvc_file" ] && continue
        name=$(grep "^  name:" "$pvc_file" | awk '{print $2}')
        echo "Deleting PVC: $name in namespace $NAMESPACE"
        kubectl delete -f "$pvc_file" -n "$NAMESPACE" --force --grace-period=0
    done
fi