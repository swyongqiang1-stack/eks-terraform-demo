output "subnet_list" {
  value = var.subnet
}

output "vpc_id" {
  value = aws_vpc.main.id
}
