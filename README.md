# Kubernetes Automation Script

This script is designed to simplify Kubernetes management tasks by automating common actions such as installing Helm and KEDA, setting up the Metrics Server, creating and managing deployments, and configuring KEDA autoscaling. 

It provides an interactive menu, making it easy for users to select specific actions, as well as an option to run all tasks sequentially for initial setup.

## Table of Contents
1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Options and Menu](#options-and-menu)
5. [Functions and Descriptions](#functions-and-descriptions)
6. [Example Usage](#example-usage)
7. [Troubleshooting](#troubleshooting)

---

## Features

- **Interactive Menu**: Easily select tasks to run directly from the terminal.
- **Install Helm and KEDA**: Automates Helm installation and the setup of KEDA for Kubernetes-based autoscaling.
- **Metrics Server Installation**: Installs Metrics Server with a custom argument for secure metrics retrieval.
- **Deployment Management**: Create, configure, scale, check health, undo, and delete Kubernetes deployments.
- **KEDA Autoscaling**: Configure autoscaling with CPU utilization-based triggers.

---

## Installation

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```
2. **Grant Execute Permission**:
   ```bash
   chmod +x kubernetes_automation.sh
   ```

---

## Usage

To display the help menu, use:
```bash
./kubernetes_automation.sh -h
```

### To Run All Setup Steps at Once
For initial setup, you can run all tasks in sequence:
```bash
./kubernetes_automation.sh run_all_steps
```

### Interactive Mode
Run the script without arguments to access the interactive menu:
```bash
./kubernetes_automation.sh
```

---

## Options and Menu

This script provides the following options:

| Option | Description |
| ------ | ----------- |
| `-h`, `--help` | Displays the help menu with usage details. |
| `run_all_steps` | Executes all primary setup steps in sequence. |
| **Interactive Options** | |
| `1` | Install Helm and KEDA |
| `2` | Install Metrics Server |
| `3` | Create a Kubernetes Deployment |
| `4` | Configure KEDA Autoscaling |
| `5` | Get Deployment Health |
| `6` | Undo Deployment |
| `7` | Delete Deployment |
| `8` | Run All Steps |
| `9` | Exit |

---

## Functions and Descriptions

### 1. `install_helm_and_keda`
- Installs **Helm** if it's not already present.
- Sets up **KEDA** in the `keda` namespace, allowing Kubernetes-based autoscaling.

### 2. `install_metrics_server`
- Installs the **Metrics Server** with custom arguments to accommodate insecure TLS configurations.

### 3. `create_deployment`
- Prompts for namespace, deployment name, image, ports, CPU, and memory configurations.
- Creates a deployment and exposes it via a **NodePort** service.

### 4. `configure_keda_autoscaling`
- Configures **KEDA Autoscaling** for a specific deployment.
- Supports autoscaling based on CPU utilization thresholds.

### 5. `get_deployment_health`
- Displays deployment health status and resource usage.
- Requires the **Metrics Server** for resource data display.

### 6. `undo_deployment`
- Rolls back the last deployment update, allowing easy reversal of recent changes.

### 7. `delete_deployment`
- Deletes a specified deployment, freeing up resources and simplifying cleanup.

---

## Example Usage

To create a deployment with autoscaling:
1. Run the script and select `3` to create a deployment.
2. Follow the prompts to specify namespace, deployment name, image, port, and resource limits.
3. After deployment creation, choose `4` to configure autoscaling.

To undo the last deployment change:
1. Run the script and select `6`.
2. Follow the prompts to enter deployment and namespace names.

---

## Troubleshooting

- **Metrics Server Not Installed**: Ensure Metrics Server is set up correctly. Check if the server’s arguments meet your environment’s requirements.
- **KEDA Installation Issues**: Verify Helm installation and namespace creation for KEDA. Check permissions if installation fails.
- **Invalid Deployment Names**: Ensure deployment names are DNS-compliant, as non-compliant names may cause errors.

---

## License
This project is licensed under the MIT License.

For any additional information or assistance, please contact the repository maintainer.

**EmailId: hyperionlearner999@gmail.com**