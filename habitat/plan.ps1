$env:HAB_BLDR_CHANNEL = "base-2025"
$pkg_name="chef-infra-client"

$env:HAB_BLDR_CHANNEL="base-2025"
$pkg_origin="chef"
$pkg_version=(Get-Content $PLAN_CONTEXT/../VERSION)
$pkg_description="Chef Infra Client is an agent that runs locally on every node that is under management by Chef Infra. This package is binary-only to provide Chef Infra Client executables. It does not define a service to run."
$pkg_maintainer="The Chef Maintainers <maintainers@chef.io>"
$pkg_upstream_url="https://github.com/chef/chef"
$pkg_license=@("Apache-2.0")
$pkg_filename="${pkg_name}-${pkg_version}.zip"
$pkg_bin_dirs=@(
    "bin"
    "vendor/bin"
)
$pkg_deps=@(
  "core/cacerts"
  "core/openssl"
  "core/zlib"
  "core/libarchive"
  "core/ruby3_4-plus-devkit"
  "chef/chef-powershell-shim"
  "core/visual-cpp-redist-2022"
)

function Invoke-Begin {
    write-output "*** Start Invoke-Begin Function"
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]"0.85.0" ) {
        Write-Warning "(╯°□°）╯︵ ┻━┻ I CAN'T WORK UNDER THESE CONDITIONS!"
        Write-Warning ":habicat: I'm being built with $hab_version. I need at least Hab 0.85.0, because I use the -IsPath option for setting/pushing paths in SetupEnvironment."
        throw "unable to build: required minimum version of Habitat not installed"
    } else {
        Write-BuildLine ":habicat: I think I have the version I need to build."
    }
}

function Invoke-SetupEnvironment {
    write-output "*** Start Invoke-SetupEnvironment Function"
    Push-RuntimeEnv -IsPath GEM_PATH "$pkg_prefix/vendor"

    Set-RuntimeEnv APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
    # Set-RuntimeEnv FORCE_FFI_YAJL "ffi" # default: ext - Always use the C-extensions because we use MRI on all the things and C is fast.
    Set-RuntimeEnv -f -IsPath SSL_CERT_FILE "$(Get-HabPackagePath cacerts)/ssl/cert.pem"
    Set-RuntimeEnv LANG "en_US.UTF-8"
    Set-RuntimeEnv LC_CTYPE "en_US.UTF-8"

    Push-RuntimeEnv -IsPath RUBY_DLL_PATH "$(Get-HabPackagePath openssl)/bin"
    Push-RuntimeEnv -IsPath RUBY_DLL_PATH "$(Get-HabPackagePath zlib)/bin"
    Push-RuntimeEnv -IsPath RUBY_DLL_PATH "$(Get-HabPackagePath visual-cpp-redist-2022)/bin"
    Push-RuntimeEnv -IsPath RUBY_DLL_PATH "$(Get-HabPackagePath libarchive)/bin"

    # Ensure Ruby 3.4 gem paths are properly set up
    $ruby_version = "3.4.0"
    Push-RuntimeEnv -IsPath GEM_PATH "$(Get-HabPackagePath ruby3_4-plus-devkit)/lib/ruby/gems/$ruby_version"
}

