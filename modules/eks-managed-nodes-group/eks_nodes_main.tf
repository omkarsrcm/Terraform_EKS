##################################################################
# DataSource
##################################################################
data "aws_iam_policy" "eks_node_iam_policies" {
  for_each = toset(var.eks_node_iam_policy_name)
  name =  each.value
}
##################################################################
# IAM Role for EKS Managed Node Group
# AmazonEKSWorkerNodePolicy,AmazonEC2ContainerRegistryPullOnly,AmazonEKS_CNI_Policy(vpc-cni)
##################################################################
resource "aws_iam_role" "eksManagedNodeRole" {
  name = "eks_managed_node_role_${var.eks_node_role_name}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
})
    tags = var.eks_mgd_nodes_tags
}

resource "aws_iam_role_policy_attachment" "eksManagedNodeRoleAttach" {
   role = aws_iam_role.eksManagedNodeRole.name
   for_each = data.aws_iam_policy.eks_node_iam_policies           # Since we used for_each in data.aws_iam_policy.eks_node_iam_policies,
   policy_arn = each.value.arn                                    # its map due to this.When looping over it use each.value.arn and not
                                                                  # data.aws_iam_policy.eks_node_iam_policies.arn
   depends_on = [ aws_iam_role.eksManagedNodeRole ]

}
##################################################################
# custom launch template for eks-managed-nodes 
##################################################################

resource "aws_launch_template" "eks_nodes_custom_templates" {
    name_prefix = "eks_node_template_${var.eks_node_group_name}"
    description   = "Custom Launch template for EKS managed nodes"
    #instance_type = var.eks_custom_instance_type
    vpc_security_group_ids = var.eks_node_custom_sg_ids
    
    block_device_mappings {
         device_name = "/dev/xvda"    # Device name for the root volume
         ebs {

                encrypted = "true"
                volume_size = 25
                volume_type = "gp3"
            }
    }

    monitoring {
        enabled = var.eks_node_detailed_monitoring
    }

    tag_specifications {
        tags = var.eks_mgd_nodes_tags
        resource_type = "instance"
    }
}