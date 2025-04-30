output "addons_id" {
  value = [for ids in data.aws_eks_addon_version.eks_addons_version: ids.version]
}
output "eks_mgd_nodes_sg_id" {
  value = [aws_security_group.eks_mgd_nodes_sg.id]
}