function Invoke-Download() {
    Write-BuildLine "*** Start Invoke-Download - Locally creating archive of latest repository commit at ${HAB_CACHE_SRC_PATH}\${pkg_filename}"

    try {
        # what is my actual path here before push-location
        Write-Output "Invoke-Download Function: Original path: $(Get-Location)"

        # just doing a test example here, should show my resolved-path, for those not sure what the resolved path does
        $resolvedPath = (Resolve-Path "$PLAN_CONTEXT/../").Path
        Write-Output "Invoke-Download Function: Resolved target path: $resolvedPath"

        # Push-Location to move into the new directory and stack the current directory, neat way to use cd
        Push-Location $resolvedPath
        Write-Output "Path after Push-Location: $(Get-Location) "

        # Generate the archive using git, fixing perms as well
        write-output "*** Invoke-Download Function: fixing permissions on docker container git config --global --add safe.directory C:/src"
        git config --global --add safe.directory C:/src
        Write-Output "*** Invoke-Download Function: Creating archive at ${HAB_CACHE_SRC_PATH}\${pkg_filename}... "
        git archive --format=zip --output="${HAB_CACHE_SRC_PATH}\${pkg_filename}" HEAD

        # Check if the file exists and has a valid size (non-zero), or fail the build
        $archiveFile = Get-Item "${HAB_CACHE_SRC_PATH}\${pkg_filename}"
        if (-not $archiveFile) {
            throw "Invoke-Download Function: Archive file not created. "
        } elseif ($archiveFile.Length -eq 0) {
            throw "Invoke-Download Function: Archive file is 0 bytes. Archive creation failed. "
        }

        Write-Output "*** Invoke-Download Function: Archive created successfully: $($archiveFile.FullName) with size $($archiveFile.Length) bytes"

    } catch {
        # Capture any errors from git archive or other commands
        Write-Output "Invoke-Download Function: Error occurred: $_ "
        throw $_
    } finally {
        # Always return to the original path
        Write-Output "Invoke-Download Function: Path before Pop-Location: $(Get-Location) "
        Pop-Location
        Write-Output "Invoke-Download Function: Restored path after Pop-Location: $(Get-Location) "
    }
}

function Invoke-Verify() {
    Write-BuildLine " ** Invoke-Verify Skipping checksum verification on the archive we just created"
    return 0
}

function Invoke-Clean () {
    Write-BuildLine " **  Start Invoke-Clean Function"
    $src = "$HAB_CACHE_SRC_PATH\$pkg_dirname"
    if (Test-Path "$src") {
        Remove-Item "$src" -Recurse -Force
    }
}

function Invoke-Unpack () {
    Write-BuildLine "*** Start Invoke-Unpack Function"
    if($null -ne $pkg_filename) {
        Expand-Archive -Path "$HAB_CACHE_SRC_PATH\$pkg_filename" -DestinationPath "$HAB_CACHE_SRC_PATH\$pkg_dirname"
    }
}

function Invoke-Prepare {
    write-output " ** Start Invoke-Prepare Function"
    $env:GEM_HOME = "$pkg_prefix/vendor"

    # Ensure Ruby 3.4 can find its gems
    $ruby_version = "3.4.0"
    $ruby_gem_path = "$(Get-HabPackagePath ruby3_4-plus-devkit)/lib/ruby/gems/$ruby_version"
    $env:GEM_PATH = "$pkg_prefix/vendor;$ruby_gem_path"

    try {
        Push-Location "${HAB_CACHE_SRC_PATH}/${pkg_dirname}"
        Write-BuildLine " ** Where is my gem at?"
        $gem_file = @"
@ECHO OFF
@"%~dp0ruby.exe" "%~dpn0" %*
"@
        $gem_file | Set-Content "$PWD\\gem.bat"
        $env:Path += ";c:\\Program Files\\Git\\bin;"

        Write-BuildLine " ** Configuring bundler for this build environment"
        bundle config --local without server docgen maintenance pry travis integration ci
        if (-not $?) { throw "unable to configure bundler to restrict gems to be installed" }
        bundle config --local retry 5
        bundle config --local silence_root_warning 1
        $openssl_dir = "$(Get-HabPackagePath core/openssl)"
        Write-BuildLine "OpenSSL Dir $openssl_dir"
        bundle config build.openssl --with-openssl-dir=$openssl_dir
    } finally {
        Pop-Location
    }
}

