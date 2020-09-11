terraform {
  required_providers {
    hetznerdns = {
      source = "registry.terraform.io/timohirt/hetznerdns"
      version = "1.1.0"
    }
  }
}

variable "node_count" {}

variable "domain" {}

variable "token" {}

variable "hostnames" {
  type = list
}

variable "public_ips" {
  type = list
}

provider "hetznerdns" {
  apitoken = var.token
}


resource "hetznerdns_zone" "selected_domain" {
  name = var.domain
  ttl = 300
}

resource "hetznerdns_record" "hosts" {
  count   = var.node_count
  zone_id = hetznerdns_zone.selected_domain.id
  name    = element(var.hostnames, count.index)
  value   = element(var.public_ips, count.index)
  type    = "A"
  ttl     = "300"

}

resource "hetznerdns_record" "domain" {
  zone_id = hetznerdns_zone.selected_domain.id

  name    = "@"
  type    = "A"
  ttl     = "300"
  value = element(var.public_ips, 0)
}

resource "hetznerdns_record" "wildcard" {
  depends_on = [hetznerdns_record.domain]

  zone_id = hetznerdns_zone.selected_domain.id
  name    = "*"
  type    = "CNAME"
  ttl     = "300"
  value   = "${hetznerdns_zone.selected_domain.name}."
}

output "domains" {
  value = "${hetznerdns_record.hosts.*.name}"
}
