### Running a cookbook as Habitat + Effortless package using policyfiles
The Effortless Config application uses the Policyfiles feature of Chef to encapsulate an application which runs chef-solo against a compiled Policyfile and the collection of cookbooks it needs.

Following directories will comprise the application:
  * cookbooks: This directory contains the cookbooks our application will run.
  * habitat: This directory contains the plan.sh and plan.ps1 files to build the habitat application for Effortless Config
  * policyfiles: This directory contains the chef Policyfiles that will control what Effortless Config runs and the attributes used to configure it

### Setting up Habitat
  * Install habitat as per steps given [here](https://docs.chef.io/habitat/install_habitat/)
  * Set up Origin and access token at habitat builder https://bldr.habitat.sh
    For additional details about Habitat builder refer [this](https://docs.chef.io/habitat/builder_overview/)
  * Set up Habitat CLI 
    `hab cli setup`
     For additional about Habitat CLI refer [this](https://docs.chef.io/habitat/hab_setup/)

### Generate chef-repo
Generate the cookbook repo using `chef generate repo REPO_NAME`
For more information on chef-repo generation refer doc [here](https://docs.chef.io/chef_repo/)
Once you are done creating your recipes, define the runlist inside a policy file under `policyfiles` directory of chef-repo e.g `policyfiles/base.rb`

### Create habitat plan
Navigate to the root of cookbook repo and run
`hab plan init`
It will create a new `habitat` sub-directory with a `plan.sh` (or `plan.ps1` on Windows), a `default.toml` file as well as `config` and `hooks` directories.

### Updating plan file
Since we are running the cookbook as Hab + Effortless package, we need let the plan file know what is the run list which will be used by Infra Client.
This can be done by setting following package configuration variables in the plan file:
```
$pkg_scaffolding="chef/scaffolding-chef-infra" # This pulls in latest Infra Client released from stable channel
$scaffold_policyfile_path="{path_to_your_policyfile_relative_to_plan_file}"  # e.g "$PLAN_CONTEXT/../policyfiles"
$scaffold_policy_name="{name_of_your_policyfile}"
```
If we want to run the cookbook with a specific version of Infra Client, set the following variable with corresponding version details:

`$scaffold_chef_client="chef/chef-infra-client/17.10.3/20220516153835"`

For more details about plan file configuration refer [here](https://docs.chef.io/habitat/plan_contents/)

### Build the package
The process for building the Effortless package is same as habitat package. 
Enter the hab studio to build the package and then load the service to run it. Since we have specified the run list and Infra Client version in the plan file, the cookbook will now run as an Effortless package
  * Enter hab studio 
    `hab studio enter`
  * Build the package.
    Note this name has to match your cookbook repo name
    `build {your_package_name}`
  * Run the package as service
    `hab svc load {your_origin}/{package_name}` 
  * See Supervisor logs
    `sup-log` # On linux
    `Get-SuperVisorLog` # On windows
  * Check status of Habitat services
    `hab svc status`
  * Stop a service
    `hab svc unload {your_origin}/{package_name}`