function Invoke-Build {
    try {
        write-output "*** invoke-build"
        Push-Location "${HAB_CACHE_SRC_PATH}/${pkg_dirname}"

        $env:_BUNDLER_WINDOWS_DLLS_COPIED = "1"

        $openssl_dir = "$(Get-HabPackagePath core/openssl)"
        gem install openssl:3.3.0 -- --with-openssl-dir=$openssl_dir --with-openssl-include="$openssl_dir/include" --with-openssl-lib="$openssl_dir/lib"

        Write-BuildLine " ** Using bundler to retrieve the Ruby dependencies"
        bundle install --jobs=3 --retry=3
        if (-not $?) { throw "unable to install gem dependencies" }
        Write-BuildLine " ** 'rake install' any gem sourced as a git reference so they'll look like regular gems."
        foreach($git_gem in (Get-ChildItem "$env:GEM_HOME/bundler/gems")) {
            try {
                Push-Location $git_gem
                Write-BuildLine " -- installing $git_gem"
                # The rest client doesn't have an 'Install' task so it bombs out when we call Rake Install for it
                # Happily, its Rakefile ultimately calls 'gem build' to build itself with. We're doing that here.
                if ($git_gem -match "rest-client"){
                    $gemspec_path = $git_gem.ToString() + "\rest-client.gemspec"
                    gem build $gemspec_path
                    $gem_path = $git_gem.ToString() + "\rest-client*.gem"
                    gem install $gem_path
                }
                else {
                    rake install $git_gem --trace=stdout # this needs to NOT be 'bundle exec'd else bundler complains about dev deps not being installed
                }
                if (-not $?) { throw "unable to install $($git_gem) as a plain old gem" }
            } finally {
                Pop-Location
            }
        }
        Write-BuildLine " ** Running the chef project's 'rake install' to install the path-based gems so they look like any other installed gem."

        # Set up gem environment for installing to vendor directory
        $ruby_version = "3.4.0"
        $ruby_gem_path = "$(Get-HabPackagePath ruby3_4-plus-devkit)/lib/ruby/gems/$ruby_version"
        $env:GEM_PATH = "$pkg_prefix/vendor;$ruby_gem_path"
        $env:GEM_HOME = "$pkg_prefix/vendor"

        Write-BuildLine " ** Running the chef project's 'rake install:local' to install the path-based gems so they look like any other installed gem."

        # Temporarily modify Gemfile to comment out chef-bin to avoid circular dependency
        $gemfile_backup = Get-Content "Gemfile"
        $modified_gemfile = $gemfile_backup | ForEach-Object {
            if ($_ -match "^\s*gem\s+[`"']chef-bin[`"']") {
                "# TEMPORARY: $_"
            } else {
                $_
            }
        }
        Set-Content "Gemfile" $modified_gemfile

        try {
            # Install gems using the original approach but without chef-bin
            $install_attempt = 0
            do {
                Start-Sleep -Seconds 5
                $install_attempt++
                Write-BuildLine "Install attempt $install_attempt"
                bundle exec rake install:local --trace=stdout
            } while ((-not $?) -and ($install_attempt -lt 5))

            # Restore original Gemfile
            Set-Content "Gemfile" $gemfile_backup

            # Now install chef-bin separately using the same approach as other gems
            Write-BuildLine " ** Installing chef-bin gem now that chef is available"

            # Restore the original Gemfile so chef-bin is available for bundling
            Set-Content "Gemfile" $gemfile_backup

            # Change to chef-bin directory and install it using rake install:local
            Push-Location "$HAB_CACHE_SRC_PATH/$pkg_dirname/chef-bin"
            try {
                # Ensure gem environment points to vendor directory
                $env:GEM_HOME = "$pkg_prefix/vendor"
                $env:GEM_PATH = "$pkg_prefix/vendor;$ruby_gem_path"

                # Build chef-bin gem directly to ensure it has proper specs
                gem build chef-bin.gemspec

                # Install chef-bin directly using gem install to ensure specs are properly installed
                $chef_bin_gem = Get-ChildItem "pkg/chef-bin-*.gem" | Select-Object -First 1
                if (-not $chef_bin_gem) {
                    # Try in current directory
                    $chef_bin_gem = Get-ChildItem "chef-bin-*.gem" | Select-Object -First 1
                }

                if ($chef_bin_gem) {
                    Write-BuildLine "Installing chef-bin gem directly: $($chef_bin_gem.FullName)"
                    gem install $chef_bin_gem.FullName --no-document --local

                    # Make sure specs are properly installed
                    Copy-Item "$env:GEM_HOME/gems/chef-bin-$pkg_version/chef-bin.gemspec" "$env:GEM_HOME/specifications/chef-bin-$pkg_version.gemspec" -ErrorAction SilentlyContinue
                } else {
                    # Fallback to rake install:local if gem not found
                    Write-BuildLine "Falling back to rake install:local for chef-bin"
                    bundle exec rake install:local
                }

                # Force refresh the gem specification cache
                gem specification chef-bin --version=$pkg_version

                Write-BuildLine " -- chef-bin gem installed via direct gem install"
            } finally {
                Pop-Location
            }

        } finally {
            # Ensure we restore the original Gemfile even if something fails
            Set-Content "Gemfile" $gemfile_backup
        }    } finally {
        Pop-Location
    }
}

