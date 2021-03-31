+++
title = "chef-apply (executable)"
draft = false

gh_repo = "chef-workstation"

aliases = ["/ctl_chef_apply.html", "/ctl_chef_apply/"]

[menu]
  [menu.workstation]
    title = "chef-apply (executable)"
    identifier = "chef_workstation/chef_workstation_tools/ctl_chef_apply.md chef-apply (executable)"
    parent = "chef_workstation/chef_workstation_tools"
    weight = 30
+++

chef-apply is an executable program that runs a single recipe from the
command line:

- Is part of Chef Workstation
- A great way to explore resources
- Is **NOT** how Chef is run in production

## Options

This command has the following syntax:

``` bash
chef-apply name_of_recipe.rb
```

This tool has the following options:

`-e RECIPE_TEXT`, `--execute RECIPE_TEXT`

: Execute a resource using a string.

`-l LEVEL`, `--log_level LEVEL`

: The level of logging to be stored in a log file.

`-s`, `--stdin`

: Execute a resource using standard input.

`-v`, `--version`

: The Chef Infra Client version.

`-W`, `--why-run`

: Run the executable in why-run mode, which is a type of Chef Infra Client run that does everything except modify the system. Use why-run mode to understand why Chef Infra Client makes the decisions that it makes and to learn more about the current and proposed state of the system.

`-h`, `--help`

: Show help for the command.

## Examples

**Run a recipe**

Run a recipe named `machinations.rb`:

``` bash
chef-apply machinations.rb
```

**Install Emacs**

Run:

``` bash
sudo chef-apply -e "package 'emacs'"
```

Returns:

``` bash
Recipe: (chef-apply cookbook)::(chef-apply recipe)
  * package[emacs] action install
    - install version 23.1-25.el6 of package emacs
```

**Install nano**

Run:

``` bash
sudo chef-apply -e "package 'nano'"
```

Returns:

``` bash
Recipe: (chef-apply cookbook)::(chef-apply recipe)
  * package[nano] action install
    - install version 2.0.9-7.el6 of package nano
```

**Install vim**

Run:

``` bash
sudo chef-apply -e "package 'vim'"
```

Returns:

``` bash
Recipe: (chef-apply cookbook)::(chef-apply recipe)
  * package[vim] action install
    - install version 7.2.411-1.8.el6 of package vim-enhanced
```

**Rerun a recipe**

Run:

``` bash
sudo chef-apply -e "package 'vim'"
```

Returns:

``` bash
Recipe: (chef-apply cookbook)::(chef-apply recipe)
  * package[vim] action install (up to date)
```
