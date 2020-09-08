variable "token" {}

variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = string
}

variable "location" {
  type = string
}

variable "type" {
  type = string
}

variable "image" {
  type = string
}

variable "ssh_keys" {
  type = list
}

provider "hcloud" {
  token = var.token
}

variable "apt_packages" {
  type    = list
  default = []
}

resource "hcloud_server" "host" {
  name        = format(var.hostname_format, count.index + 1)
  location    = var.location
  image       = var.image
  server_type = var.type
  ssh_keys    = var.ssh_keys

  count = var.hosts

  connection {
    user    = "root"
    type    = "ssh"
    timeout = "2m"
    host    = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get update",
      "apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

# resource "hcloud_volume" "volume" {
#   name      = format(var.hostname_format, count.index + 1)
#   size      = 10
#   server_id = element(hcloud_server.host.*.id, count.index)
#   automount = false

#   count = var.hosts
# }

resource "hcloud_network" "kubernetes" {
  name = "kubernetes"
  ip_range = "192.168.0.0/16"
}

resource "hcloud_network_subnet" "kubernetes" {
  network_id = hcloud_network.kubernetes.id
  type = "server"
  ip_range = "192.168.0.0/24"
  network_zone = "eu-central"
}

resource "hcloud_server_network" "privatenetwork" {
  count = var.hosts
  server_id = element(hcloud_server.host.*.id,count.index)
  subnet_id = hcloud_network_subnet.kubernetes.id
  ip = "192.168.0.${ count.index + 2}"
}

output "hostnames" {
  value = "${hcloud_server.host.*.name}"
}

output "public_ips" {
  value = "${hcloud_server.host.*.ipv4_address}"
}

output "private_ips" {
  value = "${hcloud_server_network.privatenetwork.*.ip}"
}

output "private_network_interface" {
  value = "enp7s0"
}
