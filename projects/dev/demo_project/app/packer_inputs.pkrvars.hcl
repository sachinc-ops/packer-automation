#---Tag vars---
env                   = "dev"
project               = "demo_project"
project_type          = "app"
os_version            = "Amazon-Linux-2"

#---AMI vars---
ssh_username          = "ec2-user"
instance_type         = "t3.small"
region                = "us-east-1"
regions_to_copy_ami   = ["us-east-1"]
source_ami_id         = "ami-0c02fb55956c7d316"
encrypt_boot          = "false"
extra_ebs_volumes = [
  {
    device_name           = "/dev/sdf"
    volume_size           = "50"
    volume_type           = "gp3"
    delete_on_termination = true
  }
]

#---Script vars---
os_patch              = "skip"
bootstrap             = "skip"
run_ansible_playbook  = true
