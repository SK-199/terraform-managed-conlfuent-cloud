resource "aws_security_group" "proxy" {
  name        = "confluent-pni-proxy"
  description = "Security group for Confluent Cloud PNI proxy"
  vpc_id      = module.aws_networking.vpc_id

  ingress {
    description = "SSH from administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Confluent Console and REST proxy"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka proxy"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound internet and Confluent connectivity"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "confluent-pni-proxy"
    Confluent   = "true"
    Environment = var.environment_name
  }
}

resource "aws_instance" "proxy" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.proxy_public.id

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.proxy.id
  ]

  key_name = "sk-msk"

  tags = {
    Name        = "confluent-pni-proxy"
    Confluent   = "true"
    Environment = var.environment_name
    Purpose     = "NGINX private endpoint proxy"
  }
}
