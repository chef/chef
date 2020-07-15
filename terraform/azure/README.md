# Chef Infra Project - Terraform

This directory contains the Terraform code used to enable Chef Infra developers the ability to launch ephemeral systems in different topology scenarios to enable integration test coverage.

## Pre-Requisites

### Ensure you can SSH without prompting for a passphrase

The test scenarios expect to be able to SSH directly into server instances without prompting for a passphrase.  This is most often accomplished by running an [SSH Agent](https://www.ssh.com/ssh/agent) with your private key loaded into it.  An alternative (albeit NOT recommended) approach would be to have a passphraseless SSH private key available at the default file system location (e.g. `$HOME/.ssh/id_rsa`).

### Ensure you have your SSH **public** key is saved to a file

The test scenarios require the `ARM_SSH_KEY_FILE` environment variable to be populated with the file system path to your SSH **public** key.

### Setting up your workstation to work with Azure (for Chef Software employees only)

1. Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
2. Log in to Azure using `az login`
3. Create a "service principal" for your user via `az ad sp create-for-rbac --name "$USER_service_principle"`

    ***NOTE:*** Make sure you capture the client ID and secret returned by this command.  You won't be able to retrieve the client secret in the future.

### Azure Resource Manager

Scenarios require that they are run against a compatible resource group.

You may generate a compatible resource group using the `ARM_DEPT=Eng ARM_CONTACT=csnapp make create-resource-group` command.

***NOTE:*** **There is no automatic reaping of the resource group.  Make sure you destroy your resource group using the** `ARM_DEPT=Eng ARM_CONTACT=csnapp make destroy-resource-group` **command once you are finished testing scenarios and ALL instances have been destroyed along with the Chef Server.**

### Chef Server

Once you have a resource group to work with you will need to create a Chef Server before you can execute any scenarios.

You may instantiate a compatible Chef Server using the `ARM_DEPT=Eng ARM_CONTACT=csnapp SERVER_VERSION=13.2.0 make create-chef-server` command.

***NOTE:*** **There is no automatic reaping of the Chef Server.  Make sure you destroy your Chef Server using the** `ARM_DEPT=Eng ARM_CONTACT=csnapp make destroy-chef-server` **command once you are finished testing scenarios and ALL instances have been destroyed.**

## Running a Scenario
Environment variables are used to control how the scenarios are executed and can either be passed on the command line before the `make` command or set in the shell's environment (e.g. `$HOME/.bashrc`)

### Required Environment Variables
| Environment Variable | Description | Example |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------|
| `ARM_CLIENT_ID` | The universally unique ID associated with your service principal. | 15d3cd8b-ac2a-5319-beef-616538deadee |
| `ARM_CLIENT_SECRET` | The secret token provided by Azure when you created your service principal | - |
| `ARM_DEPT` | Department that owns the resources should be one of: EngServ,  Operations, Eng, Training, Solutions, Sales, BD, Success or Partner | Eng |
| `ARM_CONTACT` | The primary contact for the resources, this should be the IAM username  and must be able to receive email by appending @chef.io to it (this  person can explain what/why, might not be the business owner) | csnapp |
| `ARM_SSH_KEY_FILE` | The file system path to your SSH **public** key. | ~/.ssh/id_rsa.pub |
| `SCENARIO` | The name of the sub-directory within `scenarios` containing the test you'd like to run. | omnibus-external-postgresql |
| `CLIENT_VERSION` | The version number of the Chef Infra artifact you want to test. | 16.2.73 |
| `SERVER_VERSION` | The version number of the Chef Server artifact you want to test against. | 13.2.0 |

### Optional Environment Variables
| Environment Variable | Description | Example |
|-----------------------------|-----------------------------------------------------------------------------------------------|--------------------------------------------|
| `ARM_TENANT_ID` | The name of the Azure tenant used to authenticate. | a2b2d6bc-afe1-4696-9c37-f97a7ac416d7 (default) |
| `ARM_SUBSCRIPTION_ID` | The Azure subscription used for billing. |  (default) |
| `ARM_DEFAULT_LOCATION` | Name of the Azure location to create instances in. | westus2 (default) |
| `ARM_DEFAULT_INSTANCE_TYPE` | The Azure instance type that determines the amount of resources server instances are allocated. | Standard_D2_v3 (default) |
| `WORKSTATION_PLATFORM` | The operating system used as the workstation to bootstrap instances from. | rhel-6, rhel-7, rhel-8, ubuntu-16.04, ubuntu-18.04, ubuntu-20.04, windows-2019, windows-10, windows-8 |
| `NODE_PLATFORMS` | A list of operating systems used as nodes to be bootstrapped. | rhel-6, rhel-7, rhel-8, ubuntu-16.04, ubuntu-18.04, ubuntu-20.04, windows-2019, windows-10, windows-8 |

### Scenario Lifecycle

The test scenarios are each defined in their own terraform directory and are selected by providing the scenario name via the `SCENARIO` environment variable.

An example of a typical scenario lifecycle might look like this:

1. `ARM_DEPT=Eng ARM_CONTACT=csnapp ARM_SSH_KEY_FILE=~/.ssh/id_rsa.pub SCENARIO=bootstrap WORKSTATION_PLATFORM=win10 NODE_PLATFORMS=ubuntu-20.04 CLIENT_VERSION=16.2.73 make apply`
2. Optionally, you may SSH into the scenario instances for troubleshooting.
3. `ARM_DEPT=Eng ARM_CONTACT=csnapp ARM_SSH_KEY_FILE=~/.ssh/id_rsa.pub SCENARIO=bootstrap WORKSTATION_PLATFORM=win10 NODE_PLATFORMS=ubuntu-20.04 CLIENT_VERSION=16.2.73 make destroy`

***NOTE:*** **There is no automatic reaping of the scenario.**

## Working with Active Scenarios

### List Active Scenarios

For terraform to track multiple concurrent scenarios it uses a concept called a `workspace`.

The `workspace` name is the combination of the following variables `${WORKSTATION_PLATFORM}:${SCENARIO}:${NODE_PLATFORMS}` (e.g. `ubuntu-20.04:bootstrap:win10`)

To get a list of the workspaces that are still active you may run the `make list-active-workspaces` command.

### Destroying Active Scenarios

To destroy all active scenarios you may run either the `make destroy-all` or `make clean` commands.

## Adding a new Scenario

1. Duplicate an existing scenario directory that is similar to the one you desire. For example, if you wanted to add a
   `knife` scenario, you could start with the `bootstrap` scenario file. 
2. Update the `main.tf` file to reflect the scenario name as well as any additional test changes you require.
