resource "hcloud_ssh_key" "xpsgamewsl" {
  name       = "Terraform key on XPSGAME on WSL"
  public_key = file("src/terraformsshkey.pub")
}
