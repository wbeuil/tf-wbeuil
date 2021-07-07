terraform {
  backend "s3" {
    bucket  = "wbeuil-tf-backend"
    key     = "vitals/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.3.3"
    }
  }
}

provider "vultr" {}

data "vultr_region" "region" {
  filter {
    name   = "city"
    values = ["Paris"]
  }
}

data "vultr_os" "os" {
  filter {
    name   = "name"
    values = ["Ubuntu 21.04 x64"]
  }
}

data "vultr_plan" "plan" {
  filter {
    name   = "monthly_cost"
    values = ["5"]
  }
  filter {
    name   = "ram"
    values = ["1024"]
  }
}

resource "vultr_ssh_key" "key" {
  name    = "Vitals"
  ssh_key = chomp(file("~/.ssh/vitals_id_ed25519.pub"))
}

resource "vultr_startup_script" "script" {
  name   = "Grafana Setup"
  script = filebase64("script.sh")
}

resource "vultr_firewall_group" "firewall_group" {
  description = "Vitals Firewall"
}

resource "vultr_firewall_rule" "http_rule" {
  firewall_group_id = vultr_firewall_group.firewall_group.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "80"
  notes             = "HTTP"
}

resource "vultr_firewall_rule" "https_rule" {
  firewall_group_id = vultr_firewall_group.firewall_group.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "443"
  notes             = "HTTPS"
}

resource "vultr_instance" "vitals" {
  label             = "Vitals"
  tag               = "Terraform"
  region            = data.vultr_region.region.id
  plan              = data.vultr_plan.plan.id
  os_id             = data.vultr_os.os.id
  ssh_key_ids       = [vultr_ssh_key.key.id]
  script_id         = vultr_startup_script.script.id
  firewall_group_id = vultr_firewall_group.firewall_group.id
}