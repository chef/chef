# Chef Client Release Notes 12.2.0:

## Policyfile Chef Server 12.0.7 Compatibility

Chef Server 12.0.7 will contain the minimum necessary funtioning
implementation of Policyfiles to converge a node. Policyfile "native
mode" is updated to work with the APIs in Chef Server 12.0.7. Note that
Chef Server 12.0.7 will likely not ship with the necessary code to
upgrade existing organizations, so you will need to set some special
configuration to opt-in to enabling the Policyfile APIs in Chef Server.
That process will be described in the release notes for Chef Server.

## Desired State Configuration (DSC) Resource

If you are using `Windows Management Framework(WMF) 5`, you can now take advantage of the new `dsc_resource`. 
This new functionality takes advantage of WMF 5's `Invoke-DscResource` cmdlet to
directly invoke resources.

### Prerequisites

To use this new resource, you must have the February preview of WMF 5.
This can be installed using the Powershell cookbook. It is also required that
the Local Configuration Manager(LCM) be configured with a `RefreshMode` of `Disabled`.
Doing this will preclude you from using `dsc_script`. Below we provide an example
DSC configuration:

```powershell
# create a configuration command to generate a meta.mof to set Local Configuration Manager settings

Configuration LCMSettings {
  Node localhost {
    LocalConfigurationManager {
      RefreshMode = 'Disabled'
    }
  }
}

# Run the configuration command and generate the meta.mof to configure a local configuration manager
LCMSettings
# Apply the local configuration manager settings found in the LCMSettings folder (by default configurations are generated 
# to a folder in the current working directory named for the configuration command name
Set-DscLocalConfigurationManager -path ./LCMSettings
```

Running this script tells the LCM not to do document management, allowing Chef to
take over that role. While you may be able to switch this to other values mid-run,
you should not be doing this to run both `dsc_script` and `dsc_resource` resources.

### Usage

Once the LCM is correctly configured, you can begin using `dsc_resource` in your recipes.
You can get a list of available by running the `Get-DscResource` command. You will be
able to use any resource that does not have an `ImplementedAs` property with value 
`Composite`.

As an example, let's consider the `User` dsc resource. Start by taking a look
at what a DSC `User` resource would look like

```
> Get-DscResource User

ImplementedAs   Name                      Module                         Properties
-------------   ----                      ------                         ----------
PowerShell      User                      PSDesiredStateConfiguration    {UserName, DependsOn, Descr...

```

We see here that is `ImplementedAs` is not equal to `Composite`, so it is a resource that can
be used with `dsc_resource`. We can what properties are accpeted by the `User` resource by
running

```
> Get-DscResource User -Syntax

User [string] #ResourceName
{
    UserName = [string]
    [ DependsOn = [string[]] ]
    [ Description = [string] ]
    [ Disabled = [bool] ]
    [ Ensure = [string] { Absent | Present }  ]
    [ FullName = [string] ]
    [ Password = [PSCredential] ]
    [ PasswordChangeNotAllowed = [bool] ]
    [ PasswordChangeRequired = [bool] ]
    [ PasswordNeverExpires = [bool] ]
}
```

From above, the `User` resource has a require property `UserName`, however we're probably
also going to want to prover at the very least a `Password`. From above, we can see the `UserName` 
property must be of type string, and `Password` needs to be of type `PSCredential`. Since there
is no native Ruby type that maps to a Powershell PSCredential, a dsl method `ps_credential` is
provided that makes creating this simple. `ps_credential` can be called as `ps_credential(password)`
or `ps_credential(username, password)`. Under the hood, this creates a 
`Chef::Util::Powershell::PSCredential` which gets serialized into a Powershell PSCredential.

The following type translations are supported:

| Ruby Type                           | Powershell Type |
|-------------------------------------|-----------------|
| Fixnum                              | Integer         |
| Float                               | Double          |
| FalseClass                          | bool($false)    |
| TrueClass                           | bool($true)     |
| Chef::Util::Powershell:PSCredential | PSCredential    |
| Hash                                | Hashtable       |
| Array                               | Object[]        |

With this information in hand, we can now construct a Chef `dsc_resource` resource that creates
a user.

```ruby
dsc_resource 'create foo user' do
  resource :User
  property :UserName, 'FooUser'
  property :Password, ps_credential("P@ssword!")
  property :Ensure, 'Present'
end
```

#### Third Party Resources
`dsc_resource` also supports the use of 3rd party DSC resources, for example the DSC Resource Kit. These
resources can be used just like you would use any `PSDesiredStateConfiguration` resource like `User`. Since
the implementation of `dsc_resource` knows how to talk to DSC resources that are visible through the
`Get-DscResource` cmdlet, it should just work. For example, if we wanted to use `xSmbShare`, we could
construct the powershell resource as

```ruby
dsc_resource 'create smb share' do
  resource :xSmbShare
  property :Name, 'Foo'
  property :Path, 'C:\Foo'
end
```

This would execute 

```
> Get-DscResource xSmbShare

ImplementedAs   Name                      Module                         Properties
-------------   ----                      ------                         ----------
PowerShell      xSmbShare                 xSmbShare                      {Name, Path, ChangeAccess, ...
```

to look up the module name, and in this case use `xSmbShare`. However, this lookup process can slow down
the process. It is also possible that there are multiple DSC resources with that name. To address these
cases, `dsc_resource` provides an aditional attribute `module_name`. You can pass the name of the module
that the resource comes from, and `dsc_resource` will make sure that it uses that module. This will
short-circuit any logic to lookup the module name, shortening the time it takes to execute the resource.

## Notes

- The implementation of `dsc_resource` is base on the experimental Invoke-DscResource cmdlet
