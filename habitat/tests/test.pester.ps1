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

        It "is the expected version" {
            $the_version = (hab pkg exec $PackageIdentifier chef-client.bat --version | Out-String).split(':')[1].Trim()
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

    Context "knife" {
        It "is an executable" {
            hab pkg exec $PackageIdentifier knife.bat --version
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