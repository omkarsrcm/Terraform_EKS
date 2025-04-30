##################################################################
# eks variables
##################################################################
variable "cluster_name" {
  type = string
  default = "eks_example"
}
variable "cluster_version" {
  type = string
  default = "1.31"
}
variable "cluster_vpc_id" {
  type = string
  default = ""
}
variable "cluster_subnets_id" {
  type = list(string)
}
variable "cluster_tags" {
  type = map(string)
  default = {}
}
variable "api_private_endpoint" {
  type = string
  default = "true"
}
variable "api_public_endpoint" {
  type = string
  default = "true"
}
variable "public_cidrs" {
  type = list(string)
  default = [ "0.0.0.0/0" ]
  
}
variable "support_type" {
  type = string
  default = "STANDARD"
}
variable "eks_mgd_nodes_sg_rules" {
  type = list(object({
    from_port = number
    to_port = number
    description = string
    protocol = string
    type = string                                     # Ingress/Egress
    cidr_blocks = optional(list(string), null)
    ipv6_cidr_blocks = optional(list(string),null)
    source_security_group_id = optional(string,null)  # SG reference
  }))
  default = [ {
    from_port = 53
    to_port = 53
    description = "node to node coreDNS"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
  {
    from_port = 53
    to_port = 53
    description = "node to node coreDNS"
    protocol = "udp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  }
  ,
  {
    from_port = 443
    to_port = 443
    description = "eks cluster api to nodes"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
  {
    from_port = 10250
    to_port = 10250
    description = "eks cluster api to kubelets on nodes"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
  {
    from_port = 6443
    to_port = 6443
    description = "eks cluster api to nodes via tcp webhooks"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
  {
    from_port = 9443
    to_port = 9443
    description = "eks cluster api to nodes via tcp webhooks"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
  {
    from_port = 4443
    to_port = 4443
    description = "eks cluster api to nodes via tcp webhooks"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
  {
    from_port = 8443
    to_port = 8443
    description = "eks cluster api to nodes via tcp webhooks"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
  {
    from_port = 1025
    to_port = 65535
    description = "node to node ingress on ephemeral ports"
    protocol = "tcp"
    type = "ingress"                                    # Ingress/Egress
    cidr_blocks = null
    ipv6_cidr_blocks = null
    source_security_group_id = ""  # SG reference
  },
    {
    from_port = 0
    to_port = 0
    description = "all egress"
    protocol = "-1"
    type = "egress"                                    # Ingress/Egress
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    source_security_group_id = "null"  # SG reference
  },
 ]
}
variable "noderolearn" {
  type = string
}
variable "private_subnet_id" {
  type = list(string)
}
variable "eks_addons_list" {
  type = map(string)
  default = {
    "vpc-cni" = "before_compute",
    "coredns" = "after_compute",
    "kube-proxy" = "after_compute",
    "eks-pod-identity-agent" = "after_compute"
  }
}
variable "eks_custom_launch_template_id" {
  type = string
  default = "null"
}
variable "node_group_capacity_type" {
  type = string
  default = "ON_DEMAND"
}
variable "node_group_instance_type" {
  type = set(string)
  default = [ "t2.medium" ]
}
variable "node_group_labels" {
  type = map(string)
  default = {
    "name" = "example"
  }
}
