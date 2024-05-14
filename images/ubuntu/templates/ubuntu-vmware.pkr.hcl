locals {
  managed_image_name = var.managed_image_name != "" ? var.managed_image_name : "packer-${var.image_os}-${var.image_version}"
}

variable "managed_image_name" {
  type    = string
  default = ""
}

variable "image_os" {
  type    = string
  default = "ubuntu22"
}

variable "image_version" {
  type    = string
  default = "latest"
}

variable "vsphere_server" {
  type    = string
  default = "vcenter.c13.data4life.care"
}

variable "vsphere_user" {
  type    = string
  default = "david.weese@data4life.care"
}

variable "vsphere_password" {
  type      = string
  default   = "yurn6KLIS1ghoy_druc"
  sensitive = true
}

variable "vsphere_datacenter" {
  type    = string
  default = "Datacenter"
}

variable "vsphere_cluster" {
  type    = string
  default = "10.198.90.13"
}

variable "vsphere_datastore" {
  type    = string
  default = "esx3-HDD-R10"
}

variable "vsphere_network" {
  type    = string
  default = "Infra"
}

variable "vm_name" {
  type    = string
  default = "packer-vm-ubuntu22-latest-runner"
}

source "vsphere-clone" "example_clone" {
  communicator        = "none"
  // host                = "esxi-1.vsphere65.test"
  // host                = var.vsphere_cluster
  insecure_connection = "true"
  password            = var.vsphere_password
  template            = "Github Runners/linux-ubuntu-22.04-lts-v23.11.ova"
  username            = var.vsphere_user
  vcenter_server      = var.vsphere_server
  vm_name             = var.vm_name

  // Virtual Machine Settings
  // guest_os_type       = "ubuntu64Guest"
  datacenter          = var.vsphere_datacenter
  cluster             = var.vsphere_cluster
  datastore           = var.vsphere_datastore
  network             = var.vsphere_network
  convert_to_template = true

  // firmware             = var.vm_firmware
  // CPUs                 = var.vm_cpu_count
  // cpu_cores            = var.vm_cpu_cores
  // CPU_hot_plug         = var.vm_cpu_hot_add
  // RAM                  = var.vm_mem_size
  // RAM_hot_plug         = var.vm_mem_hot_add
  // cdrom_type           = var.vm_cdrom_type
  // disk_controller_type = var.vm_disk_controller_type
  // storage {
  //   disk_size             = var.vm_disk_size
  //   disk_thin_provisioned = var.vm_disk_thin_provisioned
  // }
  // network_adapters {
  //   network      = var.vsphere_network
  //   network_card = var.vm_network_card
  // }

  content_library_destination {
    library = "Github Runners"
    name = "github-runner-ubuntu22-latest"
    ovf = "true"
    destroy = "true"
  }
  ssh_username = "rainpole"
  ssh_password = "R@in!$aG00dThing."
}

// source "vsphere-iso" "ubuntu" {
//   vcenter_server      = var.vsphere_server
//   username            = var.vsphere_user
//   password            = var.vsphere_password
//   insecure_connection = "true"

//   vm_name             = var.vm_name
//   datacenter          = var.vsphere_datacenter
//   cluster             = var.vsphere_cluster
//   datastore           = var.vsphere_datastore
//   network             = var.vsphere_network
//   convert_to_template = true

//   guest_os_type       = "ubuntu64Guest"
//   ISO_urls            = ["http://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"]
//   ISO_checksum        = "sha256:YOUR_ISO_CHECKSUM"

//   boot_command = [
//     "<enter><wait>",
//     "linux /casper/vmlinuz --- autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ <enter>"
//   ]

//   ssh_username = "ubuntu"
//   ssh_password = "your-ssh-password"
// }

build {
  sources = ["source.vsphere-clone.example_clone"]

  // Add your provisioners here
}
