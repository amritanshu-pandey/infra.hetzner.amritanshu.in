variable "duckdns_token" {}

resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.15.0.0/16"
}

resource "hcloud_network_subnet" "amritanshu_in_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = "eu-central"
  ip_range     = "10.15.1.0/24"
}

resource "hcloud_server" "kubenode" {
  count       = 3 
  name        = "kubenode${count.index+1}"
  server_type = "cx11"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.xpsgamewsl.id]
  user_data = <<-EOF
		#! /bin/bash
    sudo apt-get update
		sudo apt install git ansible -y

    mkdir /tmp/bootstrap
    cd /tmp/bootstrap
    git clone https://github.com/amritanshu-pandey/infra.hetzner.amritanshu.in.git .
    cd ansible && ansible-playbook bootstrap.yml | tee ~/ansible.log
		echo "<h1>Deployed via Terraform</h1>" | sudo -u serveruser  tee ~/bootstrap.log
EOF
  network {
      network_id = hcloud_network.network.id
      ip         = "10.15.1.${count.index+10}"
  }

  # **Note**: the depends_on is important when directly attaching the
  # server to a network. Otherwise Terraform will attempt to create
  # server and sub-network in parallel. This may result in the server
  # creation failing randomly.
  depends_on = [
    hcloud_network_subnet.amritanshu_in_network_subnet
  ]
}

# resource "hcloud_floating_ip" "lb" {
#   type = "ipv4"
#   home_location = "nbg1"
# }

# resource "hcloud_floating_ip_assignment" "lb" {
#   floating_ip_id = hcloud_floating_ip.lb.id
#   server_id = hcloud_server.lb.id
# }

resource "hcloud_server" "rancheroolb" {
  name        = "rancheroolb"
  server_type = "cx11"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.xpsgamewsl.id]
  user_data = <<-EOF
		#! /bin/bash
    sudo apt-get update
		sudo apt install git ansible -y
 
    mkdir /tmp/bootstrap
    cd /tmp/bootstrap
    git clone https://github.com/amritanshu-pandey/infra.hetzner.amritanshu.in.git .
    cd ansible && ansible-playbook bootstrap.yml | tee ~/ansible.log

    # Update dns record for kubelb.duckdns.org
    echo url="https://www.duckdns.org/update?domains=kubelb&token=${var.duckdns_token}&ip=" | curl -k -o /var/log/duck.log -K -
		echo "<h1>Deployed via Terraform</h1>" | sudo -u serveruser  tee ~/bootstrap.log
EOF
  network {
      network_id = hcloud_network.network.id
      ip         = "10.15.1.1"
  }

  # **Note**: the depends_on is important when directly attaching the
  # server to a network. Otherwise Terraform will attempt to create
  # server and sub-network in parallel. This may result in the server
  # creation failing randomly.
  depends_on = [
    hcloud_network_subnet.amritanshu_in_network_subnet
  ]
}
