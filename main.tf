################################################################
# Comman Parameters for all resources
################################################################
locals {
    tags = {
    owner = "devops",
    env= "eks-prd-ap",
    customer="hfnlife"
}
aws_region = "ap-south-1"
ekscluster_name = "hfnlife-dev"
}
################################################################
# VPC Parameters
################################################################
module "vpc" {
  source     = "./modules/vpc"
  vpc_name = local.ekscluster_name
  public_sg_rules = [
  {
    type         = "ingress"
    from_port    = 443
    to_port      = 443
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
]
   tags = local.tags

}


################################################################
# Cluster Parameters
################################################################

module "eks" {
  source        = "./modules/eks"
  cluster_version = "1.32"
  cluster_name = "hfnlife_prd"
  cluster_vpc_id = module.vpc.vpc_id
  cluster_subnets_id = module.vpc.control_plane_subnets_ids
  private_subnet_id = module.vpc.private_subnets_ids
  cluster_tags = local.tags
  noderolearn = module.eks-managed-nodes-group.eksManagedNodeRoleARN
  eks_custom_launch_template_id = module.eks-managed-nodes-group.eks_custom_launch_template_id
  node_group_labels = {"instance_type" = "t2.medium","team"= "devops" }
  node_group_instance_type = ["t3.micro"]

}

################################################################
# Mananged Nodes Parameters
################################################################

module "eks-managed-nodes-group" {
  source        = "./modules/eks-managed-nodes-group"
  eks_node_role_name = local.ekscluster_name
  eks_mgd_nodes_tags = local.tags
  eks_node_group_name = local.ekscluster_name
  eks_node_custom_sg_ids = concat(module.eks.eks_mgd_nodes_sg_id)  
}


