// Bicep template for deploying a Windows GitHub Actions self-hosted runner on Azure VM
//
// Parameters to customize the deployment

@description('Name of the virtual machine')
param vmName string = 'github-runner-windows'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Size of the virtual machine')
param vmSize string = 'Standard_D2s_v3'

@description('Admin username for the virtual machine')
param adminUsername string = 'runneradmin'

@description('Admin password for the virtual machine')
@secure()
param adminPassword string

@description('GitHub repository URL (e.g., https://github.com/chef/chef)')
param githubRepoUrl string

@description('GitHub runner registration token')
@secure()
param githubRegistrationToken string

@description('Name for the GitHub runner')
param runnerName string = vmName

@description('Comma-separated labels for the runner')
param runnerLabels string = 'windows,self-hosted,azure'

@description('GitHub Actions runner version to install')
param runnerVersion string = '2.317.0'

@description('Installation directory for the runner')
param installDir string = 'C:\\actions-runner'

@description('Windows OS version')
@allowed([
  '2019-Datacenter'
  '2022-Datacenter'
  '2022-datacenter-azure-edition'
])
param windowsOSVersion string = '2022-Datacenter'

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
        name: 'AllowRDP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
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
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
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
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command "$ErrorActionPreference = \'Stop\'; New-Item -ItemType Directory -Path \'${installDir}\' -Force | Out-Null; Set-Location \'${installDir}\'; Invoke-WebRequest -Uri \'https://github.com/actions/runner/releases/download/v${runnerVersion}/actions-runner-win-x64-${runnerVersion}.zip\' -OutFile \'actions-runner.zip\'; Expand-Archive -Path \'actions-runner.zip\' -DestinationPath \'.\' -Force; Remove-Item \'actions-runner.zip\'; .\\config.cmd --url ${githubRepoUrl} --token ${githubRegistrationToken} --name ${runnerName} --work _work --labels ${runnerLabels} --unattended; .\\svc.ps1 install; Start-Service actions.runner.*"'
    }
  }
}

// Outputs
output vmId string = vm.id
output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
output adminUsername string = adminUsername
output runnerName string = runnerName
