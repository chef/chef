#!/bin/bash
# Local test script for debugging PowerShell validation in Docker

echo "==> Testing PowerShell scripts in Docker container locally..."

echo ""
echo "1. Testing ultra-minimal script..."
docker run --rm -v "$(pwd):/workspace" -w /workspace mcr.microsoft.com/windows/servercore:ltsc2022 powershell -ExecutionPolicy Bypass -File "scripts/validate-powershell-ultra-minimal.ps1"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Ultra-minimal test PASSED"
    
    echo ""
    echo "2. Testing minimal script..."
    docker run --rm -v "$(pwd):/workspace" -w /workspace mcr.microsoft.com/windows/servercore:ltsc2022 powershell -ExecutionPolicy Bypass -File "scripts/validate-powershell-minimal.ps1"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Minimal test PASSED"
        
        echo ""
        echo "3. Testing full script..."
        docker run --rm -v "$(pwd):/workspace" -w /workspace mcr.microsoft.com/windows/servercore:ltsc2022 powershell -ExecutionPolicy Bypass -File "scripts/validate-powershell.ps1"
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ All tests PASSED!"
        else
            echo ""
            echo "❌ Full script FAILED"
        fi
    else
        echo ""
        echo "❌ Minimal script FAILED"
    fi
else
    echo ""
    echo "❌ Ultra-minimal script FAILED"
fi