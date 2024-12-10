#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print a breakline for readability
print_breakline() {
    echo -e "${YELLOW}============================================================${NC}"
}

# Set default Kubernetes context
## $ kubectl config get-contexts
KUBECTL_CONTEXT="kind-devops-test"

# Initial prerequisites check
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    check_k8s_connection
}

# Check if connected to the Kubernetes cluster
check_k8s_connection() {
    current_context=$(kubectl config current-context 2>/dev/null)
    
    if [[ "$current_context" != "$KUBECTL_CONTEXT" ]]; then
        echo -e "${YELLOW}>>> Not connected to the Kubernetes cluster. Please provide the path to your kubeconfig file to connect.${NC}"
        
        # Prompt user for kubeconfig path
        read -p "Enter the path to your kubeconfig file: " kubeconfig_path
        
        # Attempt to use the provided kubeconfig
        export KUBECONFIG="$kubeconfig_path"
        kubectl config use-context "$KUBECTL_CONTEXT" &> /dev/null
        
        # Check again if the connection was successful
        if [[ "$(kubectl config current-context)" == "$KUBECTL_CONTEXT" ]]; then
            echo -e "${GREEN}Connected to Kubernetes cluster with context: $KUBECTL_CONTEXT${NC}"
        else
            echo -e "${RED}Failed to connect to Kubernetes cluster with the provided kubeconfig file. Please verify the file and try again.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Already connected to Kubernetes cluster with context: $KUBECTL_CONTEXT${NC}"
    fi
}

# Help menu function
print_help() {
    echo -e "${BLUE}Script Usage:${NC}"
    echo "This script automates Kubernetes tasks, including installing Helm and KEDA, setting up the Metrics Server, creating and managing deployments, and configuring KEDA autoscaling."
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help          Show this help menu."
    echo "  run_all_steps       Execute all main steps in sequence (useful for initial setup)."
    echo -e "${YELLOW}Interactive Menu Options:${NC}"
    echo "  1. Install Helm and KEDA"
    echo "  2. Install Metrics Server"
    echo "  3. Create a Kubernetes Deployment"
    echo "  4. Configure KEDA Autoscaling"
    echo "  5. Get Deployment Health"
    echo "  6. Undo Deployment"
    echo "  7. Delete Deployment"
    echo "  8. Exit"
}

# Run all main steps sequentially
run_all_steps() {
    echo -e "${BLUE}Running all setup steps in sequence...${NC}"
    install_helm_and_keda
    install_metrics_server
    create_deployment
    configure_keda_autoscaling
    echo -e "${GREEN}All steps completed successfully.${NC}"
}

# Function to install Helm and KEDA
install_helm_and_keda() {
    if ! command -v helm &> /dev/null; then
        print_breakline
        echo -e "${YELLOW}>>> Installing Helm...${NC}"
        curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
        echo -e "${GREEN}Helm installed successfully.${NC}"
    else
        echo -e "${GREEN}Helm is already installed.${NC}"
    fi

    if ! kubectl get ns keda &> /dev/null; then
        print_breakline
        echo -e "${YELLOW}>>> Installing KEDA...${NC}"
        helm repo add kedacore https://kedacore.github.io/charts
        helm repo update
        helm install keda kedacore/keda --namespace keda --create-namespace
        echo -e "${GREEN}KEDA installed successfully.${NC}"
    else
        echo -e "${GREEN}KEDA is already installed.${NC}"
    fi
}

# Function to install the Metrics Server with custom arguments
install_metrics_server() {
    if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        print_breakline
        echo -e "${YELLOW}>>> Installing Metrics Server...${NC}"
        wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        sed -i '/args:/a\        - --kubelet-insecure-tls' components.yaml
        kubectl apply -f components.yaml
        rm components.yaml
        echo -e "${GREEN}Metrics Server installed successfully with custom arguments.${NC}"
    else
        echo -e "${GREEN}Metrics Server is already installed.${NC}"
    fi
}

# Function to create a Kubernetes deployment
create_deployment() {
    print_breakline
    echo -e "${BLUE}>>> Creating a new deployment...${NC}"

    read -p "Namespace (default is 'default'): " namespace
    namespace=${namespace:-default}

    read -p "Deployment name (default is 'my-deployment'): " deployment_name
    deployment_name=${deployment_name:-my-deployment}

    read -p "Container image (default is 'nginx'): " image
    image=${image:-nginx}

    read -p "Container port (default 80): " container_port
    container_port=${container_port:-80}

    read -p "CPU request (default is '100m'): " cpu_request
    cpu_request=${cpu_request:-100m}

    read -p "Memory request (default is '128Mi'): " memory_request
    memory_request=${memory_request:-128Mi}

    read -p "CPU limit (default is '200m'): " cpu_limit
    cpu_limit=${cpu_limit:-200m}

    read -p "Memory limit (default is '256Mi'): " memory_limit
    memory_limit=${memory_limit:-256Mi}

    print_breakline
    echo -e "${YELLOW}Creating namespace ${namespace}...${NC}"
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

    print_breakline
    echo -e "${YELLOW}Creating deployment $deployment_name...${NC}"
    kubectl create deployment "$deployment_name" --image="$image" -n "$namespace"

    kubectl set resources deployment "$deployment_name" -n "$namespace" \
        --requests=cpu="$cpu_request",memory="$memory_request" \
        --limits=cpu="$cpu_limit",memory="$memory_limit"

    print_breakline
    echo -e "${YELLOW}Creating NodePort service for $deployment_name...${NC}"
    kubectl expose deployment "$deployment_name" --type=NodePort --name="${deployment_name}-service" -n "$namespace" --port=80 --target-port="$container_port"

    echo -e "${GREEN}Deployment $deployment_name created successfully.${NC}"
    print_breakline
}

