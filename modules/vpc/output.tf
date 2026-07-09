output "vpc_id" {
    value = aws_vpc.main.id
}

output "vpc_cidr_block" {
    value = aws_vpc.main.cidr_block
}

output "subnet" {
    value = [aws_subnet.a.id, aws_subnet.b.id]
}