# Step-by-Step Guide to Create a Self-Hosted GitHub Runner on Azure

This guide provides instructions for setting up self-hosted GitHub runners on both Windows (using PowerShell) and Linux (using Bash and Azure CLI). Self-hosted runners allow you to run GitHub Actions workflows on your own infrastructure.

Side Note: Internally on the Chef team, we use Github hosted Windows runners already. There is no need to spin up a new runner in that use case.
However, for FIPS testing, we need to create our own Linux runners using an OS like Ubuntu with the Pro subscription and then configure it to be FIPS enabled.

## Prerequisites

- You need to have Owner rights in the Chef org
- You need a resource group in the "Engineering Dev/Test" subscription
- For Windows: Administrative privileges on the Windows machine
- For Linux: An Azure subscription and Azure CLI installed
- GitHub Personal Access Token (PAT) with `repo` scope (for repository-level runners) or `admin:org` scope (for organization-level runners)

Github also allows you to create a token to execute the runner with that does not require your PAT. Do this to get a spiffy token:

```PowerShell
gh api --method POST /repos/chef/chef/actions/runners/registration-token \
  --header 'Accept: application/vnd.github+json' \
  --header 'X-GitHub-Api-Version: 2022-11-28'
```

## Part 1: Windows Runner Setup (Using PowerShell)

### Step 1: Prepare the Windows Environment

1. Ensure PowerShell is running with administrative privileges
2. Create a dedicated directory for the runner (e.g., `C:\actions-runner`)
3. Ensure the machine has internet access and meets GitHub's runner requirements:
   - Windows 10/11 or Windows Server 2019/2022
   - At least 2 GB RAM
   - At least 10 GB free disk space

### Step 2: Download and Extract the Runner

```powershell
# Create directory for the runner
New-Item -ItemType Directory -Path "C:\actions-runner" -Force
Set-Location "C:\actions-runner"

# Download the latest runner (replace with your desired version)
$runnerVersion = "2.317.0"  # Check https://github.com/actions/runner/releases for latest
$url = "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip"
Invoke-WebRequest -Uri $url -OutFile "actions-runner.zip"

# Extract the runner
Expand-Archive -Path "actions-runner.zip" -DestinationPath "." -Force
Remove-Item "actions-runner.zip"
```

### Step 3: Configure the Runner

1. Go to your GitHub repository or organization settings
2. Navigate to **Settings** > **Actions** > **Runners**
3. Click **Add runner**
4. Select **Self-hosted** and choose **Windows**
5. Copy the registration token

```powershell
# Configure the runner (replace with your actual values)
$repoUrl = "https://github.com/chef/chef"  # For repo-level runner
# OR for organization-level: $orgUrl = "https://github.com/your-org"
$token = "YOUR_REGISTRATION_TOKEN_HERE"
$runnerName = "windows-runner-01"

# Run configuration
.\config.cmd --url $repoUrl --token $token --name $runnerName --work "_work" --labels "windows,self-hosted"
```

### Step 4: Install and Start the Service

```powershell
# Install as a service (requires admin privileges)
.\svc-install.ps1

# Start the service
Start-Service actions.runner.*

# Verify the service is running
Get-Service actions.runner.*
```

### Step 5: Verify the Runner

1. Go back to GitHub Settings > Actions > Runners
2. You should see your new runner listed as "Online"
3. Test with a simple workflow to ensure it's working

## Part 2: Linux Runner Setup (Using Bash and Azure CLI)

### Step 1: Prepare Azure Environment

1. Ensure Azure CLI is installed and authenticated:

```bash
az login
az account set --subscription "your-subscription-id"
```

