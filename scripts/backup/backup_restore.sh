#!/bin/bash

# Default namespace and values
default_namespace="dotcms-dev"
default_backup_path="/private/tmp" # Updated default backup path
default_filename="backup"
timestamp=$(date +%Y%m%d-%H%M%S)

# Services
dotcms_service="dotcms-cluster"
opensearch_service="opensearch"
db_service="db"

# Get the directory of the script
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Path to the Helm chart
chart_path="$script_dir/../../charts/backup"

# Function to show usage
show_usage() {
  echo "Usage: $0 --operation <backup|restore|cleanup> [--hostpath <path>] [--filename <name>] [--namespace <namespace>] [--help]"
  echo "  --operation   : Operation to perform ('backup', 'restore', 'cleanup')."
  echo "  --hostpath    : Path to the directory for backup/restore files (required for 'restore', default for 'backup': $default_backup_path)."
  echo "  --filename    : Name of the backup file without extension (required for 'restore', default for 'backup': 'backup-<timestamp>')."
  echo "  --namespace   : Kubernetes namespace (default: $default_namespace)."
  echo "  --help        : Show this help message and exit."
  echo ""
  echo "IMPORTANT:"
  echo "  - Ensure that the paths provided in '--hostpath' are included in the Docker Desktop Shared Directories."
  echo "    Refer to this guide for configuration: https://docs.docker.com/desktop/settings/#file-sharing"
  exit 0
}

# Parse input arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --operation) operation="$2"; shift ;;
    --hostpath) hostpath="$2"; shift ;;
    --filename) filename="$2"; shift ;;
    --namespace) namespace="$2"; shift ;;
    --help) show_usage ;; # Implementing the --help flag
    *) echo "❌ Unknown parameter passed: $1"; show_usage ;;
  esac
  shift
done

# Validate required inputs
if [[ -z "$operation" ]]; then
  echo "❌ Error: Operation (--operation) is required."
  show_usage
fi

# Set default values for optional inputs
namespace=${namespace:-$default_namespace}
hostpath=${hostpath:-$default_backup_path}

# Validate inputs for restore
if [[ "$operation" == "restore" ]]; then
  if [[ -z "$hostpath" ]]; then
    echo "❌ Error: Hostpath (--hostpath) is required for restore operation."
    show_usage
  fi
  if [[ -z "$filename" ]]; then
    echo "❌ Error: Filename (--filename) is required for restore operation."
    show_usage
  fi
  # Remove .tar.gz if provided
  filename=${filename%.tar.gz}

  # Validate the file existence
  if [ ! -f "$hostpath/$filename.tar.gz" ]; then
    echo "❌ Error: Backup file $hostpath/$filename.tar.gz does not exist."
    exit 1
  fi
fi

# Determine filename for backup
if [[ "$operation" == "backup" ]]; then
  if [[ -z "$filename" ]]; then
    filename="${default_filename}-${timestamp}"
  else
    filename="${filename%.tar.gz}"
  fi
fi

# Function to check prerequisites
check_prerequisites() {
  echo ""
  echo "🚀 Starting process..."
  echo "🔍 Validating prerequisites..."
  
  if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed."
    exit 1
  fi

  if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed."
    exit 1
  fi

  if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Kubernetes cluster is not running."
    exit 1
  fi

  echo "✅ All prerequisites are valid."
  echo ""
}

# Function to get and store the current replicas of deployments and statefulsets
store_replicas() {
  echo "🔍 Storing current replicas for services in namespace '$namespace'..."
  db_replicas=$(kubectl get deployment "$db_service" -n "$namespace" -o jsonpath='{.spec.replicas}')
  opensearch_replicas=$(kubectl get deployment "$opensearch_service" -n "$namespace" -o jsonpath='{.spec.replicas}')
  dotcms_replicas=$(kubectl get statefulset "$dotcms_service" -n "$namespace" -o jsonpath='{.spec.replicas}')
  
  echo "$db_replicas" > /tmp/db_replicas.txt
  echo "$opensearch_replicas" > /tmp/opensearch_replicas.txt
  echo "$dotcms_replicas" > /tmp/dotcms_replicas.txt
  
  echo "✅ Replicas stored: $db_service=$db_replicas, $opensearch_service=$opensearch_replicas, $dotcms_service=$dotcms_replicas"
}

# Function to scale down services
scale_down_services() {
  echo "⬇️  Scaling down services in namespace '$namespace'..."
  echo ""
  kubectl scale statefulset "$dotcms_service" --replicas=0 -n "$namespace"
  kubectl scale deployment "$opensearch_service" --replicas=0 -n "$namespace"
  kubectl scale deployment "$db_service" --replicas=0 -n "$namespace"
  echo ""
  echo "✅ Services scaled down."
  echo ""
}

