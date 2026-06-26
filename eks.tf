resource "aws_eks_cluster" "this" {
  name = "cluster"
  
  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.35"

  vpc_config {
    subnet_ids = module.vpc.subnet_list
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}



resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.1" #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
}



module "vpc" {
  source = "./modules/vpc"
  subnet = var.subnet
}