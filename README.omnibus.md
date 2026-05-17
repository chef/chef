# Building Chef Infra with Omnibus

## Overview

The `omnibus/` directory in this repository is a Git submodule that points to a **private** configuration repository (`chef/chef-18-omnibus-config`). This private repo is used internally by the Chef team for official release builds and is not accessible to community contributors.

## For Community Contributors

If you want to build Chef Infra packages using Omnibus, substitute the private submodule with the public community configuration:

**[https://github.com/chef/chef-omnibus-community-config](https://github.com/chef/chef-omnibus-community-config)**

### Steps to Use the Community Config

1. **Remove the existing submodule** (if already initialized):

   ```bash
   git submodule deinit -f omnibus
   git rm -f omnibus
   rm -rf .git/modules/omnibus
   ```

2. **Clone the community config in its place**:

   ```bash
   git clone https://github.com/chef/chef-omnibus-community-config.git omnibus
   ```

3. **Install Omnibus dependencies and build**:

   ```bash
   cd omnibus
   bundle install
   bundle exec omnibus build chef
   ```

   Built packages will be placed in `omnibus/pkg/`.

### Notes

- The community config repo targets the same Chef Infra source but may lag slightly behind the internal build config used for official releases.
- If you encounter issues with the community config, please open an issue at [chef/chef-omnibus-community-config](https://github.com/chef/chef-omnibus-community-config/issues).
- Official release packages are available at [downloads.chef.io](https://www.chef.io/downloads).

## For Chef Team Members

The `omnibus/` submodule is pinned to `chef/chef-18-omnibus-config` (branch `chef-18`). To initialize it:

```bash
git submodule update --init omnibus
```
