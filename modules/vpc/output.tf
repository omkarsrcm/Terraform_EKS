output "aws_availability_zones" {
  value = local.azs
}
output "vpc_id" {
  value = aws_vpc.main.id
}
output "control_plane_subnets_ids" {
  value = [for ids in aws_subnet.control_plane_subnets: ids.id]
}
output "public_subnets_ids" {
  value = [for ids in aws_subnet.public_subnets: ids.id]
}
output "private_subnets_ids" {
  value = [for ids in aws_subnet.private_subnets: ids.id]
}

output "private_subnets_cidr_range" {
  value = local.private_subnets
}
output "public_subnets_cidr_range" {
  value = local.public_subnets
}
output "control_plane_cidr_range" {
  value = local.control_plane_subnets
}
output "private_subnets_sg_id" {
  value = [aws_security_group.private_sg.id]
}

