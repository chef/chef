#
# A scaffolding for Chef Policyfile packages
#

if (!$scaffold_policy_name) {
    Write-Host "You must set `$scaffold_policy_name to a valid policy name. For example:`n `$scaffold_policy_name=base `n Will build a base.rb policyfile."
    exit 1
}

function Load-Scaffolding {
    $scaffold_chef_client = "stuartpreston/chef-client-detox"
    $scaffold_chef_dk = "core/chef-dk"

    $pkg_deps += @("$scaffold_chef_client", "core/cacerts")
    $pkg_build_deps += @("$scaffold_chef_dk", "core/git")
    $pkg_svc_run = "set_just_so_you_will_render"
}

function Invoke-DefaultBuildService {
    New-Item -ItemType directory -Path "$pkg_prefix/hooks"

    Add-Content -Path "$pkg_prefix/hooks/run" -Value @"
function Invoke-ChefClient {
  {{pkgPathFor "stuartpreston/chef-client-detox"}}/bin/chef-client.bat -z -l {{cfg.log_level}} -c $pkg_svc_config_path/client-config.rb -j $pkg_svc_config_path/attributes.json --once --no-fork --run-lock-timeout {{cfg.run_lock_timeout}}
}

`$splay_duration = Get-Random -InputObject (0..{{cfg.splay}}) -Count 1

`$splay_first_run_duration = Get-Random -InputObject (0..{{cfg.splay_first_run}}) -Count 1

`$env:SSL_CERT_FILE="{{pkgPathFor "core/cacerts"}}/ssl/cert.pem"

cd {{pkg.path}}

Start-Sleep -Seconds `$splay_first_run_duration
Invoke-ChefClient

while(`$true){
  Start-Sleep -Seconds `$splay_duration
  Start-Sleep -Seconds {{cfg.interval}}
  Invoke-ChefClient
}
"@
}


function Invoke-DefaultBuild {
    if (!(Test-Path -Path "$scaffold_policyfile_path")) {
        Write-BuildLine "Could not detect a policyfiles directory, this is required to proceed!"
        exit 1
    }

    Remove-Item "$scaffold_policyfile_path/*.lock.json" -Force
    $policyfile = "$scaffold_policyfile_path/$scaffold_policy_name.rb"

    Get-Content $policyfile | ? { $_.StartsWith("include_policy") } | % {
        $p = $_.Split()[1]
        $p = $p.Replace("`"", "").Replace(",", "")
        Write-BuildLine "Detected included policyfile, $p.rb, installing"
        chef install "$scaffold_policyfile_path/$p.rb"
    }
    Write-BuildLine "Installing $policyfile"
    chef install "$policyfile"
}

function Invoke-DefaultInstall {
    Write-BuildLine "Exporting Chef Infra Repository"
    chef export "$scaffold_policyfile_path/$scaffold_policy_name.lock.json" "$pkg_prefix"

    Write-BuildLine "Creating Chef Infra configuration"
    New-Item -ItemType directory -Path "$pkg_prefix/config"
    Add-Content -Path "$pkg_prefix/.chef/config.rb" -Value @"
cache_path "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$pkg_svc_data_path/cache").Replace("\","/"))"
node_path "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$pkg_svc_data_path/nodes").Replace("\","/"))"
role_path "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$pkg_svc_data_path/roles").Replace("\","/"))"
chef_zero.enabled true
ENV['PSModulePath'] += "C:/Program\ Files/WindowsPowerShell/Modules"
"@

    Write-BuildLine "Creating initial bootstrap configuration"
    Copy-Item -Path "$pkg_prefix/.chef/config.rb" -Destination "$pkg_prefix/config/bootstrap-config.rb"
    Add-Content -Path "$pkg_prefix/config/bootstrap-config.rb" -Value @"
ENV['PATH'] += ";C:/WINDOWS;C:/WINDOWS/system32/;C:/WINDOWS/system32/WindowsPowerShell/v1.0;C:/ProgramData/chocolatey/bin"
"@

    Write-BuildLine "Creating Chef Infra client configuration"
    Copy-Item -Path "$pkg_prefix/.chef/config.rb" -Destination "$pkg_prefix/config/client-config.rb"
    Add-Content -Path "$pkg_prefix/config/client-config.rb" -Value @"
ssl_verify_mode {{cfg.ssl_verify_mode}}
ENV['PATH'] += "{{cfg.env_path_prefix}}"

{{#if cfg.data_collector.enable ~}}
chef_guid "{{sys.member_id}}"
data_collector.token "{{cfg.data_collector.token}}"
data_collector.server_url "{{cfg.data_collector.server_url}}"
{{/if ~}}
"@

    Write-BuildLine "Generating config/attributes.json"
    Add-Content -Path "$pkg_prefix/config/attributes.json" -Value @"
{{#if cfg.attributes}}
{{toJson cfg.attributes}}
{{else ~}}
{}
{{/if ~}}
"@

    Write-BuildLine "Generating Chef Habiat configuration, default.toml"
    Add-Content -Path "$pkg_prefix/default.toml" -Value @"
interval = 1800
splay = 1800
splay_first_run = 0
run_lock_timeout = 1800
log_level = "warn"
env_path_prefix = ";C:/WINDOWS;C:/WINDOWS/system32/;C:/WINDOWS/system32/WindowsPowerShell/v1.0;C:/ProgramData/chocolatey/bin"
ssl_verify_mode = ":verify_peer"

[chef_license]
acceptance = "undefined"

[data_collector]
enable = false
token = "set_to_your_token"
server_url = "set_to_your_url"
"@

    $scaffold_data_bags_path = "not_using_data_bags" # Set default to some string so Test-Path returns false instead of error. Thanks Powershell!
    if (Test-Path "$scaffold_data_bags_path") {
        Write-BuildLine "Detected a data bags directory, installing into package"
        Copy-Item "$scaffold_data_bags_path/*" -Destination "$pkg_prefix" -Recurse
    }
}
