#!/bin/bash

set -e

NAMESPACE="${1:-default}"
OUTPUT_DIR="k8s_resources_${NAMESPACE}_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$OUTPUT_DIR/extraction.log"
ERROR_LOG="$OUTPUT_DIR/errors.log"

RESOURCE_TYPES=(
    "deployments"
    "services"
    "configmaps"
    "secrets"
    "ingresses"
    "statefulsets"
    "daemonsets"
    "persistentvolumeclaims"
    "networkpolicies"
    "serviceaccounts"
    "roles"
    "rolebindings"
    "cronjobs"
    "jobs"
    "secretproviderclasses.secrets-store.csi.x-k8s.io"
)

mkdir -p "$OUTPUT_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$ERROR_LOG"
}

sanitize_name() {
    echo "$1" | sed 's/[^a-zA-Z0-9-]/_/g'
}

extract_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local output_file="$3"
    local ns="${4:-$NAMESPACE}"

    # Skip helm release secrets and kube-root-ca.crt configmap
    if [[ "$resource_type" == "secrets" && "$resource_name" == sh.helm.release* ]] || \
       [[ "$resource_type" == "configmaps" && "$resource_name" == "kube-root-ca.crt" ]]; then
        echo "Skipping protected resource: $resource_type/$resource_name"
        return 0
    fi

    if ! kubectl get "$resource_type" "$resource_name" -n "$ns" -o yaml > "$output_file.tmp" 2>> "$ERROR_LOG"; then
        error_log "Failed to extract $resource_type/$resource_name"
        return 1
    fi
    
    if [[ "$resource_type" == "secrets" ]]; then
        # For secrets, obfuscate the data values but keep the keys
        awk '
        BEGIN { in_data = 0 }
        /^data:/ { in_data = 1; print; next }
        /^[^ ]/ { in_data = 0 }  # Reset when indent level returns to 0
        in_data && /:[[:space:]]+/ { 
            # Print key but replace value with [REDACTED]
            sub(/:[[:space:]]+.*$/, ": [REDACTED]")
            print
            next
        }
        { print }
        ' "$output_file.tmp" | grep -v "^\s*\(creationTimestamp\|resourceVersion\|uid\|generation\|status\):" > "$output_file"
    else
        grep -v "^\s*\(creationTimestamp\|resourceVersion\|uid\|generation\|status\):" "$output_file.tmp" > "$output_file"
    fi
    
    rm "$output_file.tmp"
    return 0
}

extract_related_pvs() {
    local pvc_dir="$OUTPUT_DIR/persistentvolumeclaims"
    local pv_dir="$OUTPUT_DIR/persistentvolumes"
    mkdir -p "$pv_dir"

    if [ ! -d "$pvc_dir" ]; then
        return
    fi

    for pvc_file in "$pvc_dir"/*.yaml; do
        [ -f "$pvc_file" ] || continue
        
        local pv_name=$(grep "volumeName:" "$pvc_file" | awk '{print $2}')
        if [ -n "$pv_name" ]; then
            log "Extracting related PV: $pv_name"
            extract_resource "persistentvolumes" "$pv_name" "$pv_dir/${pv_name}.yaml"
        fi
    done
}



log "Saving cluster information..."
kubectl config view --minify -o yaml > "$OUTPUT_DIR/cluster_context.yaml" 2>> "$ERROR_LOG"
kubectl cluster-info > "$OUTPUT_DIR/cluster_info.txt" 2>> "$ERROR_LOG"

{
    echo "Namespace: $NAMESPACE"
    echo "Extraction Date: $(date)"
    kubectl version
    echo "Current Context: $(kubectl config current-context)"
    echo "Current User: $(kubectl config view --minify -o jsonpath='{.users[].name}')"
} > "$OUTPUT_DIR/metadata.txt" 2>> "$ERROR_LOG"

for resource_type in "${RESOURCE_TYPES[@]}"; do
    log "Processing $resource_type..."
    type_dir="$OUTPUT_DIR/$resource_type"
    mkdir -p "$type_dir"
    
    if ! kubectl auth can-i get "$resource_type" -n "$NAMESPACE" > /dev/null 2>&1; then
        error_log "No permission to access $resource_type in namespace $NAMESPACE"
        continue
    fi
    
    resources=$(kubectl get "$resource_type" -n "$NAMESPACE" -o name 2>> "$ERROR_LOG")
    if [ $? -ne 0 ]; then
        error_log "Failed to list $resource_type"
        continue
    fi
    
    if [ -z "$resources" ]; then
        log "No $resource_type found"
        continue
    fi
    
    while IFS= read -r resource; do
        resource_name=$(echo "$resource" | cut -d'/' -f2)
        if [ -n "$resource_name" ]; then
            sanitized_name=$(sanitize_name "$resource_name")
            output_file="$type_dir/${sanitized_name}.yaml"
            log "Extracting $resource_type/$resource_name"
            extract_resource "$resource_type" "$resource_name" "$output_file"
        fi
    done <<< "$resources"
done

extract_related_pvs

log "Creating combined configuration..."
> "$OUTPUT_DIR/combined_config.yaml"

# Create a temporary directory for sorted files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Copy and rename files with resource type prefix for sorting
for dir in "$OUTPUT_DIR"/*/ ; do
    if [[ "$dir" != *"combined_config"* ]]; then
        resource_type=$(basename "$dir")
        for file in "$dir"/*.yaml; do
            if [ -f "$file" ]; then
                resource_name=$(basename "$file" .yaml)
                cp "$file" "$TEMP_DIR/${resource_type}___${resource_name}.yaml"
            fi
        done
    fi
done

# Combine sorted files with separators
first_file=true
for file in $(ls "$TEMP_DIR"/*.yaml | sort); do
    if [ "$first_file" = true ]; then
        first_file=false
    else
        echo "---" >> "$OUTPUT_DIR/combined_config.yaml"
    fi
    cat "$file" >> "$OUTPUT_DIR/combined_config.yaml"
done

# Verify contents
log "Resources in combined config:"
grep "kind:" "$OUTPUT_DIR/combined_config.yaml" | sort | uniq -c

log "Generating checksums..."
find "$OUTPUT_DIR" -type f -exec sha256sum {} \; > "$OUTPUT_DIR/checksums.txt"

if [ -s "$ERROR_LOG" ]; then
    echo "Completed with errors. Check $ERROR_LOG for details"
else
    echo "Extraction completed successfully"
fi

echo "Output directory: $OUTPUT_DIR"