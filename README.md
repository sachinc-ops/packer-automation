## Packer AMI Automation
Using single Packer template we are automating the AWS EC2 linux image building process for multiple envs and projects which will make the AMI creation simple and uniform. 

## Workflow
Instance_creation > (ebs_mount) > (os_patch) > (bootstrap) > (Ansible_provisioning) > (extra_shell_scripts) > AMI_tagging

## Prerequisites

* [Packer](http://www.packer.io) CLI >= 1.7.2 installed
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) CLI >= 2.11 installed
* Authentication method configured to communicate to [AWS](https://www.packer.io/docs/builders/amazon#authentication)
* Get the source `ami_id`. See "reference" folder


## Usage

* Clone this repo
* If not exist,
  - Create project specific folder with format of `env/project_name/type/` inside `projects` folder.
  (Eg: `mkdir -p projects/dev/demo_project/app/`)
  - Create `packer_inputs.pkrvars.hcl` file inside the folder created in previous step.
* (Optional) 
  - Setup Ansible playbook with name `ansible.yaml` inside `projects/env/project_name/project_type/`
  - Setup a custom shell script file inside the same 'project_type' folder which will run after ansible execution.
* Define required packer variables in `packer_inputs.pkrvars.hcl`. See supported variables in reference folder
* Run bellow commands from the repository root path
  ### Option1 - Run using `packer-runner` script
  ```

  # Ensure that packer-runner script has executable permission
    chmod +x ./packer-runner

  # Validate the variables, template and ansible file
  ./packer-runner validate projects/<env>/<project>/<type>/

  NOTE: This warning can be ignored "Could not match supplied host pattern, ignoring: default"

  # Run backer Build
  ./packer-runner build projects/<env>/<project>/<type>/

  ```
  ### Option2 - Patch an existing AMI
  ```
  # create a folder named 'ami_patch' inside projects/<env>/<project>/<type>/
  mkdir projects/<env>/<project>/<type>/ami_patch
  
  # Add/Update the packer-var,ansible,shell script files accordingly

  # Validate the variables, template and ansible file
  ./packer-runner validate projects/<env>/<project>/<type>/ami_patch
  
  # Run packer build
  ./packer-runner build projects/<env>/<project>/<type>/ami_patch
  ```

  ### Debugging Manually
  ```

  # Validate the variables and template. Empty Output for Success
  packer validate -var-file="./projects/<env>/<project>/<type>/packer_inputs.pkrvars.hcl" .

  # Inspect the variables provided
  packer inspect -var-file="./projects/<env>/<project>/<type>/packer_inputs.pkrvars.hcl" .

  # Run backer Build
  packer build -color=false -debug -var-file="./projects/<env>/<project>/<type>/packer_inputs.pkrvars.hcl" .

  ```


## When the script can fail

* When the project folder structure (`projects/env/project_name/project_type/`) does not match with the values of `var.env`, `var.project` and `var.project_type`
  >Solution : Make sure the values are matching

* When you add an ansible-playbook with a custom name.(Eg: projects/dev/demo_project/app/my_playbook.yaml)
  >Solution : The playbook name should be `ansible.yaml`

* When you place ansible roles in custom locations.
  >Solution : Place the roles inside `scripts/ansible_roles/`
