<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### chef-client -j JSON
Add to the [description of chef-client options](https://docs.chef.io/ctl_chef_client.html#options):

> This option can also be used to set a node's `chef_environment`. For example,
running `chef-client -j /path/to/file.json` where `/path/to/file.json` is
similar to:
```
{
  "chef_environment": "pre-production"
}
```
will set the node's environment to `"pre-production"`.

> *Note that the environment specified by `chef_environment` in your JSON will
take precedence over an environment specified by `-E ENVIROMENT` when both options
are provided.*
