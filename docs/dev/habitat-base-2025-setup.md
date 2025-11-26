# Chef Infra Client 19 - Habitat base-2025 Channel Setup Guide

## Introduction

Chef Infra Client 19 is transitioning to Ruby 3.4.2, requiring all Chef Infra Client 19 builds to align with the new **'base-2025'** channel in Chef Habitat SaaS Builder ([bldr.habitat.sh](https://bldr.habitat.sh)).

### Impacted Builds

This change will affect the following builds for Chef Infra Client 19:

- `verify`
- `habitat build/test`
- `kitchen-tests`

### Key Requirement

Accessing the 'base-2025' channel in Chef Habitat Public Builder requires a `HAB_AUTH_TOKEN` linked to a valid License Key. This means:

- All builds utilizing the base-2025 channel must set the `HAB_AUTH_TOKEN` to function successfully
- Package downloads and installations from the base-2025 channel also require a `HAB_AUTH_TOKEN` with a valid License Key

This document outlines the process of obtaining a `HAB_AUTH_TOKEN` and configuring GitHub forks of the [chef/chef](https://github.com/chef/chef) repository.

---

## Getting a License Key

To access the base-2025 channel, you'll need a Chef License. For more details about Chef Licensing, visit [About Chef Licenses](https://docs.chef.io/licensing/).

### License Types

You'll need one of the following licenses:

- **Free license**
- **Trial license**
- **Commercial license**

### Provisioning Your License

Once you've provisioned a license, store it securely. Refer to the [Builder Profile documentation](https://docs.chef.io/habitat/builder_profile/#add-a-progress-chef-license-key) for instructions on adding your license key in Builder.

---

## Get a HAB_AUTH_TOKEN

All builds, including public OSS pipelines (except kitchen tests), will be configured to use the token, ensuring successful execution of Habitat builds.

For successful kitchen test runs, follow the steps below.

### Step 1: Provision a License Key

Follow the instructions in the [Getting a License Key](#getting-a-license-key) section above.

### Step 2: Configure Builder Profile Settings

1. **Access Habitat Builder**: Log in to [Habitat Builder](https://bldr.habitat.sh/)

2. **Navigate to Profile Settings**: Click on your builder profile and access profile settings

3. **Add the License Key**:
   - Scroll to the **License Key** section of the profile
   - Paste your generated license key
   - Click **Submit**

4. **Generate/Regenerate HAB_AUTH_TOKEN**:
   - In the same profile settings page, find the **"Personal Access Token"** section
   - Click to generate the token
   - **⚠️ IMPORTANT**: Save the token immediately - it will only be displayed once!
   - Store it securely for later use

![Builder Profile Settings](Screenshot 2025-06-18 at 1.08.44 PM.png)

### Step 3: Set the HAB_AUTH_TOKEN in Your Fork

If you are maintaining a fork of the Chef Infra Client repository ([chef/chef](https://github.com/chef/chef)), you need to set the `HAB_AUTH_TOKEN` as a repository secret.

1. **Navigate to Your Forked Repository** on GitHub

2. **Access Repository Secrets**:
   - Click on the **"Settings"** tab
   - Go to **"Secrets and Variables"**
   - Click on **"Actions"**
   - Click on **"New repository secret"**

   ![GitHub Settings Navigation](Screenshot 2025-07-22 at 5.52.35 PM.png)

3. **Add the Secret**:
   - Enter **"Name"** as: `HAB_AUTH_TOKEN`
   - Paste your generated token in the **"Secret"** field
   - Click **"Add secret"**

   ![Add Secret Form](Screenshot 2025-07-22 at 5.54.47 PM.png)

4. **Verify the Secret**:
   - Once added, you should see `HAB_AUTH_TOKEN` listed among your repository secrets

   ![Secret Confirmation](Screenshot 2025-07-22 at 6.01.35 PM.png)

### Step 4: Continue Contributing

Once the `HAB_AUTH_TOKEN` is configured, you can continue to contribute to the repository. The `verify` and `kitchen-tests` should run normally for all pull requests.

## Additional Resources

- [Chef Licensing Documentation](https://docs.chef.io/licensing/)
- [Habitat Builder Documentation](https://docs.chef.io/habitat/builder_overview/)
- [Habitat Builder Profile Settings](https://docs.chef.io/habitat/builder_profile/)
- [Chef Infra Client Repository](https://github.com/chef/chef)