2. Create a resource group (if it doesn't exist)

```bash
az group create --name "github-runners-rg" --location "eastus"
```

### Step 2: Create Azure VM

```bash
# Create VM with Ubuntu (recommended for GitHub runners)
az vm create \
  --resource-group "github-runners-rg" \
  --name "github-runner-linux" \
  --image "Ubuntu2204" \
  --admin-username "runneradmin" \
  --generate-ssh-keys \
  --size "Standard_B2s" \
  --public-ip-sku "Standard" \
  --tags "purpose=github-runner"
```

### Step 3: Open Required Ports and Configure Security

```bash
# Open SSH port (if not already open)
az vm open-port --resource-group "github-runners-rg" --name "github-runner-linux" --port 22

# Get VM public IP
VM_IP=$(az vm show --resource-group "github-runners-rg" --name "github-runner-linux" --show-details --query [publicIps] -o tsv)
echo "VM IP: $VM_IP"
```

### Step 4: Connect to VM and Install Dependencies

```bash
# SSH into the VM (replace 'azureuser' with your actual VM admin username)
ssh azureuser@$VM_IP

# Update system and install dependencies
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget unzip jq

# Create runner user (optional, for security)
sudo useradd -m -s /bin/bash runner
sudo usermod -aG sudo runner
# Note: Do not set a password for the runner account. Instead do this:
sudo visudo
# now add this to the list:
runner ALL=(ALL) NOPASSWD:ALL
# Ctrl-O, Ctrl-X to save and exit

# Switch to runner user for the rest of the setup
sudo -u runner mkdir -p /home/runner/actions-runner
sudo su - runner
```

### Step 5: Download and Extract the Runner

```bash
# Download latest runner (run as runner user)
sudo -u runner bash << 'EOF'
cd /home/runner/actions-runner

# Get latest release version
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
echo "Latest runner version: $RUNNER_VERSION"

# Download and extract
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
EOF
```

### Step 6: Configure the Runner

1. From your local machine, get the registration token from GitHub (same as Windows steps)
2. SSH back to VM and configure:

```bash
# SSH back to VM
ssh runneradmin@$VM_IP

# Configure runner (replace with your values)
REPO_URL="https://github.com/chef/chef"
<!-- cspell:disable -->
TOKEN="ABFBQT5WJE4YTDVFEL3EMBDJCX7CS"
<!-- cspell:enable -->
RUNNER_NAME="ubuntu-2404-pro-fips-tester"

sudo -u runner bash << EOF
cd /home/runner/actions-runner
./config.sh --url $REPO_URL --token $TOKEN --name $RUNNER_NAME --work _work --labels "ubuntu-2404-pro-fips-tester,linux,self-hosted" --unattended
EOF
```

### Step 7: Install and Start the Service

```bash
# Install as service. Since we added the NOPASSWD settings to the runner user account, we pass the '-n' flag in when we start the service, otherwise bad things happen.
sudo -u runner bash << 'EOF'
cd /home/runner/actions-runner
sudo ./svc.sh install
sudo -n ./svc.sh start
EOF

# Verify service is running
sudo -u runner bash << 'EOF'
cd /home/runner/actions-runner
sudo ./svc.sh status
EOF
```

### Step 8: Verify the Runner

1. Go back to GitHub Settings > Actions > Runners
2. You should see your Linux runner listed as "Ready". If the runner shows up as "idle" something is not correct in the configuration.
3. Test with a workflow that targets the "linux" label
4. You can also test using "./config.sh --check --url https://github.com/chef/chef" - you will be prompted to enter your personal PAT

## Maintenance and Security Considerations

### For Both Platforms

- **Security**: Store registration tokens securely, rotate them regularly
- **Updates**: GitHub runners auto-update, but monitor for issues
- **Monitoring**: Check runner status regularly in GitHub settings
- **Cleanup**: Remove runners from GitHub settings before decommissioning VMs/machines

### Windows-Specific

- Use Windows Firewall to restrict inbound connections
- Consider using Group Policy for runner management in enterprise environments

### Linux/Azure-Specific

- Use Azure Key Vault for secrets management
- Implement Azure Monitor for VM health
- Consider using Azure Virtual Machine Scale Sets for multiple runners
- Use Azure Resource Manager templates for reproducible deployments

## Troubleshooting

### Common Issues

1. **Runner not appearing online**: Check network connectivity and firewall rules
2. **Jobs not picking up runner**: Verify labels match workflow requirements
3. **Service fails to start**: Check permissions and service logs
4. **Token expired**: Generate new token and reconfigure runner

### Logs Location

- **Windows**: `C:\actions-runner\_diag\*.log`
- **Linux**: `/home/runner/actions-runner/_diag/*.log`

For more detailed troubleshooting, refer to the [GitHub Actions documentation](https://docs.github.com/en/actions/hosting-your-own-runners).
