
# 🌐 EKS Terraform Module

This repository contains a modular and reusable Terraform setup to provision a complete Amazon EKS (Elastic Kubernetes Service) cluster on AWS. It uses isolated modules for VPC, EKS control plane, and EKS-managed node groups.

---

## 📁 Module Structure

```
.
├── backend-config.tfvars      # Remote backend configuration
├── main.tf                    # Root module to orchestrate submodules
├── provider.tf                # AWS provider configuration
├── modules/
│   ├── eks/                   # EKS cluster (control plane)
│   │   ├── eks_cluster.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   ├── eks-managed-nodes-group/  # Managed node groups
│   │   ├── eks_nodes_main.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   └── vpc/                   # VPC networking layer
│       ├── vpc.tf
│       ├── output.tf
│       └── variables.tf
```

---

## 🚀 Getting Started

### 1. Prerequisites

- Terraform v1.3+
- AWS CLI with configured credentials
- S3 bucket and DynamoDB table (for remote state, optional)

### 2. Backend Configuration (Optional)

Create a file named `backend-config.tfvars`:

```hcl
bucket         = "my-eks-terraform-state"
key            = "eks-cluster/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-locks"
```

### 3. Initialize Terraform

```bash
terraform init -backend-config=backend-config.tfvars
```

### 4. Apply Infrastructure

```bash
terraform plan   # Review resources
terraform apply  # Create infrastructure
```

### 5. Destroy Resources

```bash
terraform destroy
```

---

## 🧱 Modules Explained

### 🔹 VPC Module

Creates a highly available VPC with:

- Public and private subnets across 2 AZs
- NAT Gateway for outbound internet
- Internet Gateway for public access

Inputs: VPC name, CIDR, AZs, subnet CIDRs  
Outputs: VPC ID, subnet IDs

---

### 🔹 EKS Module

Creates the EKS control plane:

- AWS EKS cluster with IAM roles
- OIDC provider
- Security groups

Inputs: Cluster name, VPC/subnet IDs, IAM roles  
Outputs: Cluster name, ARN, endpoint

---

### 🔹 EKS Managed Node Group

Launches worker nodes in the cluster:

- Uses `aws_eks_node_group`
- Auto-scaling configuration
- IAM role and tags

Inputs: Node group name, instance type, min/max size, subnets  
Outputs: Node group name, ASG name

---

## 📤 Outputs

- cluster_name
- cluster_endpoint
- vpc_id
- private_subnets
- node_group_name

---

## ⚠️ Notes

- IAM roles and policies should be pre-created or managed externally.
- This module does install the Kubernetes add-ons (like CoreDNS, VPC-CNI, etc.).
- You can use kubectl by setting up your kubeconfig:

```bash
aws eks update-kubeconfig --name <cluster_name> --region <region>
```

---

## 👨‍💻 Author

Maintained by the Omvexis DevOps Team.
