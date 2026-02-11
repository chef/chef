$env:HAB_BLDR_CHANNEL = "base-2025"
$pkg_name="chef-infra-client"
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
  "core/xz"
  "core/libarchive"
  "core/ruby3_4-plus-devkit/3.4.8"
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
    Push-RuntimeEnv -IsPath RUBY_DLL_PATH "$(Get-HabPackagePath xz)/bin"

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

        # Ensure gem environment is set up correctly for appbundler
        $ruby_version = "3.4.0"
        $ruby_gem_path = "$(Get-HabPackagePath ruby3_4-plus-devkit)/lib/ruby/gems/$ruby_version"
        $env:GEM_PATH = "$pkg_prefix/vendor;$ruby_gem_path"
        $env:GEM_HOME = "$pkg_prefix/vendor"

        $env:_BUNDLER_WINDOWS_DLLS_COPIED = "1"

        $openssl_dir = "$(Get-HabPackagePath core/openssl)"
        gem install openssl:3.3.0 -- --with-openssl-dir=$openssl_dir --with-openssl-include="$openssl_dir/include" --with-openssl-lib="$openssl_dir/lib"

        Write-BuildLine " ** Using bundler to retrieve the Ruby dependencies"
        bundle install --jobs=3 --retry=3
        if (-not $?) { throw "unable to install gem dependencies" }

        Write-BuildLine " ** Cleaning up lint_roller Gemfile.lock"
        ruby .\scripts\cleanup_lint_roller.rb

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
        foreach($path_gem in @("chef-utils", "chef-config", "chef", "chef-bin")) {
            Write-BuildLine " -- installing $path_gem gem"

            if ($path_gem -ne "chef") {
                $path_gem_path = "${HAB_CACHE_SRC_PATH}/${pkg_dirname}/$path_gem"
                Push-Location $path_gem_path
            }

            try {
                bundle exec rake build --trace=stdout
                if (-not $?) { throw "unable to build $path_gem gem" }

                $built_gem = Get-ChildItem "pkg/$path_gem-*.gem" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($built_gem) {
                    Write-BuildLine "Installing $path_gem gem from $($built_gem.Name)"
                    gem install --local $built_gem.FullName
                    if (-not $?) { throw "unable to install built $path_gem gem from $($built_gem.FullName)" }
                } else {
                    throw "unable to locate built $path_gem gem"
                }
            } finally {
                if ($path_gem -ne "chef") {
                    Pop-Location
                }
            }
        }

    } finally {
        Pop-Location
    }
}

function Invoke-Install {
    write-output "*** invoke-install"

    # Copy NOTICE to the package directory
    $NoticeFile = "$PLAN_CONTEXT\..\..\NOTICE"

    if (Test-Path $NoticeFile) {
        Write-BuildLine "** Copying NOTICE to package directory"
        Copy-Item -Path $NoticeFile -Destination $pkg_prefix -Force
    } else {
        Write-BuildLine "** Warning: NOTICE not found at $NoticeFile"
    }

    try {
        Push-Location $pkg_prefix
        $env:BUNDLE_GEMFILE="${HAB_CACHE_SRC_PATH}/${pkg_dirname}/Gemfile"

        # Ensure gem environment is set up correctly for appbundler
        $ruby_version = "3.4.0"
        $ruby_gem_path = "$(Get-HabPackagePath ruby3_4-plus-devkit)/lib/ruby/gems/$ruby_version"
        $env:GEM_PATH = "$pkg_prefix/vendor;$ruby_gem_path"
        $env:GEM_HOME = "$pkg_prefix/vendor"

        # Test artifactory access and install chef-official-distribution if accessible
        Write-BuildLine "******* Testing access to artifactory*****"
        $ArtifactoryUrl = "https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local/"
        try {
            $null = Invoke-WebRequest -Uri $ArtifactoryUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            Write-BuildLine "******* Artifactory is accessible, installing chef-official-distribution gem*****"
            gem sources --add $ArtifactoryUrl
            gem install chef-official-distribution
            gem sources --remove $ArtifactoryUrl

            # Verify chef-official-distribution installation
            Write-BuildLine "******* Verifying chef-official-distribution installation******"
            gem list chef-official-distribution
            If ($lastexitcode -ne 0) { Exit $lastexitcode }
        } catch {
            Write-BuildLine "******* Artifactory is not accessible, skipping chef-official-distribution installation*****"
            Write-BuildLine "******* Error: $($_.Exception.Message)*****"
        }

        foreach($gem in ("chef-bin", "chef", "inspec-core-bin", "ohai")) {
            Write-BuildLine "** generating binstubs for $gem with precise version pins"
            appbundler.bat "${HAB_CACHE_SRC_PATH}/${pkg_dirname}" $pkg_prefix/bin $gem
            if (-not $?) { throw "Failed to create appbundled binstubs for $gem"}
        }

        Write-BuildLine "** patching binstubs to allow running directly"
        Get-ChildItem -Path "$pkg_prefix\bin\*.bat" -File | ForEach-Object {
            $binstub = $_.FullName
            $binstubName = $_.Name
            Write-BuildLine "Before patching ${binstubName}:"
            Get-Content $binstub -TotalCount 20

            # Read the .bat file content
            $content = Get-Content $binstub -Raw

            # Read the patch content from binstub_patch.bat
            $envLoaderBat = Get-Content "$PLAN_CONTEXT\binstub_patch.bat" -Raw

            # Replace @ECHO OFF with @ECHO OFF followed by the environment loader
            $content = $content -replace '(?m)^@ECHO OFF', "@ECHO OFF`r`n$envLoaderBat"

            # Write back to the file
            Set-Content -Path $binstub -Value $content -NoNewline

            Write-BuildLine "After patching ${binstubName}:"
            Get-Content $binstub -TotalCount 30
        }

        Remove-StudioPathFrom -File $pkg_prefix/vendor/gems/chef-$pkg_version*/Gemfile
    } finally {
        Pop-Location
    }
}

function Invoke-After {
    write-output "*** invoke after"
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
    write-output "Copying gems to ${SRC_PATH}"
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
