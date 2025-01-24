$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

$pkg_name="knife"
$pkg_origin="core"
$pkg_description="knife is a command-line tool that provides an interface between a local chef-repo and the Chef Infra Server."
$pkg_version="18.5.11"
$pkg_revision="1"
$pkg_maintainer="The Chef Maintainers <humans@chef.io>"

$pkg_deps=@(
  "chef/ruby31-plus-devkit"
  "core/git"
)
$pkg_bin_dirs=@("bin"
                "vendor/bin")
$project_root= (Resolve-Path "$PLAN_CONTEXT/../").Path

function Invoke-SetupEnvironment {
    Push-RuntimeEnv -IsPath GEM_PATH "$pkg_prefix/vendor"
    Set-RuntimeEnv APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
    Set-RuntimeEnv FORCE_FFI_YAJL "ext"
    Set-RuntimeEnv LANG "en_US.UTF-8"
    Set-RuntimeEnv LC_CTYPE "en_US.UTF-8"
}

function Invoke-Build {
    try {
        $env:Path += ";c:\\Program Files\\Git\\bin"
        Push-Location $project_root
        $env:GEM_HOME = "$HAB_CACHE_SRC_PATH/$pkg_dirname/vendor"

        Write-BuildLine " ** Configuring bundler for this build environment"
        bundle config --local without integration deploy maintenance
        bundle config --local jobs 4
        bundle config --local retry 5
        bundle config --local silence_root_warning 1
        Write-BuildLine " ** Using bundler to retrieve the Ruby dependencies"
        bundle install

        gem build knife.gemspec
        Write-BuildLine " ** Using gem to  install"
        gem install knife-*.gem --no-document

        Write-BuildLine " ** Installing knife driver"
        gem install knife-vcenter
        gem install knife-vrealize
        gem install knife-vsphere
        gem install knife-azure
        gem install knife-ec2
        gem install knife-google
        gem install knife-windows

        If ($lastexitcode -ne 0) { Exit $lastexitcode }
    } finally {
        Pop-Location
    }
}

function Invoke-Install {
    Write-BuildLine "** Copying built & cached gems from two directories up to the install directory"
    # Adjusting the source path to copy two levels up, similar to do_unpack
    Copy-Item -Path "$PLAN_CONTEXT/../.." -Destination "$HAB_CACHE_SRC_PATH/$pkg_dirname" -Recurse -Force

    Write-BuildLine "** Copying from cache to install directory"
    Copy-Item -Path "$HAB_CACHE_SRC_PATH/$pkg_dirname/*" -Destination $pkg_prefix -Recurse -Force -Exclude @("gem_make.out", "mkmf.log", "Makefile",
                     "*/latest", "latest",
                     "*/JSON-Schema-Test-Suite", "JSON-Schema-Test-Suite")

    try {
        Push-Location $pkg_prefix
        bundle config --local gemfile $project_root/Gemfile
        Write-BuildLine "** Generating binstubs for knife with precise version pins"
        Write-BuildLine "** Generating binstubs for knife with precise version pins $project_root $pkg_prefix/bin"
        Invoke-Expression -Command "appbundler.bat $project_root $pkg_prefix/bin knife"
        If ($lastexitcode -ne 0) { Exit $lastexitcode }
        Write-BuildLine "** Running the knife project's 'rake install' to install the path-based gems so they look like any other installed gem."

        If ($lastexitcode -ne 0) { Exit $lastexitcode }
    } finally {
        Pop-Location
    }
}

function Invoke-After {
    # We don't need the cache of downloaded .gem files ...
    Remove-Item $pkg_prefix/vendor/cache -Recurse -Force
    # We don't need the gem docs.
    Remove-Item $pkg_prefix/vendor/doc -Recurse -Force
    # We don't need to ship the test suites for every gem dependency,
    # only inspec's for package verification.
    Get-ChildItem $pkg_prefix/vendor/gems -Filter "spec" -Directory -Recurse -Depth 1 `
        | Where-Object -FilterScript { $_.FullName -notlike "*knife*" }             `
        | Remove-Item -Recurse -Force
    # Remove the byproducts of compiling gems with extensions
    Get-ChildItem $pkg_prefix/vendor/gems -Include @("gem_make.out", "mkmf.log", "Makefile") -File -Recurse `
        | Remove-Item -Force
}