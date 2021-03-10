param(
    [Parameter()]
    [string]$PackageIdentifier = $(throw "Usage: test.ps1 [test_pkg_ident] e.g. test.ps1 ci/user-windows-default/1.0.0/20190812103929")
)

$PackageVersion = $PackageIdentifier.split('/')[2]

Describe "chef-infra-client" {
    Context "chef-client" {
        It "is an executable" {
            hab pkg exec $PackageIdentifier chef-client.bat --version
            $? | Should be $true
        }

        <#
          At some point hab's argument parsing changed and it started interpreting the trailing `--version` as being
          an argument passed to hab instead of an argument to the command passed to `hab pkg exec`.

          Powershell 5.1 and 7 appear to differ in how they treat following arguments as well, such that these two
          versions of the command fail in powershell 5.1 (which is currently what is running in the windows machines
          in Buildkite) but pass in powershell 7 (which is currently what is running in a stock Windows 10 VM).

          $the_version = (hab pkg exec $PackageIdentifier chef-client.bat '--version' | Out-String).split(':')[1].Trim()
          $the_version = (hab pkg exec $PackageIdentifier chef-client.bat --version | Out-String).split(':')[1].Trim()

          This version of the command passes in powershell 5.1 but fails in powershell 7.
        #>
        It "is the expected version" {
            $the_version = (hab pkg exec $PackageIdentifier chef-client.bat -- --version | Out-String).split(':')[1].Trim()
            $the_version | Should be $PackageVersion
        }
    }

    Context "ohai" {
        It "is an executable" {
            hab pkg exec $PackageIdentifier ohai.bat --version
            $? | Should be $true
        }
    }

    Context "chef-shell" {
        It "is an executable" {
            hab pkg exec $PackageIdentifier chef-shell.bat --version
            $? | Should be $true
        }
    }

    Context "chef-apply" {
        It "is an executable" {
            hab pkg exec $PackageIdentifier chef-apply.bat --version
            $? | Should be $true
        }
    }

    Context "chef-solo" {
        It "is an executable" {
            hab pkg exec $PackageIdentifier chef-solo.bat --version
            $? | Should be $true
        }
    }
}