function Invoke-Install {
    write-output "*** invoke-install"
    try {
        Push-Location $pkg_prefix
        $env:BUNDLE_GEMFILE="${HAB_CACHE_SRC_PATH}/${pkg_dirname}/Gemfile"

        # Ensure gem environment is set up correctly for appbundler
        $ruby_version = "3.4.0"
        $ruby_gem_path = "$(Get-HabPackagePath ruby3_4-plus-devkit)/lib/ruby/gems/$ruby_version"
        $env:GEM_PATH = "$pkg_prefix/vendor;$ruby_gem_path"
        $env:GEM_HOME = "$pkg_prefix/vendor"



        # Copy all gem executables directly to bin directory - skip appbundler completely
        # since we're getting stack level too deep errors
        $binDir = "$pkg_prefix/bin"
        if (!(Test-Path $binDir)) {
            New-Item -Path $binDir -ItemType Directory -Force | Out-Null
        }

        # First copy chef-bin executables
        if (Test-Path "$env:GEM_HOME/gems/chef-bin-$pkg_version/bin") {
            Write-BuildLine "** Copying chef-bin executables directly to bin directory"
            Copy-Item "$env:GEM_HOME/gems/chef-bin-$pkg_version/bin/*" $binDir -Force
            Write-BuildLine " -- Chef-bin executables copied directly to bin directory"
        } else {
            Write-BuildLine " -- Warning: chef-bin/bin directory not found"
        }

        # Copy chef executables
        if (Test-Path "$env:GEM_HOME/gems/chef-$pkg_version-universal-mingw-ucrt/bin") {
            Write-BuildLine "** Copying chef executables directly to bin directory"
            Copy-Item "$env:GEM_HOME/gems/chef-$pkg_version-universal-mingw-ucrt/bin/*" $binDir -Force
            Write-BuildLine " -- Chef executables copied directly to bin directory"
        } elseif (Test-Path "$env:GEM_HOME/gems/chef-$pkg_version/bin") {
            Write-BuildLine "** Copying chef executables directly to bin directory"
            Copy-Item "$env:GEM_HOME/gems/chef-$pkg_version/bin/*" $binDir -Force
            Write-BuildLine " -- Chef executables copied directly to bin directory"
        } else {
            Write-BuildLine " -- Warning: chef/bin directory not found"
        }

        # Copy inspec-core-bin executables
        if (Test-Path "$env:GEM_HOME/gems/inspec-core-bin-*/bin") {
            Write-BuildLine "** Copying inspec-core-bin executables directly to bin directory"
            $inspecBin = Get-ChildItem "$env:GEM_HOME/gems" -Directory -Filter "inspec-core-bin-*" | Select-Object -First 1
            if ($inspecBin) {
                Copy-Item "$($inspecBin.FullName)/bin/*" $binDir -Force
                Write-BuildLine " -- Inspec-core-bin executables copied directly to bin directory"
            }
        } else {
            Write-BuildLine " -- Warning: inspec-core-bin/bin directory not found"
        }

        # Copy ohai executables
        if (Test-Path "$env:GEM_HOME/gems/ohai-*/bin") {
            Write-BuildLine "** Copying ohai executables directly to bin directory"
            $ohaiBin = Get-ChildItem "$env:GEM_HOME/gems" -Directory -Filter "ohai-*" | Select-Object -First 1
            if ($ohaiBin) {
                Copy-Item "$($ohaiBin.FullName)/bin/*" $binDir -Force
                Write-BuildLine " -- Ohai executables copied directly to bin directory"
            }
        } else {
            Write-BuildLine " -- Warning: ohai/bin directory not found"
        }

        # Create batch wrapper scripts for each bin file to ensure they can find their gems
        Write-BuildLine "** Creating batch wrapper scripts for bin files"
        $binFiles = Get-ChildItem $binDir -File
        foreach ($file in $binFiles) {
            # Skip files that are already batch files
            if ($file.Extension -eq ".bat" -or $file.Extension -eq ".cmd") {
                Write-BuildLine "   - Skipping existing batch file $($file.Name)"
                continue
            }

            # Create .bat wrapper script for each executable
            $batchWrapper = @"
@echo off
SET "GEM_HOME=${pkg_prefix}\vendor"
SET "GEM_PATH=${pkg_prefix}\vendor;$(Get-HabPackagePath ruby3_4-plus-devkit)/lib/ruby/gems/3.4.0"
SET "RUBYOPT="
SET "RUBY_DLL_PATH=$(Get-HabPackagePath ruby3_4-plus-devkit)/bin"
"%~dp0$($file.Name)" %*
"@
            # Create wrapper script with .bat extension
            $wrapperPath = "$binDir\$($file.BaseName).bat"
            Set-Content -Path $wrapperPath -Value $batchWrapper -Force
            Write-BuildLine "   - Created batch wrapper for $($file.Name)"
        }
        Write-BuildLine " -- Batch wrapper scripts created"

        Write-BuildLine "** Skipping appbundler due to stack level too deep errors"
        Remove-StudioPathFrom -File $pkg_prefix/vendor/gems/chef-$pkg_version*/Gemfile
    } finally {
        Pop-Location
    }
}

