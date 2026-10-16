# k3s Workspace

A comprehensive Infrastructure as Code repository for provisioning, configuring, and managing lightweight Kubernetes clusters using **k3s** and **Terraform**.

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-844FFF?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![k3s](https://img.shields.io/badge/k3s-Lightweight%20Kubernetes-FFC61C?logo=kubernetes&logoColor=white)](https://k3s.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

**k3s-workspace** provides automated, declarative infrastructure for provisioning and managing lightweight Kubernetes clusters. It combines Terraform for infrastructure provisioning with custom automation scripts for operational excellence, making k3s deployment reproducible and maintainable.

Whether you're setting up a single-node cluster for development or a multi-node production cluster, this workspace provides battle-tested configurations and tooling.

## Key Features

- **Terraform IaC** — Declarative infrastructure definitions for reproducible k3s deployments
- **Automation Scripts** — Shell scripts for cluster setup, validation, and troubleshooting
- **VS Code Integration** — Pre-configured workspace settings for consistent development
- **CI/CD Ready** — GitHub Actions workflows for automated testing and deployment

## Technology Stack

| Component           | Technology                                               | Purpose                                    |
| ------------------- | -------------------------------------------------------- | ------------------------------------------ |
| **Orchestration**   | [k3s](https://k3s.io)                                    | Lightweight, production-grade Kubernetes   |
| **IaC**             | [Terraform](https://www.terraform.io/)                   | Infrastructure provisioning and management |
| **Container CLI**   | [kubectl](https://kubernetes.io/docs/reference/kubectl/) | Kubernetes cluster interaction             |
| **Scripting**       | [Bash 5](https://www.gnu.org/software/bash/)             | Automation and orchestration scripts       |
| **Version Control** | [Git](https://git-scm.com/)                              | Source control and workflow management     |
| **CI/CD**           | [GitHub Actions](https://github.com/features/actions)    | Automated testing and deployment pipelines |

## Directory Structure

```
k3s-workspace/
├── terraform/             # Terraform configurations for infrastructure
│   ├── main.tf            # Primary infrastructure definition
│   ├── variables.tf       # Variable declarations
│   ├── outputs.tf         # Output values
│   └── terraform.tfvars   # Variable assignments (create from template)
├── terraform_mod/
│   ├── environments
│   │   ├── dev
│   │   │   ├── deploy.tfvars
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── production
│   │   │   ├── deploy.tfvars
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   └── staging
│   │       ├── deploy.tfvars
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   └── modules
│       ├── application
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── helm_release
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── monitoring
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── namespace
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── networking
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       └── storage
│           ├── main.tf
│           ├── oputputs.tf
│           └── variables.tf
├── tools/
│   ├── shell/             # Automation scripts
│   │   ├── k3s-setup.sh           # Initial k3s cluster setup
│   │   └── k3s-deploy-test.sh     # Cluster validation
│   └── docs/             # Operational documentation
├── .github/              # GitHub Actions workflows
│   └── workflows/        # CI/CD pipeline definitions
├── .vscode/              # VS Code workspace configuration
├── CONTRIBUTING.md       # Contribution guidelines
├── SECURITY.md           # Security policy
└── README.md             # This file
```

## Requirements

### Prerequisites

Ensure you have the following tools installed before proceeding:

- [**Bash 5**](https://www.gnu.org/software/bash/) — Shell scripting
- [**Git**](https://git-scm.com/install/linux) — Version control
- [**Terraform**](https://developer.hashicorp.com/terraform/install) — Infrastructure provisioning
- [**Kubectl**](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) — Kubernetes CLI

### Supported Operating Systems

- **Linux (Debian-based)** — Recommended and fully tested.
- **Windows** — Use WSL2 (Windows Subsystem for Linux) with Ubuntu.

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/rfprod/k3s-workspace.git; \
  cd k3s-workspace
```

### 2. Set Up k3s Cluster

```bash
sudo bash ./tools/shell/k3s-setup.sh
```

### 3. Verify Cluster Deployment

```bash
bash ./tools/shell/k3s-deploy-test.sh
```

### 4. Configure Terraform Variables

```bash
cp ./terraform/deploy.tfvars.example ./terraform/deploy.tfvars
```

Edit `deploy.tfvars` to use your values.

### 5. Deploy Infrastructure

```bash
cd terraform; \
  terraform init; \
  terraform plan -var-file=./deploy.tfvars -out=./tfplan; \
  terraform apply ./tfplan
```

## Common Commands

### Initialize and Plan

```bash
cd terraform; \
  terraform init; \
  terraform plan -out=./tfplan
```

### Apply Configuration

```bash
terraform apply ./tfplan
```

### Destroy Resources

```bash
terraform destroy -var-file=./deploy.tfvars
```

### Validate k3s Cluster

```bash
kubectl get nodes; \
  kubectl get pods -A
```

## Troubleshooting

### k3s service not starting

```bash
sudo systemctl status k3s; \
  sudo journalctl -xe -u k3s
```

### Kubectl connection refused

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml; \
  sudo chmod 644 $KUBECONFIG
```

### Terraform state issues

```bash
terraform refresh; \
  terraform state list
```
