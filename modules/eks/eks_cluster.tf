##################################################################
# Info
# IAM_ROLES(what action a serive can perform in aws).Trust_Policy is like who is allowed to use the role and use the permission attached to role.
# IAM Roles need by eks(AmazonEKSClusterPolicy(EC2,Volumes,ELB)).
# EKS automatcially create service-linked role named AWSServiceRoleForAmazonEKS has permission to interact with (ENI,SG,VPC,CW)
# AWS KMS used for encryting k8s secrets.Symmetric type and should be able to do encrypt and decrypt.Same Region as cluster.
##################################################################

##################################################################
# DataSource.
##################################################################

data "aws_iam_policy" "amazonEKSClusterPolicy" {
  name = "AmazonEKSClusterPolicy"
}
data "aws_eks_addon_version" "eks_addons_version" {
  for_each = var.eks_addons_list
  addon_name = each.key
  kubernetes_version = var.cluster_version

}

##################################################################
# IAM Roles for eks.
# Managed iam eks policy in use by eks-cluster[AmazonEKSClusterPolicy] and used by nodes are in eks-managed-node-group module
##################################################################

resource "aws_iam_role" "eksClusterRole" {
  name = "eks_cluster_role_${var.cluster_name}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
                    {
                        "Effect": "Allow",
                        "Principal": {
                                        "Service": "eks.amazonaws.com"
                                    },
                        "Action": "sts:AssumeRole"
                    }           
                ]
  })

  tags = merge(
            {"Name"= "eks_${var.cluster_name}_cluster_role"},
            var.cluster_tags
  )
}

resource "aws_iam_role_policy_attachment" "eksClusterRoleAttach" {
  role       = aws_iam_role.eksClusterRole.name
  policy_arn = data.aws_iam_policy.amazonEKSClusterPolicy.arn
}
##################################################################
# Addtional custom SG for eks
# EKS Managed Nodes SG and rule
##################################################################
resource "aws_security_group" "eks_addtional_sg" {
  vpc_id = var.cluster_vpc_id
  ingress{
            from_port = "0"                                                     #Here we are accepting traffic on 443 port for api endpoint.
            to_port = "0"
            protocol = "-1"
            security_groups = [ aws_security_group.eks_mgd_nodes_sg.id ]
            description = "Custom eks cluster sg"

  }                                                
  tags = merge(
                    {"Name" = "eks_${var.cluster_name}_cluster_addtional_sg"},
                    var.cluster_tags
  )
  depends_on = [ aws_security_group.eks_mgd_nodes_sg ]
}

resource "aws_security_group" "eks_mgd_nodes_sg" {
  vpc_id = var.cluster_vpc_id  
                                              
  tags = merge(
                    {"Name" = "eks_${var.cluster_name}_eks_mgd_nodes_sg"},
                    var.cluster_tags
  )
}

resource "aws_security_group_rule" "eks_mgd_nodes_sg_rule" {
  
  for_each = {for idx,rule in var.eks_mgd_nodes_sg_rules: "${rule.type}-${rule.from_port}-${idx}" => rule }    # here since the info is in object we are basically creating map for A for_each. 
  type              = each.value.type                                                                          # ${rule.type}-${rule.from_port}-${idx} is basically creating unquie keys and anything after => is value for the key
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description = each.value.description
  security_group_id = aws_security_group.eks_mgd_nodes_sg.id

  # Conditional assignment to avoid conflict
  cidr_blocks             = each.value.cidr_blocks != null ? each.value.cidr_blocks : null
  ipv6_cidr_blocks        = each.value.ipv6_cidr_blocks != null ? each.value.ipv6_cidr_blocks : null
  source_security_group_id = each.value.source_security_group_id != "null" ? (
  each.value.from_port == 53 || each.value.from_port == 1025 ? aws_security_group.eks_mgd_nodes_sg.id : aws_security_group.eks_addtional_sg.id
  ) : null

  depends_on = [ aws_security_group.eks_mgd_nodes_sg,aws_security_group.eks_addtional_sg ]
}

