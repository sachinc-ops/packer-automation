locals {
  # Directory Vars
  default_var_dir     = format("projects/%s/%s/%s", var.env, var.project, var.project_type)
  ami_patch_dir       = "${local.default_var_dir}/ami_patch"
  var_dir             = var.ami_patch != false ? local.ami_patch_dir : local.default_var_dir
  dummy_script_dir    = "scripts/dummy"
  shell_scripts_path  = "scripts/shell_scripts"

  # SHELL Vars
  skip_shell          = "${local.dummy_script_dir}/skip-shell.sh"
  ebs_mount_input     = var.extra_ebs_volumes != [] ? "run" : "skip"
  include_script      = var.include_script != "" ? format("${local.var_dir}/%s", var.include_script) : local.skip_shell

  # ANSIBLE Vars
  default_ansible_file_name = "ansible.yaml"
  ansible_playbook          = var.run_ansible_playbook != false ? "${local.var_dir}/${local.default_ansible_file_name}" : "${local.dummy_script_dir}/skip-ansible.yaml"
  pause_time                = var.bootstrap != "run" ? "0s" : "20s"

  # AMI Vars
  name_suffix         = var.ami_patch != false ? "patched" : ""
  ami_name            = trimsuffix("${var.project}-${var.project_type}-${var.env}-${var.region}-${var.os_version}-AMI-{{isotime \"02-01-2006\"}}-${local.name_suffix}", "-")
  source_ami_filter   = var.source_ami_id != "" ? [] : var.source_ami_filter
  ami_regions         = try(var.regions_to_copy_ami, var.region)
  standard_tags = {
    owner      = var.owner
    Name       = local.ami_name
    prj        = var.project
    cst        = var.project
    env        = var.env
    OS_Version = var.os_version
  }
  ami_tags = merge(local.standard_tags, var.extra_tags)
}

source "amazon-ebs" "ami" {
  ami_name                    = local.ami_name
  ami_regions                 = local.ami_regions
  source_ami                  = var.source_ami_id
  subnet_id                   = var.public_subnet_id
  vpc_id                      = var.vpc_id
  instance_type               = var.instance_type
  region                      = var.region
  ssh_username                = var.ssh_username
  communicator                = "ssh"
  associate_public_ip_address = "true"
  kms_key_id                  = var.kms_key_id
  encrypt_boot                = var.encrypt_boot

  dynamic "launch_block_device_mappings" {
    for_each = var.extra_ebs_volumes
    content {
      device_name           = launch_block_device_mappings.value.device_name
      volume_size           = launch_block_device_mappings.value.volume_size
      volume_type           = launch_block_device_mappings.value.volume_type
      delete_on_termination = launch_block_device_mappings.value.delete_on_termination
    }
  }

  dynamic "source_ami_filter" {
    for_each = try(local.source_ami_filter, [])
    content {
      filters = {
        virtualization-type = source_ami_filter.value.virtualization-type
        name                = source_ami_filter.value.name
        root-device-type    = source_ami_filter.value.root-device-type
      }
      owners      = source_ami_filter.value.owners
      most_recent = source_ami_filter.value.most_recent
    }
  }

  dynamic "tag" {
    for_each = local.ami_tags
    content {
      key   = tag.key
      value = tag.value
    }
  }
}

build {
  name    = "base-ami-build"
  sources = ["source.amazon-ebs.ami"]

  provisioner "shell" {
    environment_vars = ["INPUT=${local.ebs_mount_input}"]
    script           = "${local.shell_scripts_path}/ebs-mount.sh"
  }

  provisioner "shell" {
    environment_vars = ["INPUT=${var.os_patch}"]
    script           = "${local.shell_scripts_path}/os-patch.sh"
  }

  provisioner "shell" {
    environment_vars  = ["INPUT=${var.bootstrap}"]
    expect_disconnect = true
    script            = "${local.shell_scripts_path}/bootstrap.sh"
  }

  provisioner "ansible" {
    ansible_env_vars = ["ANSIBLE_CONFIG=./ansible.cfg"]
    user             = var.ssh_username
    playbook_file    = local.ansible_playbook
    extra_arguments  = ["-v"]
    pause_before     = local.pause_time
  }

  provisioner "shell" {
    environment_vars = ["INPUT=include_script"]
    script           = local.include_script
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    script = "${local.shell_scripts_path}/post-processor.sh"
  }

}
