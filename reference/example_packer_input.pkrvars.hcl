#=======================================#
#   Supported Packer Input Variables    #
#=======================================#


#---Tag vars---
env                   = "dev"                             # Project Environment name to tag final AMI
project               = "demo"                            # Project name to tag final AMI
project_type          = "app"                             # Project type to tag final AMI
os_version            = "Amazon_Linux_2"                  # OS name/version to tag final AMI
extra_tags = {                                            # (optional) Extra tags for final AMI
    do_not_delete = "yes"
    auto_delete   = "true"
}


#---Script vars---
os_patch              = "run"                             # Update packages with 'yum -y update'. Allowed values are "run" or "skip"
bootstrap             = "run"                             # Run bootstrap script. Allowed values are "run" or "skip"
run_ansible_playbook  = true                              # Run ansible playbook from this folder. Allowed values are true or false
include_script        = "script1.sh"                      # (optional) Name of shell script in this folder to run after Ansible
ami_patch             = true                              # (optional) Include the files inside "projects/<env>/<project>/<type>/ami_patch" folder and add name suffix "-patched" on ami name.

#---AMI vars---
ssh_username          = "ec2-user"                        # Default ssh username of the OS
instance_type         = "t3.small"                        # Instance type to create for  packer execution
region                = "us-east-1"                       # Region to run packer and create final AMI
regions_to_copy_ami   = ["us-east-1"]                     # (optional) Regions to copy the final AMI
vpc_id                = "vpc-123"                         # (optional) Required when you do not have a 'default' VPC
public_subnet_id      = "subnet-123"                      # (optional) Required when you do not have a 'default' VPC
source_ami_id         = "ami-123456"                      # Source AMI ID of the selected OS. Can be skipped if 'source_ami_filter' is defined
kms_key_id            = "c343kak-kfdsak"                  # (optional) Required when you need to specify the customer managed key id, recommend is to keep the Default value, change in value may caused the execution of atlantis plan/apply
encrypt_boot          = "true"                            # Encrypt/unecrypt the ebs volume. Allowed values are true or false

source_ami_filter     = [                                 # (optional) Get AMI ID using filter. Can be skipped if 'source_ami_id' is defined
 {
    virtualization-type = "hvm"
    root-device-type    = "ebs"
    name                = "project-project_type-env-region-Amazon_Linux_2-AMI-*"    # Existing AMI's name
    owners              = ["12345"]                                                 # AWS account ID of the AMI owner
    most_recent         = true                                                      # Fetch latest AMI id from the AMIs which have the same name
  }
]

extra_ebs_volumes = [                                     # (optional) Create, attach and mount extra EBS volumes to AMI. Volumes are mounted on /mnt/drive_<number>. Eg: Two additional volumes will be mounted as /mnt/drive_1 and /mnt/drive_2
  {
    device_name           = "/dev/sdb"                    # IMPORTANT: Do not provide "/dev/sda1" and "/dev/xvda". See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
    volume_size           = "10"
    volume_type           = "gp3"
    delete_on_termination = true
  },
  {
    device_name           = "/dev/sdc"
    volume_size           = "10"
    volume_type           = "gp3"
    delete_on_termination = true
  }
]