/*resource "aws_security_group_rule" "eks_mgd_nodes_sg_rule1" {
  
  type              = "ingress"                                                                         # ${rule.type}-${rule.from_port}-${idx} is basically creating unquie keys and anything after => is value for the key
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  security_group_id = aws_security_group.eks_mgd_nodes_sg.id
  source_security_group_id = aws_security_group.eks_addtional_sg.id

  # Conditional assignment to avoid conflict  

  depends_on = [ aws_security_group.eks_mgd_nodes_sg,aws_security_group.eks_addtional_sg ]
}
resource "aws_security_group_rule" "eks_mgd_nodes_sg_rule2" {
  
  type              = "ingress"                                                                         # ${rule.type}-${rule.from_port}-${idx} is basically creating unquie keys and anything after => is value for the key
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  security_group_id = aws_security_group.eks_mgd_nodes_sg.id
  self = true
  # Conditional assignment to avoid conflict  

  depends_on = [ aws_security_group.eks_mgd_nodes_sg,aws_security_group.eks_addtional_sg ]
}*/
##################################################################
# eks managed add-ons(vpc-cni,kube-proxy,coredns,eks-pod-identity-agent)
# policy for vpc-cni is already added as part of eks-managed-nodes-roles
# in eks-managed-nodes module
# eks_addons_before_compute mean we need those add-on before node-group is launched(like vpc-cni).
# eks_addons_after_compute mean we need those add-on after nodes  are launched. 
##################################################################
resource "aws_eks_addon" "eks_addons_before_compute" {

  cluster_name = aws_eks_cluster.main.name
  for_each = {for k ,v in var.eks_addons_list: k => v if v == "before_compute"}
  addon_name = each.key
  addon_version = data.aws_eks_addon_version.eks_addons_version[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [ aws_eks_cluster.main ]  
  tags = merge(
                    {"Name" = "eks_${var.cluster_name}_add_ons"},
                    var.cluster_tags
  )

}

resource "aws_eks_addon" "eks_addons_after_compute" {

  for_each = {for k ,v in var.eks_addons_list: k => v if v == "after_compute"}
  cluster_name = aws_eks_cluster.main.name
  addon_name = each.key
  addon_version = data.aws_eks_addon_version.eks_addons_version[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [ aws_eks_cluster.main,aws_eks_node_group.managed_nodes ]
  tags = merge(
                    {"Name" = "eks_${var.cluster_name}_add_ons"},
                    var.cluster_tags
  )
}

##################################################################
# eks cluster
##################################################################

resource "aws_eks_cluster" "main" { 
  name = var.cluster_name
  version = var.cluster_version
  role_arn = aws_iam_role.eksClusterRole.arn
  
  access_config {
    authentication_mode = "API"
  }

  vpc_config {
                subnet_ids = [for ids in var.cluster_subnets_id: ids]
                endpoint_private_access = var.api_private_endpoint
                endpoint_public_access = var.api_public_endpoint
                public_access_cidrs = var.public_cidrs
                security_group_ids = [aws_security_group.eks_addtional_sg.id]
  }
  upgrade_policy {
    support_type = var.support_type                                                 # Do we need Extended or Standard support.
  }
  
  bootstrap_self_managed_addons = false                                              # Install aws_cni,kube-proxy and coredns during cluster creation.
  # enabled_cluster_log_types =                                                     # Need this
  # encryption_config =                                                             # Need this

  depends_on = [aws_iam_role.eksClusterRole,aws_security_group.eks_addtional_sg]
}

##################################################################
# eks cluster managed nodes config
##################################################################

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.main.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
}

resource "random_id" "node_group_suffix" {
  byte_length = 2  # Generates a short random suffix
}

resource "aws_eks_node_group" "managed_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "hfnlife_node_group_${random_id.node_group_suffix.hex}"
  version         = aws_eks_cluster.main.version
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  node_role_arn   = var.noderolearn
  subnet_ids      = [for ids in var.private_subnet_id: ids]
  instance_types = var.node_group_instance_type
  capacity_type =  var.node_group_capacity_type
  labels = var.node_group_labels
  update_config {
    max_unavailable = 1
  }
 launch_template {
   id = var.eks_custom_launch_template_id
   version = "$Latest"
 }
  scaling_config {
    desired_size = 2
    max_size = 2
    min_size = 1
  }
  depends_on = [ aws_eks_addon.eks_addons_before_compute ]
}
