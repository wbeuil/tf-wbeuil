terraform {
  backend "s3" {
    bucket  = "wbeuil-tf-backend"
    key     = "plausible/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "will"
  default_tags {
    tags = local.tags
  }
}

locals {
  ami = "ami-0b3e57ee3b63dd76b"
  tags = {
    Name      = "plausible"
    Terraform = true
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_default_route_table" "rt" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
}

resource "aws_route" "r" {
  route_table_id         = aws_default_route_table.rt.id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_default_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "i_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP"
  security_group_id = aws_default_security_group.sg.id
}

resource "aws_security_group_rule" "i_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS"
  security_group_id = aws_default_security_group.sg.id
}

resource "aws_security_group_rule" "e_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All protocols"
  security_group_id = aws_default_security_group.sg.id
}

resource "aws_instance" "instance" {
  ami                         = local.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet.id
  associate_public_ip_address = true
  key_name                    = "plausible"
  user_data                   = file("script.sh")
  disable_api_termination     = true
  metadata_options {
    http_endpoint = "disabled"
  }
  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = false
    tags                  = local.tags
  }
}