
# 🌐 EKS Terraform Module

This repository contains a modular and reusable Terraform setup to provision a complete Amazon EKS (Elastic Kubernetes Service) cluster on AWS. It uses isolated modules for VPC, EKS control plane, and EKS-managed node groups.
---

## ✅ Prerequisites & IAM Setup

To use this Terraform module securely and in alignment with GitOps practices, follow the IAM and S3 bucket setup instructions below:

### 1. Create IAM User: terraform-executor

Create a non-SSO IAM user with permission to assume a role. This avoids browser-based SSO logins which are incompatible with automation.

Attach the following inline policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:aws:iam::AccountID:role/terraform-executor-role"
      ]
    }
  ]
}
```

---

### 2. Create IAM Role: terraform-executor-role

This role will be assumed by the `terraform-executor` user. It requires:

#### 🔸 Trust Relationship

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::AccountID:user/terraform-executor"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### 🔸 Permissions

- Access to manage EKS, EC2, IAM, and S3
- S3 access for Terraform state storage

🔹 EKS + IAM + EC2 Permissions (sample scope shown, see full policy above):

```json
{
  "Effect": "Allow",
  "Action": [
    "eks:*",
    "ec2:*",
    "iam:*",
    "ssm:GetParameter"
  ],
  "Resource": "*"
}
```

🔹 S3 Bucket Access:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    "arn:aws:s3:::hfnlife-dev",
    "arn:aws:s3:::hfnlife-dev/terraform_state/*"
  ]
}
```

---

### 3. Create & Configure S3 Bucket for Terraform Backend

Enable versioning on the bucket (e.g. `hfnlife-dev`). Add this bucket policy to allow role access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListTerraformStateFolder",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::497439481164:role/terraform-executor-role"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::hfnlife-dev",
      "Condition": {
        "StringLike": {
          "s3:prefix": "terraform_state/*"
        }
      }
    },
    {
      "Sid": "AccessTerraformStateObjects",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::497439481164:role/terraform-executor-role"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::hfnlife-dev/terraform_state/*"
    }
  ]
}
```

---

### 4. Environment Variables for Terraform Execution

Set the IAM user credentials used to assume the role:

```bash
export AWS_ACCESS_KEY_ID=<access_key>
export AWS_SECRET_ACCESS_KEY=<secret_key>
```

These credentials allow Terraform to assume terraform-executor-role as defined in provider.tf.

---

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
- This module does  install the Kubernetes add-ons (like CoreDNS, VPC-CNI, etc.).
- You can use kubectl by setting up your kubeconfig:

```bash
aws eks update-kubeconfig --name <cluster_name> --region <region>
```

---

## 👨‍💻 Author

Maintained by the Omvexis DevOps Team.

---
