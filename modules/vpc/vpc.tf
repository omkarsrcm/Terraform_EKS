##########################################################################
# Information

# List can be know from [],And have duplicate values,reading via index no
# Map can be know from {},Key and value pair,Keys need to be unqiue.reading via keys and not using index no
# Sets can be know from toset([]), Only unqiue values,No indexing to read values.Use function like contains
# Objects({}) used for structured data stored in key:values.But we need to mention specific type for each field.But in map we dont need to
# cidrsubnet function used to divide and create subnet from vpc cidr
# slice function is used to fetch values between mentioned start and end index.value of end index no is not considerd.
# for_each fun used to create multiple resources works with list,map,sets.Applies direclty to resources
# element fun return single element from list.
# index fun return index of element from a list.
# Merge function used to combine mutiple sets of map into one
# dynamic fun like here is list of things go and create block for each item in list.It write repetitive part for us with different value.
# concat fun used to join two or more list into single.
# values fun used to fetch from values from map 

##########################################################################
# Data Sources
##########################################################################
data "aws_availability_zones" "aws_az" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

##########################################################################
# Local values
##########################################################################
locals {
 azs = slice(data.aws_availability_zones.aws_az.names,0,3)
 #[az1,az2,az3]
 private_subnets = [for k,v in local.azs : cidrsubnet(var.vpc_cidr, 4 ,k)]                # subnet cidr range calculator.Create list type variable.
 public_subnets = [for k,v in local.azs : cidrsubnet(var.vpc_cidr, 8 ,k + 48)]            # 48 is used so we dont overlap with private subnet cidr.Create list type variable.
 control_plane_subnets = [for k,v in local.azs : cidrsubnet(var.vpc_cidr, 8 ,k + 51)]            # 48 is used so we dont overlap with private subnet cidr.Create list type variable.
 #[192.1681.1.1,192.1681.1.2,192.1681.1.3]
}

##########################################################################
# VPC
##########################################################################
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  instance_tenancy = var.vpc_tenancy
  enable_dns_support= var.vpc_dns
  enable_dns_hostnames = var.vpc_dns_hostname
  tags = merge(                                       
                {"Name" = var.vpc_name},
                var.tags,
    )
}
##########################################################################
# controlplane,private subnets and public subnets.
##########################################################################

resource "aws_subnet" "control_plane_subnets" {
    vpc_id = aws_vpc.main.id
    for_each = toset(local.control_plane_subnets)                                                                # for_each only works with set and maps.So we convert local.private_subnets from list to set.And internally 
    availability_zone  = element(local.azs, index(local.control_plane_subnets, each.value) % length(local.azs))  # this used even incase the lenght of az and subnets different still they would get the azs
    cidr_block = each.value                                                                                      # for_each coverted this info to map.So cidr range become key and values are subnet attributes
    tags = merge(
                   {Name = "eks_control_plane_subnet_${index(local.control_plane_subnets, each.value)}"},
                   var.tags
    )

}
resource "aws_subnet" "private_subnets" {
    vpc_id = aws_vpc.main.id
    availability_zone  = element(local.azs, index(local.private_subnets, each.value) % length(local.azs))  # this used even incase the lenght of az and subnets different still they would get the azs
    for_each = toset(local.private_subnets)                                                                # for_each only works with set and maps.So we convert local.private_subnets from list to set.And internally
    cidr_block = each.value                                                                                # for_each coverted this info to map.So cidr range become key and values are subnet attributes
    tags = merge(
                   {Name = "eks_private_subnet_${index(local.private_subnets, each.value)}"},
                   {"kubernetes.io/role/internal-elb" = "1"},
                   var.tags
    )

}

resource "aws_subnet" "public_subnets" {
    vpc_id = aws_vpc.main.id
    map_public_ip_on_launch = true
    availability_zone  = element(local.azs, index(local.public_subnets, each.value) % length(local.azs))  # this used even incase the lenght of az and subnets different still they would get the azs
    for_each = toset(local.public_subnets)                                                                # for_each only works with set and maps.So we convert local.private_subnets from list to set.And internally
    cidr_block = each.value                                                                               # for_each coverted this info to map.So cidr range become key and values are subnet attributes
    tags = merge(
                   {Name = "eks_public_subnet_${index(local.public_subnets, each.value)}"},
                   {"kubernetes.io/role/elb" = "1"},
                   var.tags
    )

}

##########################################################################
# Tagging default route table,
# Create custom control plane,private and public route tables,And subnet assocation.
##########################################################################

resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags = merge(
                {"Name" = "${var.vpc_name}_default__rt"},
                    var.tags
  )
}

