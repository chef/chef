# Debugging Effortless Chef from Export

There are some occasions in which Chef Infra Client runs in Effortless may fail. This document will help you debug those failures.

## From fresh Windows VM

### Install hab

In a Powershell console, run as administrator:

```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.ps1'))
```

## Untar the customer export
(You may need to restart your shell after installing hab)

```powershell
    tar -xvf customer-export.tar.gz
```

## Copy hab directory from the untarred export to C:\hab

```powershell
    Copy-Item -Path customer-export\hab -Destination C:\hab -Recurse
```

or `start path\to\customer-export` and `start C:\` and drag/copy `hab` directory from the customer export to `C:\`

## Run habitat supervisor

In a Powershell console, run as administrator:

```powershell
    hab sup run
```

## Load the service that you're debugging  

In a separate Powershell console, run as administrator:

```powershell
    # Load the service in question c:\hab\pkgs\<origin>\<service>
    hab svc load <origin>/<service> 
``` 

This will output to `c:\hab\svc\<service>\...`

## Observe

### Timing 
The service will start up based on an interval of seconds defined in `c:\hab\pkgs\<origin>\<service>\...\default.toml`:

```toml
    interval = 14400
    splay = 7200
    splay_first_run = 1000
    run_lock_timeout = 600
    log_level = "info"
    env_path_prefix = ";C:/WINDOWS;C:/WINDOWS/system32/;C:/WINDOWS/system32/WindowsPowerShell/v1.0;"

    [chef_license]
    acceptance = "accept-no-persist"
```

You can see the loop that runs this in `c:\hab\pkgs\<origin>\<service>\...\hooks\run` to see how the intervals are used.

### Output from the service run

The `hab sup run` window will display any output from the service run. If an error occurs that results in a stacktrace,
the stacktrace will be output to the `sup` window, such as `C:/hab/svc/<service>/data/cache/cache/chef-stacktrace.out`

## Altering the service run
If you want to make changes to the service, `hab svc unload <origin>/<service>` and make changes to the files in the `c:\hab\pkgs\<origin>\<service>` directory,

Then, `hab svc load <origin>/<service>` to start the service again.
