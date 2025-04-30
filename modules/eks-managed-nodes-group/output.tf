output "eksManagedNodeRoleARN" {
  value = aws_iam_role.eksManagedNodeRole.arn
}
output "eks_custom_launch_template_id" {
  value = aws_launch_template.eks_nodes_custom_templates.id
}