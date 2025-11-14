#!/bin/bash
#
# Deploy a GitHub Actions runner to Azure using Bicep (Windows or Linux)
#
# This script deploys a VM to Azure configured as a GitHub Actions self-hosted runner
# using Bicep templates. Works from any platform (Windows, macOS, Linux).

set -e

# Default values
RUNNER_TYPE=""
RESOURCE_GROUP=""
LOCATION="eastus"
VM_NAME=""
VM_SIZE=""
ADMIN_USERNAME="runneradmin"
ADMIN_PASSWORD=""
SSH_PUBLIC_KEY=""
GITHUB_REPO_URL=""
GITHUB_TOKEN=""
RUNNER_NAME=""
RUNNER_LABELS=""
RUNNER_VERSION=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    cat << EOF
Deploy a GitHub Actions runner to Azure using Bicep (Windows or Linux)

Usage:
  $0 [OPTIONS]

Required Options:
  -t, --type TYPE             Runner type: 'windows' or 'linux'
  -g, --resource-group NAME   Azure resource group name
  -r, --repo-url URL          GitHub repository URL

Type-Specific Options:
  Windows:
    -p, --password PASS       Admin password (prompts if not provided)

  Linux:
    -k, --ssh-key PATH        Path to SSH public key file (prompts if not provided)

Optional Options:
  -l, --location REGION       Azure region (default: eastus)
  -n, --vm-name NAME          VM name (default: github-runner-TYPE)
  -s, --vm-size SIZE          VM size (default varies by type)
  -u, --admin-user USER       Admin username (default: runneradmin)
  --github-token TOKEN        GitHub registration token (prompts if not provided)
  --runner-name NAME          Runner name (defaults to VM name)
  --runner-labels LABELS      Runner labels (defaults vary by type)
  --runner-version VERSION    Runner version (default varies by type)
  -h, --help                  Show this help message