# Function to scale up services
scale_up_services() {
  echo "⬆️  Scaling up services in namespace '$namespace'..."
  echo ""
  db_replicas=$(cat /tmp/db_replicas.txt)
  opensearch_replicas=$(cat /tmp/opensearch_replicas.txt)
  dotcms_replicas=$(cat /tmp/dotcms_replicas.txt)

  kubectl scale deployment "$db_service" --replicas="$db_replicas" -n "$namespace"
  kubectl scale deployment "$opensearch_service" --replicas="$opensearch_replicas" -n "$namespace"
  kubectl scale statefulset "$dotcms_service" --replicas="$dotcms_replicas" -n "$namespace"
  echo ""
  echo "✅ Services scaled up to previous states: $db_service=$db_replicas, $opensearch_service=$opensearch_replicas, $dotcms_service=$dotcms_replicas"
  echo ""
}

# Function to wait until all resources are scaled down
wait_for_scale_down() {
  echo "⏳ Waiting for all resources to scale down in namespace '$namespace'..."
  echo ""
  while true; do
    # Check dotcms-cluster (StatefulSet)
    dotcms_ready=$(kubectl get statefulset "$dotcms_service" -n "$namespace" -o jsonpath='{.status.readyReplicas}')
    dotcms_ready=${dotcms_ready:-0}

    # Check opensearch (Deployment)
    opensearch_ready=$(kubectl get deployment "$opensearch_service" -n "$namespace" -o jsonpath='{.status.readyReplicas}')
    opensearch_ready=${opensearch_ready:-0}

    # Check db (Deployment)
    db_ready=$(kubectl get deployment "$db_service" -n "$namespace" -o jsonpath='{.status.readyReplicas}')
    db_ready=${db_ready:-0}

    # Print status
    echo "📋 Status: $dotcms_service: $dotcms_ready, $opensearch_service: $opensearch_ready, $db_service: $db_ready"

    # Check if all are scaled down (readyReplicas = 0)
    if [[ $dotcms_ready -eq 0 && $opensearch_ready -eq 0 && $db_ready -eq 0 ]]; then
      echo "✅ All resources have been successfully scaled down."
      echo ""
      break
    fi

    # Wait before rechecking
    sleep 5
  done
}

# Function to run backup
run_backup() {
  echo "📦 Running backup operation..."
  echo ""

  # Scale down services before backup
  store_replicas
  scale_down_services
  wait_for_scale_down  

  # Use Helm values for backup
  helm upgrade --install dotcms-backup "$chart_path" \
    --namespace "$namespace" \
    --set operation=backup \
    --set hostPath="$hostpath" \
    --set fileName="$filename"

  if [[ $? -eq 0 ]]; then
    echo "✅ Backup completed successfully. File saved at: $hostpath/$filename.tar.gz"
    echo ""
  else
    echo "❌ Backup failed."
    exit 1
  fi

  # Scale up services after restore
  scale_up_services  
}

# Function to run restore
run_restore() {
  echo "🗄️  Running restore operation..."
  echo ""

  # Scale down services before restore
  store_replicas
  scale_down_services
  wait_for_scale_down

  # Use Helm values for restore
  helm upgrade --install dotcms-restore "$chart_path" \
    --namespace "$namespace" \
    --set operation=restore \
    --set hostPath="$hostpath" \
    --set fileName="$filename"

  if [[ $? -eq 0 ]]; then
    echo "✅ Restore completed successfully."
    echo ""
  else
    echo "❌ Restore failed."
    exit 1
  fi

  # Scale up services after restore
  scale_up_services
}

# Function to cleanup Helm releases
cleanup_releases() {
  echo "🧹 Cleaning up backup and restore releases in $namespace..."
  
  helm uninstall dotcms-backup --namespace "$namespace" 2>/dev/null || echo "⚠️ Backup release not found."
  helm uninstall dotcms-restore --namespace "$namespace" 2>/dev/null || echo "⚠️ Restore release not found."

  echo "✅ Cleanup completed successfully."
}

# Validate prerequisites
check_prerequisites

# Execute operation
case $operation in
  backup)
    run_backup
    ;;
  restore)
    run_restore
    ;;
  cleanup)
    cleanup_releases
    ;;
  *)
    echo "❌ Error: Invalid operation '$operation'. Must be 'backup', 'restore', or 'cleanup'."
    exit 1
    ;;
esac
