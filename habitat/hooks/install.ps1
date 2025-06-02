# Chef Infra Client Windows post-install hook

Function Invoke-Binlink {
    Write-Host "Creating binlinks for Chef Infra Client..."
    
    # Use the pkg_ident env var that's available in hooks
    hab pkg binlink --force $env:pkg_ident chef-client
    hab pkg binlink --force $env:pkg_ident chef-solo
    hab pkg binlink --force $env:pkg_ident chef-shell
    hab pkg binlink --force $env:pkg_ident chef-apply
    hab pkg binlink --force $env:pkg_ident ohai
    
    Write-Host "Chef Infra Client binaries have been successfully linked"
}

Invoke-Binlink