Examples:
  # Deploy Windows runner
  $0 -t windows -g "github-runners-rg" -r "https://github.com/chef/chef"

  # Deploy Linux runner with SSH key
  $0 -t linux -g "github-runners-rg" -r "https://github.com/chef/chef" -k ~/.ssh/id_rsa.pub

  # Deploy with custom settings
  $0 -t linux -g "rg-runners" -r "https://github.com/chef/chef" \\
     -n "ubuntu-runner-01" -l "westus2" -k ~/.ssh/id_rsa.pub

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            RUNNER_TYPE="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -n|--vm-name)
            VM_NAME="$2"
            shift 2
            ;;
        -s|--vm-size)
            VM_SIZE="$2"
            shift 2
            ;;
        -u|--admin-user)
            ADMIN_USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        -k|--ssh-key)
            SSH_PUBLIC_KEY="$2"
            shift 2
            ;;
        -r|--repo-url)
            GITHUB_REPO_URL="$2"
            shift 2
            ;;
        --github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --runner-name)
            RUNNER_NAME="$2"
            shift 2
            ;;
        --runner-labels)
            RUNNER_LABELS="$2"
            shift 2
            ;;
        --runner-version)
            RUNNER_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Display banner
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}GitHub Runner Azure Deployment${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Validate required parameters
if [ -z "$RUNNER_TYPE" ]; then
    echo -e "${RED}ERROR: Runner type is required${NC}"
    echo "Use --type or -t to specify 'windows' or 'linux'"
    exit 1
fi

if [ "$RUNNER_TYPE" != "windows" ] && [ "$RUNNER_TYPE" != "linux" ]; then
    echo -e "${RED}ERROR: Runner type must be 'windows' or 'linux'${NC}"
    exit 1
fi

if [ -z "$RESOURCE_GROUP" ]; then
    echo -e "${RED}ERROR: Resource group is required${NC}"
    echo "Use --resource-group or -g to specify"
    exit 1
fi

if [ -z "$GITHUB_REPO_URL" ]; then
    echo -e "${RED}ERROR: GitHub repository URL is required${NC}"
    echo "Use --repo-url or -r to specify"
    exit 1
fi

# Set defaults based on runner type
if [ -z "$VM_NAME" ]; then
    VM_NAME="github-runner-$RUNNER_TYPE"
fi

if [ -z "$VM_SIZE" ]; then
    if [ "$RUNNER_TYPE" == "windows" ]; then
        VM_SIZE="Standard_D2s_v3"
    else
        VM_SIZE="Standard_B2s"
    fi
fi

if [ -z "$RUNNER_LABELS" ]; then
    if [ "$RUNNER_TYPE" == "windows" ]; then
        RUNNER_LABELS="windows,self-hosted,azure"
    else
        RUNNER_LABELS="linux,self-hosted,azure,ubuntu"
    fi
fi

if [ -z "$RUNNER_VERSION" ]; then
    if [ "$RUNNER_TYPE" == "windows" ]; then
        RUNNER_VERSION="2.317.0"
    else
        RUNNER_VERSION="latest"
    fi
fi

if [ -z "$RUNNER_NAME" ]; then
    RUNNER_NAME="$VM_NAME"
fi

# Runner type specific validation
if [ "$RUNNER_TYPE" == "windows" ]; then
    # Windows - need password
    if [ -z "$ADMIN_PASSWORD" ]; then
        echo -e "${YELLOW}Admin password is required for Windows VM${NC}"
        read -sp "Enter admin password: " ADMIN_PASSWORD
        echo ""
        read -sp "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
        echo ""

        if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
            echo -e "${RED}ERROR: Passwords do not match${NC}"
            exit 1
        fi
    fi
else
    # Linux - need SSH key
    if [ -z "$SSH_PUBLIC_KEY" ]; then
        DEFAULT_KEY="$HOME/.ssh/id_rsa.pub"
        if [ -f "$DEFAULT_KEY" ]; then
            echo -e "${YELLOW}Found SSH key at: $DEFAULT_KEY${NC}"
            read -p "Use this key? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                SSH_PUBLIC_KEY="$DEFAULT_KEY"
            else
                read -p "Enter path to SSH public key: " SSH_PUBLIC_KEY
            fi
        else
            echo -e "${YELLOW}SSH public key is required for Linux VM${NC}"
            read -p "Enter path to SSH public key file: " SSH_PUBLIC_KEY
        fi
    fi

    # Expand tilde in path
    SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY/#\~/$HOME}"

    if [ ! -f "$SSH_PUBLIC_KEY" ]; then
        echo -e "${RED}ERROR: SSH key file not found: $SSH_PUBLIC_KEY${NC}"
        exit 1
    fi
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}ERROR: Azure CLI is not installed${NC}"
    echo "Install it from: https://aka.ms/installazurecli"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Please login...${NC}"
    az login
    if [ $? -ne 0 ]; then
        echo -e "${RED}Azure login failed${NC}"
        exit 1
    fi
fi

ACCOUNT_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}Using Azure subscription: $ACCOUNT_NAME${NC}"
echo ""

# Prompt for GitHub token if not provided
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}GitHub registration token is required${NC}"
    echo -e "${CYAN}Get it from: $GITHUB_REPO_URL/settings/actions/runners${NC}"
    echo -e "${CYAN}Or use: gh api --method POST /repos/OWNER/REPO/actions/runners/registration-token${NC}"
    echo ""
    read -sp "Enter GitHub registration token: " GITHUB_TOKEN
    echo ""

    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}ERROR: GitHub token is required${NC}"
        exit 1
    fi
fi

# Display configuration
echo ""
echo -e "${CYAN}Deployment Configuration:${NC}"
echo -e "${CYAN}=========================${NC}"
echo -e "${NC}Runner Type: $RUNNER_TYPE${NC}"
echo -e "${NC}Resource Group: $RESOURCE_GROUP${NC}"
echo -e "${NC}Location: $LOCATION${NC}"
echo -e "${NC}VM Name: $VM_NAME${NC}"
echo -e "${NC}VM Size: $VM_SIZE${NC}"
echo -e "${NC}Admin Username: $ADMIN_USERNAME${NC}"
if [ "$RUNNER_TYPE" == "linux" ]; then
    echo -e "${NC}SSH Key: $SSH_PUBLIC_KEY${NC}"
