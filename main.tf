terraform {
  backend "s3" {
    bucket = "ryo-terraform-state-20260430"
    key    = "study-aws-2/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
provider "aws" {
  region = "ap-northeast-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "study-aws-2-vpc"
  }
}

# -------------------------
# Public Subnets
# -------------------------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

# -------------------------
# Private Subnets
# -------------------------
resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

# -------------------------
# Internet Gateway
# -------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------
# NAT Gateway
# -------------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_app_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_app_nat" {
  route_table_id         = aws_route_table.private_app_rt.id
  nat_gateway_id         = aws_nat_gateway.nat.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_app_assoc" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private_app_rt.id
}

# -------------------------
# Security Groups
# -------------------------
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
}

# -------------------------
# RDS
# -------------------------
resource "aws_db_subnet_group" "db_subnet" {
  subnet_ids = [
    aws_subnet.private_db_1.id,
    aws_subnet.private_db_2.id
  ]
}

resource "aws_db_instance" "mysql" {
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "wordpress"
  username = var.db_user
  password = var.db_pass

  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
}

# -------------------------
# EC2 (WordPress)
# -------------------------
resource "aws_instance" "web" {
  ami           = "ami-0d52744d6551d851e"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.private_app_1.id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data_replace_on_change = true

  user_data = <<EOF
#!/bin/bash
apt update -y
apt install -y docker.io docker-compose
systemctl start docker
systemctl enable docker

mkdir -p /home/ubuntu/wp
cd /home/ubuntu/wp

cat > docker-compose.yml <<EOL
services:
  wordpress:
    image: wordpress
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: ${aws_db_instance.mysql.address}:3306
      WORDPRESS_DB_USER: ${var.db_user}
      WORDPRESS_DB_PASSWORD: ${var.db_pass}
      WORDPRESS_DB_NAME: wordpress
EOL

docker-compose up -d
EOF
}

# -------------------------
# ALB
# -------------------------
resource "aws_lb" "alb" {
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# -------------------------
# CloudFront（修正版）
# -------------------------
resource "aws_cloudfront_distribution" "wordpress" {
  enabled = true

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Forwarded-Proto"
      value = "https"
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "DELETE", "PATCH"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      # CloudFrontからALBへHostヘッダーを転送しない
      headers = ["CloudFront-Forwarded-Proto"]

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}