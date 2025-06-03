# Adding documentation to resources:
The documentation for Infra Client resources resides at [chef-wed-docs repository](https://github.com/chef/chef-web-docs/).
Currently in order to reflect the documentation added to Infra Client resources on the [website](https://docs.chef.io/) we need to follow some manual steps.

# Prerequisite:
Clone [chef-wed-docs repository](https://github.com/chef/chef-web-docs/). Install Hugo, npm, go.

`brew tap go-swagger/go-swagger && brew install go-swagger hugo node go jq`

# Generating YAML files:
The YAML data is generated using a [rake](https://github.com/chef/chef/blob/main/tasks/docs.rb) task in the `chef/chef` repository.

`rake docs_site:resources`

The YAML files will be created under `docs_site` directory. Copy the corresponding file(s) for the resource(s) for which documentation is updated to [chef-web-docs/data/infra/resources](https://github.com/chef/chef-web-docs/tree/main/data/infra/resources).
(NOTE: The data file(.yaml) should be verified and edited manually to remove any inaccuracies.)

# Generating mark down(.md) files:
Go to the [chef-web-docs](https://github.com/chef/chef-web-docs/) repository, where we copied the YAML file(s).
Using the YAML file(s) create corresponding markdown(.md) file(s).

`hugo new -k resource content/resources/RESOURCE_NAME.md`

# Verifying changes locally:
Run server locally and verify the changes in your browser at http://localhost:1313

`make serve`

Once changes are verified, create a PR at [chef-web-docs](https://github.com/chef/chef-web-docs/) repository.
