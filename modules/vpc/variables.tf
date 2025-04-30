##################################################################
# VPC variables
##################################################################
variable "vpc_name" {
  description = "VPC Name"
  type = string
  default = "eks_vpc"
}
variable "vpc_cidr" {
    description = "IPv4 CIDR Block"
    type = string
    default = "10.0.0.0/16"
  
}
variable "vpc_tenancy" {
    type = string
    default = "default"
  
}
variable "tags" {
    type = map(string)
    default = {}
}
variable "vpc_dns" {
    type = bool
    default = "true"
  
}
variable "vpc_dns_hostname" {
    type = bool
    default = "true"
  
}
variable "aws_region" {
    type = string
    default = "ap-south-1"
}

variable "public_sg_rules" {
  type = list(object({
    type                    = string # "ingress" or "egress"
    from_port               = number
    to_port                 = number
    protocol                = string
    cidr_blocks             = optional(list(string), null)
    ipv6_cidr_blocks        = optional(list(string), null)
    source_security_group_id = optional(string, null) # For SG references
  }))
}
