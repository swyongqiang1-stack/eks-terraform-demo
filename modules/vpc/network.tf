resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet[0]
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Main"
  }
}



resource "aws_route_table" "a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }



  tags = {
    Name = "a_route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.a.id
  route_table_id = aws_route_table.a.id
}




resource "aws_subnet" "b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet[1]
  map_public_ip_on_launch = true

  availability_zone = "ap-southeast-1b"
  tags = {
    Name = "Main"
  }
}


resource "aws_route_table" "b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }



  tags = {
    Name = "b_route_table"
  }
}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.b.id
  route_table_id = aws_route_table.b.id
}
