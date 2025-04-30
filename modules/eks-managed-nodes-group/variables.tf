variable "eks_node_role_name" {
  type = string
  default = "eksWorkerNodeRole"
}
variable "eks_node_iam_policy_name" {
  type = list(string)
  default = [ "AmazonEKSWorkerNodePolicy","AmazonEKS_CNI_Policy","AmazonEC2ContainerRegistryPullOnly" ]
}

variable "eks_mgd_nodes_tags" {
    type = map(string)
}
variable "eks_node_group_name" {
    type = string
    default = "eks_cluster_nodes"
}
variable "eks_node_detailed_monitoring" {
     type = bool
     default = false
}
variable "eks_node_custom_sg_ids" {
      type = list(string)
}
variable "eks_custom_instance_type" {
  type = string
  default = "t3.micro"
}