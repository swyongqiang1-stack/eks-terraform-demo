# Terraform EKS Cluster on AWS

A modular Terraform configuration that provisions an Amazon EKS cluster with a custom VPC, IAM roles, managed node groups, and core addons.

## Architecture

```text
.
├── eks.tf                  # EKS cluster, addons, and VPC module call
├── iam.tf                  # IAM roles and policy attachments for cluster and node group
├── node.tf                 # EKS managed node group
├── variables.tf            # Root module input variables
├── terraform.tfvars        # Variable values for the root module
└── modules/
    └── vpc/                # Custom VPC networking submodule
        ├── vpc.tf          # VPC, subnets, and internet gateway
        ├── route.tf        # Route tables and subnet associations
        ├── security.tf     # Security group with ingress/egress rules
        ├── variables.tf    # Submodule input variables
        └── output.tf       # Submodule outputs (consumed by the root module)
```

## Key Design Decisions

- **EKS Access Entries (API mode)** instead of the legacy `aws-auth` ConfigMap, reflecting the current AWS-recommended approach for cluster authentication.
- **Three-layer permission model** for cluster access: IAM identity → EKS Access Entry → Kubernetes RBAC.
- **Explicit `depends_on`** on IAM policy attachments to ensure correct creation order and clean teardown (prevents dangling node groups on `destroy`).
- **VPC as a reusable submodule**, decoupling network provisioning from cluster configuration.
- **Subnet IDs passed via module outputs** (not raw CIDR variables), so EKS receives real AWS resource IDs and the dependency graph is correct.

## Components

| Layer | Resources |
|---|---|
| Network | VPC, 2 subnets across AZs, Internet Gateway, route tables, security group |
| Identity | Cluster IAM role, Node IAM role, policy attachments, Access Entry |
| Compute | EKS cluster (v1.35), managed node group |
| Addons | CoreDNS, VPC-CNI |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

To destroy:

```bash
terraform destroy
```

## Requirements

- Terraform >= 1.5
- AWS provider >= 5.0
- Configured AWS credentials with permissions for EKS, EC2, IAM, and VPC

## Notes

This configuration is built as a learning exercise focused on understanding the EKS permission model, module composition, and resource dependency graphs. It is not hardened for production use — public subnets are used for simplicity, and the Access Entry `principal_arn` should be set to a real IAM principal before applying.
