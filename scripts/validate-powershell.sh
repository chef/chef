#!/bin/bash
# Simple wrapper to run PowerShell validation locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running Chef PowerShell validation..."

# Check if we're on Windows (via WSL or native)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -f /proc/version ]] && grep -q Microsoft /proc/version 2>/dev/null; then
    # Running on Windows or WSL
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/validate-powershell.ps1"
else
    echo "This validation script is designed for Windows environments."
    echo "You can run it in:"
    echo "  - Windows directly: powershell -ExecutionPolicy Bypass -File scripts/validate-powershell.ps1"
    echo "  - Docker: docker run --rm -v \"\${PWD}:C:\\workspace\" -w C:\\workspace mcr.microsoft.com/windows/servercore:ltsc2022 powershell -ExecutionPolicy Bypass -File \"scripts\\validate-powershell.ps1\""
    exit 1
fi