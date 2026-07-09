resource "aws_eks_access_entry" "this" {
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = "arn:aws:iam::463884819678:user/terraform"
  kubernetes_groups = ["dev-1", "dev-2"]
  type              = "STANDARD"
  depends_on = [ aws_eks_cluster.this ]
}


resource "aws_eks_access_policy_association" "this" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.this.principal_arn

  access_scope {
    type       = "cluster"
  }
}


