resource "aws_internet_gateway" "proxy" {
  vpc_id = module.aws_networking.vpc_id

  tags = {
    Name        = "confluent-pni-proxy-igw"
    Confluent   = "true"
    Environment = var.environment_name
  }
}

resource "aws_subnet" "proxy_public" {
  vpc_id = module.aws_networking.vpc_id

  cidr_block        = "10.50.0.192/28"
  availability_zone = "ap-south-1a"

  map_public_ip_on_launch = true

  tags = {
    Name        = "confluent-pni-proxy-public"
    Confluent   = "true"
    Environment = var.environment_name
  }
}

resource "aws_route_table" "proxy_public" {
  vpc_id = module.aws_networking.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proxy.id
  }

  tags = {
    Name        = "confluent-pni-proxy-public"
    Confluent   = "true"
    Environment = var.environment_name
  }
}

resource "aws_route_table_association" "proxy_public" {
  subnet_id      = aws_subnet.proxy_public.id
  route_table_id = aws_route_table.proxy_public.id
}