# Function to configure KEDA autoscaling
configure_keda_autoscaling() {
    print_breakline
    echo -e "${BLUE}>>> Configuring KEDA Autoscaling...${NC}"

    read -p "Enter the deployment name for autoscaling: " deployment_name
    read -p "Enter the namespace of the deployment: " namespace
    read -p "Enter the target memory utilization percentage (e.g., 50): " target_value
    target_value="${target_value}%"

    cat <<EOF > keda_scaled_object.yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: ${deployment_name}-scaledobject
  namespace: ${namespace}
spec:
  maxReplicaCount: 5
  minReplicaCount: 1
  scaleTargetRef:
    name: ${deployment_name}
  triggers:
    - type: cpu
      metricType: Utilization
      metadata:
        value: "${target_value}"
EOF

    kubectl apply -f keda_scaled_object.yaml -n "$namespace"
    echo -e "${GREEN}KEDA Autoscaling configured successfully for deployment ${deployment_name}.${NC}"
    print_breakline
}

# Function to get the health status of a deployment
get_deployment_health() {
    print_breakline
    echo -e "${BLUE}>>> Get Deployment Health...${NC}"
    read -p "Enter the namespace of the deployment: " namespace
    read -p "Enter the deployment name: " deployment_name

    echo -e "${YELLOW}Fetching health status for deployment ${deployment_name}...${NC}"
    kubectl get deployment "$deployment_name" -n "$namespace" -o wide

    if ! kubectl top nodes &> /dev/null; then
        echo -e "${RED}Metrics Server is not installed. Skipping resource usage display.${NC}"
    else
        echo -e "${YELLOW}Resource usage:${NC}"
        kubectl top pods -n "$namespace" | grep "$deployment_name" || echo -e "${RED}No resource usage data available.${NC}"
    fi
    print_breakline
}

# Function to undo a deployment
undo_deployment() {
    print_breakline
    echo -e "${BLUE}>>> Undo Deployment Process...${NC}"
    read -p "Enter the deployment name to undo: " deployment_name
    read -p "Enter the namespace of the deployment: " namespace

    echo -e "${YELLOW}Undoing the last deployment for ${deployment_name}...${NC}"
    kubectl rollout undo deployment "$deployment_name" -n "$namespace"
    echo -e "${GREEN}Deployment ${deployment_name} undone successfully.${NC}"
    print_breakline
}

# Function to delete a deployment
delete_deployment() {
    print_breakline
    echo -e "${BLUE}>>> Deleting Deployment...${NC}"
    read -p "Enter the deployment name to delete: " deployment_name
    read -p "Enter the namespace of the deployment: " namespace

    echo -e "${YELLOW}Deleting deployment ${deployment_name}...${NC}"
    kubectl delete deployment "$deployment_name" -n "$namespace"
    echo -e "${GREEN}Deployment ${deployment_name} deleted successfully.${NC}"
    print_breakline
}


# Run prerequisite check before any main actions (Checking K8s connection)
check_prerequisites

# Main script execution
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
elif [[ "$1" == "run_all_steps" ]]; then
    run_all_steps
    exit 0
fi

# Interactive menu
while true; do
    echo -e "${BLUE}Choose an action:${NC}"
    echo "1. Install Helm and KEDA"
    echo "2. Install Metrics Server"
    echo "3. Create a Kubernetes Deployment"
    echo "4. Configure KEDA Autoscaling"
    echo "5. Get Deployment Health"
    echo "6. Undo Deployment"
    echo "7. Delete Deployment"
    echo "8. Run All Steps"
    echo "9. Exit"

    read -p "Select an option (1-9): " choice

    case "$choice" in
        1) install_helm_and_keda ;;
        2) install_metrics_server ;;
        3) create_deployment ;;
        4) configure_keda_autoscaling ;;
        5) get_deployment_health ;;
        6) undo_deployment ;;
        7) delete_deployment ;;
        8) run_all_steps ;;
        9) echo -e "${GREEN}Exiting.${NC}"; break ;;
        *) echo -e "${RED}Invalid choice. Please select a valid option.${NC}" ;;
    esac
done