fi
echo -e "${NC}GitHub Repository: $GITHUB_REPO_URL${NC}"
echo -e "${NC}Runner Name: $RUNNER_NAME${NC}"
echo -e "${NC}Runner Labels: $RUNNER_LABELS${NC}"
echo -e "${NC}Runner Version: $RUNNER_VERSION${NC}"
echo ""

# Confirm deployment
read -p "Proceed with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Create resource group if it doesn't exist
echo ""
echo -e "${YELLOW}Checking resource group...${NC}"
RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")
if [ "$RG_EXISTS" == "false" ]; then
    echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create resource group${NC}"
        exit 1
    fi
    echo -e "${GREEN}Resource group created successfully${NC}"
else
    echo -e "${GREEN}Resource group already exists${NC}"
fi

# Find the Bicep template
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BICEP_TEMPLATE="$SCRIPT_DIR/templates/github-runner-$RUNNER_TYPE.bicep"

if [ ! -f "$BICEP_TEMPLATE" ]; then
    echo -e "${RED}ERROR: Bicep template not found: $BICEP_TEMPLATE${NC}"
    exit 1
fi

# Build parameters array
DEPLOYMENT_NAME="github-runner-$(date +%Y%m%d%H%M%S)"
PARAMS="vmName=$VM_NAME location=$LOCATION vmSize=$VM_SIZE adminUsername=$ADMIN_USERNAME"
PARAMS="$PARAMS githubRepoUrl=$GITHUB_REPO_URL githubRegistrationToken=$GITHUB_TOKEN"
PARAMS="$PARAMS runnerName=$RUNNER_NAME runnerLabels=$RUNNER_LABELS runnerVersion=$RUNNER_VERSION"

if [ "$RUNNER_TYPE" == "windows" ]; then
    PARAMS="$PARAMS adminPassword=$ADMIN_PASSWORD"
else
    SSH_KEY_DATA=$(cat "$SSH_PUBLIC_KEY")
    PARAMS="$PARAMS sshPublicKey=$SSH_KEY_DATA"
fi

# Deploy the Bicep template
echo ""
echo -e "${YELLOW}Deploying Bicep template...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"
echo ""

az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$BICEP_TEMPLATE" \
    --parameters $PARAMS

if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment failed${NC}"
    exit 1
fi

# Get deployment outputs
echo ""
echo -e "${YELLOW}Retrieving deployment outputs...${NC}"
OUTPUTS=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.outputs)

VM_NAME_OUT=$(echo "$OUTPUTS" | jq -r '.vmName.value')
PUBLIC_IP=$(echo "$OUTPUTS" | jq -r '.publicIpAddress.value')
ADMIN_USER=$(echo "$OUTPUTS" | jq -r '.adminUsername.value')
RUNNER_NAME_OUT=$(echo "$OUTPUTS" | jq -r '.runnerName.value')

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${NC}VM Name: $VM_NAME_OUT${NC}"
echo -e "${NC}Public IP: $PUBLIC_IP${NC}"
echo -e "${NC}Admin Username: $ADMIN_USER${NC}"
echo -e "${NC}Runner Name: $RUNNER_NAME_OUT${NC}"
echo ""

if [ "$RUNNER_TYPE" == "windows" ]; then
    echo -e "${CYAN}RDP Connection: mstsc /v:$PUBLIC_IP${NC}"
else
    SSH_COMMAND=$(echo "$OUTPUTS" | jq -r '.sshCommand.value')
    echo -e "${CYAN}SSH Connection: $SSH_COMMAND${NC}"
fi

echo ""
echo -e "${YELLOW}Check runner status at: $GITHUB_REPO_URL/settings/actions/runners${NC}"
echo ""
echo -e "${YELLOW}Note: The runner installation may take a few more minutes to complete.${NC}"
echo -e "${YELLOW}Check the custom script extension status in the Azure portal.${NC}"
echo ""
