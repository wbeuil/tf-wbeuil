terraform {
  backend "s3" {
    bucket  = "wbeuil-tf-backend"
    key     = "wbeuil.com/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "will"
  default_tags {
    tags = {
      Name      = "wbeuil.com"
      Terraform = true
    }
  }
}

resource "aws_s3_bucket" "backend_bucket" {
  bucket = "wbeuil-tf-backend"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_route53_zone" "wbeuil_zone" {
  name    = "wbeuil.com"
  comment = "Personal Website"
}

resource "aws_route53_record" "ns_records" {
  name            = "wbeuil.com"
  allow_overwrite = true
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.wbeuil_zone.zone_id
  records = [
    "ns1.vercel-dns.com",
    "ns2.vercel-dns.com"
  ]
}

resource "aws_route53_record" "a_record" {
  name    = "wbeuil.com"
  type    = "A"
  ttl     = 300
  zone_id = aws_route53_zone.wbeuil_zone.zone_id
  records = ["76.76.21.21"]
}

resource "aws_route53_record" "www_record" {
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  zone_id = aws_route53_zone.wbeuil_zone.zone_id
  records = ["cname.vercel-dns.com"]
}

resource "aws_route53_record" "gsv_record" {
  name    = "wbeuil.com"
  type    = "TXT"
  ttl     = 1800
  zone_id = aws_route53_zone.wbeuil_zone.zone_id
  records = ["google-site-verification=5frvSVU61KI556iqZnxfMPdz2ZZi2t22sCSPNUGBYVg"]
}

resource "aws_route53_record" "a_record_plausible" {
  name    = "analytics"
  type    = "A"
  ttl     = 300
  zone_id = aws_route53_zone.wbeuil_zone.zone_id
  records = ["13.36.170.166"]
}

resource "aws_route53_record" "a_record_vitals" {
  name    = "vitals"
  type    = "A"
  ttl     = 300
  zone_id = aws_route53_zone.wbeuil_zone.zone_id
  records = ["107.191.62.254"]
}