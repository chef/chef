// Bicep template for deploying a Linux GitHub Actions self-hosted runner on Azure VM
//
// Parameters to customize the deployment

@description('Name of the virtual machine')
param vmName string = 'github-runner-linux'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Size of the virtual machine')
param vmSize string = 'Standard_B2s'

@description('Admin username for the virtual machine')
param adminUsername string = 'runneradmin'

@description('SSH public key for authentication')
param sshPublicKey string

@description('GitHub repository URL (e.g., https://github.com/chef/chef)')
param githubRepoUrl string

@description('GitHub runner registration token')
@secure()
param githubRegistrationToken string

@description('Name for the GitHub runner')
param runnerName string = vmName

@description('Comma-separated labels for the runner')
param runnerLabels string = 'linux,self-hosted,azure,ubuntu'

@description('GitHub Actions runner version to install (use "latest" for auto-detect)')
param runnerVersion string = 'latest'

@description('System user to run the service as')
param runnerUser string = 'runner'

@description('Installation directory for the runner')
param installDir string = '/home/runner/actions-runner'

@description('Ubuntu version')
@allowed([
  '20_04-lts-gen2'
  '22_04-lts-gen2'
  '24_04-lts-gen2'
])
param ubuntuOSVersion string = '22_04-lts-gen2'

@description('Name of the network security group')
param nsgName string = '${vmName}-nsg'

@description('Name of the virtual network')
param vnetName string = '${vmName}-vnet'

@description('Name of the network interface')
param nicName string = '${vmName}-nic'

@description('Name of the public IP address')
param publicIpName string = '${vmName}-pip'

// Variables
var subnetName = 'default'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Static'
var publicIpSku = 'Standard'

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Public IP Address
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Custom Script Extension to install GitHub runner
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'InstallGitHubRunner'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      script: base64('''#!/bin/bash
set -e

# Configuration from Bicep parameters
RUNNER_VERSION="${runnerVersion}"
REPO_URL="${githubRepoUrl}"
REGISTRATION_TOKEN="${githubRegistrationToken}"
RUNNER_NAME="${runnerName}"
RUNNER_LABELS="${runnerLabels}"
RUNNER_USER="${runnerUser}"
INSTALL_DIR="${installDir}"

echo "Starting GitHub Actions runner installation..."

# Install dependencies
apt-get update -qq
apt-get install -y curl tar jq

# Create runner user
if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
fi

# Configure passwordless sudo
echo "$RUNNER_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$RUNNER_USER
chmod 440 /etc/sudoers.d/$RUNNER_USER

# Create installation directory
mkdir -p "$INSTALL_DIR"
chown "$RUNNER_USER:$RUNNER_USER" "$INSTALL_DIR"

# Determine runner version
if [ "$RUNNER_VERSION" == "latest" ]; then
    RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
fi

# Download and extract runner
sudo -u "$RUNNER_USER" bash << EOF
cd "$INSTALL_DIR"
curl -o actions-runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
tar xzf ./actions-runner.tar.gz
rm actions-runner.tar.gz
EOF

# Configure runner
sudo -u "$RUNNER_USER" bash << EOF
cd "$INSTALL_DIR"
./config.sh \\
    --url "$REPO_URL" \\
    --token "$REGISTRATION_TOKEN" \\
    --name "$RUNNER_NAME" \\
    --work "_work" \\
    --labels "$RUNNER_LABELS" \\
    --unattended
EOF

# Install and start service
cd "$INSTALL_DIR"
./svc.sh install "$RUNNER_USER"
./svc.sh start

echo "GitHub Actions runner installation completed successfully!"
''')
    }
  }
}

// Outputs
output vmId string = vm.id
output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
output adminUsername string = adminUsername
output runnerName string = runnerName
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.ipAddress}'