resource "aws_route_table" "control_plane_route" {
  vpc_id = aws_vpc.main.id
  tags = merge(
                    {"Name" = "${var.vpc_name}_control_plane_rt"},
                    var.tags
  )

}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id
  route {
              cidr_block = "0.0.0.0/0"
              nat_gateway_id = aws_nat_gateway.natgw.id
  }
  tags = merge(
                    {"Name" = "${var.vpc_name}_private_rt"},
                    var.tags
  )
  depends_on = [ aws_nat_gateway.natgw ]
}

resource "aws_route_table" "public_route" {
    vpc_id = aws_vpc.main.id
    route {
              cidr_block = "0.0.0.0/0"
              gateway_id = aws_internet_gateway.ingw.id
          }
    tags = merge(
                    {"Name" = "${var.vpc_name}_public_rt"},
                    var.tags
    )
    depends_on = [ aws_internet_gateway.ingw ]
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each = aws_subnet.public_subnets                                                                          # Since aws_subnet.public_subnets is map.We will use for_each loop
  subnet_id = each.value.id                                                                                     # id is the key inside.List like map of map 
  route_table_id = aws_route_table.public_route.id
  depends_on = [ aws_route_table.public_route ]
}

resource "aws_route_table_association" "private_route_table_association" {
  for_each = aws_subnet.private_subnets                                                                         # Since aws_subnet.private_subnets is map.We will use for_each loop
  subnet_id = each.value.id                                                                                     # id is the key inside.List like map of map 
  route_table_id = aws_route_table.private_route.id
  depends_on = [ aws_route_table.private_route ]
}

resource "aws_route_table_association" "controlplane_route_table_association" {
  for_each = aws_subnet.control_plane_subnets                                                                    # Since aws_subnet.private_subnets is map.We will use for_each loop
  subnet_id = each.value.id                                                                                      # id is the key inside.List like map of map 
  route_table_id = aws_route_table.control_plane_route.id
  depends_on = [ aws_route_table.control_plane_route ]
}
##########################################################################
# INGW
##########################################################################
resource "aws_internet_gateway" "ingw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
                    {"Name" = "${var.vpc_name}_ingw"},
                    var.tags
  )
  depends_on = [ aws_vpc.main ]
}

##########################################################################
# NAT Gateway And EIP
##########################################################################
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = element([for ids in aws_subnet.public_subnets: ids.id],0)

  tags = merge(
                    {"Name" = "${var.vpc_name}_natgw"},
                    var.tags
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ingw,aws_subnet.public_subnets]
}

resource "aws_eip" "natgw_eip" {
  public_ipv4_pool = "amazon"
  domain = "vpc"

  tags = merge(
                  {"Name"= "${var.vpc_name}_natgw_eip"},
                  var.tags
  )
}

##########################################################################
# tag default nacl
# create custom nacl for public and private subnets.
##########################################################################

resource "aws_default_network_acl" "default_nacl" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  subnet_ids = concat([for subnet in aws_subnet.control_plane_subnets: subnet.id],[for subnet in aws_subnet.public_subnets: subnet.id],[for subnet in aws_subnet.private_subnets: subnet.id])
  ingress {
                protocol = -1
                rule_no = 100
                action = "allow"
                cidr_block = "0.0.0.0/0"
                from_port = "0"
                to_port = "0"
  } 
  egress {
                protocol = -1
                rule_no = 100
                action = "allow"
                cidr_block = "0.0.0.0/0"
                from_port = "0"
                to_port = "0"
  }             
    
  tags = merge(
                {"Name" = "${var.vpc_name}_default_nacl"},
                var.tags
    )
}

##########################################################################
# tag default sg
# create public sg ,public sg, controlplane sg.
# adding inbound and outbound rules
##########################################################################
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.main.id
  tags = merge(
                    {"Name" = "${var.vpc_name}_default_sg"},
                    var.tags
  )
}

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.main.id
  tags = merge(
                    {"Name" = "${var.vpc_name}_public_sg"},
                    var.tags
  )
  depends_on = [ aws_vpc.main ]
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id
  tags = merge(
                    {"Name" = "${var.vpc_name}_private_sg"},
                    var.tags
  )
  depends_on = [ aws_vpc.main ]
}
resource "aws_security_group_rule" "public_rules" {
  for_each = { for idx , rule in var.public_sg_rules:"${rule.type}-${rule.from_port}-${idx}" => rule}     # here since the info is in object we are basically creating map for A for_each. 
  type              = each.value.type                                                                          # ${rule.type}-${rule.from_port}-${idx} is basically creating unquie keys and anythin after => is value for the key
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.public_sg.id

  # Conditional assignment to avoid conflict
  cidr_blocks             = each.value.cidr_blocks != null ? each.value.cidr_blocks : null
  ipv6_cidr_blocks        = each.value.ipv6_cidr_blocks != null ? each.value.ipv6_cidr_blocks : null
  source_security_group_id = each.value.source_security_group_id != null ? each.value.source_security_group_id : null
  depends_on = [ aws_security_group.public_sg ]

}

