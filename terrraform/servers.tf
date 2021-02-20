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

resource "hcloud_server" "kubenode1" {
  name        = "kubenode1"
  server_type = "cx11"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.xpsgamewsl.id]
  user_data = <<-EOF
		#! /bin/bash
    sudo apt-get update
		sudo apt install curl wget -y
    sudo adduser serveruser -m
    sudo mkdir /home/serveruser/.ssh
    sudo cp /root/.ssh/authorized_keys /home/amritanshu/.ssh/
    sudo chown -R serveruser:serveruser /home/amritanshu/.ssh
    sudo chmod 700 /home/amritanshu/.ssh
    sudo chmod 600 /home/amritanshu/authorized_keys
    curl https://get.docker.com | sudo sh
    sudo usermod -aG sudo serveruser
    sudo usermod -aG docker serveruser
    echo -e "\nserveruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
		echo "<h1>Deployed via Terraform</h1>" | sudo tee ~/bootstrap.log
EOF
  network {
      network_id = hcloud_network.network.id
      ip         = "10.15.1.5"
  }

  # **Note**: the depends_on is important when directly attaching the
  # server to a network. Otherwise Terraform will attempt to create
  # server and sub-network in parallel. This may result in the server
  # creation failing randomly.
  depends_on = [
    hcloud_network_subnet.amritanshu_in_network_subnet
  ]
}
