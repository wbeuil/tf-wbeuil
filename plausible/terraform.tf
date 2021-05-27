terraform {
  backend "s3" {
    bucket = "wbeuil-tf-backend"
    key    = "plausible/terraform.tfstate"
    region = "eu-west-3"
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "will"
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
  tags       = local.tags
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  tags       = local.tags
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.tags
}

resource "aws_default_route_table" "rt" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  tags                   = local.tags
}

resource "aws_route" "r" {
  route_table_id         = aws_default_route_table.rt.id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_default_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.tags
}

resource "aws_security_group_rule" "i_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SSH"
  security_group_id = aws_default_security_group.sg.id
}

resource "aws_security_group_rule" "i_http" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP"
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
  tags                        = local.tags
}