function Invoke-After {
    Write-BuildLine "*** Invoke After"
    # Trim the fat before packaging

    # We don't need the cache of downloaded .gem files ...
    Remove-Item $pkg_prefix/vendor/cache -Recurse -Force
    # ... or bundler's cache of git-ref'd gems
    Remove-Item $pkg_prefix/vendor/bundler -Recurse -Force

    # We don't need the gem docs.
    Remove-Item $pkg_prefix/vendor/doc -Recurse -Force
    # We don't need to ship the test suites for every gem dependency,
    # only Chef's for package verification.
    Get-ChildItem $pkg_prefix/vendor/gems -Filter "spec" -Directory -Recurse -Depth 1 `
        | Where-Object -FilterScript { $_.FullName -notlike "*chef-$pkg_version*" }   `
        | Remove-Item -Recurse -Force
    # Remove the byproducts of compiling gems with extensions
    Get-ChildItem $pkg_prefix/vendor/gems -Include @("gem_make.out", "mkmf.log", "Makefile") -File -Recurse `
        | Remove-Item -Force

    # we need the built gems outside of the studio
    Write-BuildLine "Copying gems to ${SRC_PATH}"
    New-Item -ItemType Directory -Force "${SRC_PATH}\pkg","${SRC_PATH}\chef-bin\pkg","${SRC_PATH}\chef-config\pkg","${SRC_PATH}\chef-utils\pkg"
    Copy-Item "${CACHE_PATH}\pkg\chef-${pkg_version}-universal-mingw-ucrt.gem" "${SRC_PATH}\pkg"
    Copy-Item "${CACHE_PATH}\chef-bin\pkg\chef-bin-${pkg_version}.gem" "${SRC_PATH}\chef-bin\pkg"
    Copy-Item "${CACHE_PATH}\chef-config\pkg\chef-config-${pkg_version}.gem" "${SRC_PATH}\chef-config\pkg"
    Copy-Item "${CACHE_PATH}\chef-utils\pkg\chef-utils-${pkg_version}.gem" "${SRC_PATH}\chef-utils\pkg"
}

function Remove-StudioPathFrom {
    Param(
        [Parameter(Mandatory=$true)]
        [String]
        $File
    )
    (Get-Content $File) -replace ($env:FS_ROOT -replace "\\","/"),"" | Set-Content $File
}
