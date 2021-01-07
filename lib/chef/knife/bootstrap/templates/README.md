This directory contains bootstrap templates which can be used with the -d flag
to 'knife bootstrap' to install Chef in different ways. To simplify installation,
and reduce the matrix of common installation patterns to support, we have
standardized on the [Omnibus](https://github.com/chef/omnibus) built installation
packages.

The 'chef-full' template downloads a script which is used to determine the correct
Omnibus package for this system from the [Omnitruck](https://docs.chef.io/api_omnitruck/) API.

You can still utilize custom bootstrap templates on your system if your installation
needs are unique. Additional information can be found on the [docs site](https://docs.chef.io/knife_bootstrap/#custom-templates).
