# TAGS
variable "extra_tags" { default = {} }

# AMI
variable "os_version" {}
variable "ssh_username" {}
variable "source_ami_id" { default = "" }
variable "ami_patch" {
  type    = bool
  default = false
}
variable "kms_key_id" { default = "" }
variable "encrypt_boot" {}
variable "source_ami_filter" {
  type = list(object({
    virtualization-type = string
    name                = string
    root-device-type    = string
    owners              = list(string)
    most_recent         = bool
  }))
  default = []
}
variable "extra_ebs_volumes" {
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = string
    delete_on_termination = bool
  }))
  default = []
}

# AWS
variable "instance_type" {}
variable "region" {}
variable "regions_to_copy_ami" {}
variable "vpc_id" { default = "" }
variable "public_subnet_id" { default = "" }

# PROJECT
variable "env" {}
variable "project" {}
variable "project_type" {}
variable "owner" { default = "DevOps" }


# SHELL
variable "bootstrap" {
  type = string
  validation {
    condition     = contains(["run", "skip"], var.bootstrap)
    error_message = "Value of argument \"bootstrap\" must be either \"run\", or \"skip\"."
  }
}
variable "os_patch" {
  type = string
  validation {
    condition     = contains(["run", "skip"], var.os_patch)
    error_message = "Value of argument \"os_patch\" must be either \"run\", or \"skip\"."
  }
}
variable "include_script" {
  type    = string
  default = ""
}

# ANSIBLE
variable "run_ansible_playbook" { default = false }
