<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->


### knife ssh has --exit-on-error option
`knife ssh` now has an --exit-on-error option that will cause it to
fail immediately in the face of an SSH connection error.  The default
behavior is move on to the next node.

### DSC Resource

The `dsc_resource` resource for Windows systems that allows cookbook authors to invoke [PowerShell Desired
State Configuration](http://technet.microsoft.com/en-us/library/dn249912.aspx) resources in Chef DSL.

#### Prerequisites

* **Windows Management Framework 5** February Preview
* **Local Configuration Manager** must be set to have a `RefreshMode` of `Disabled`

#### Syntax

```ruby
dsc_resource "description" do
  resource "resource_name"
  property :property_name, property_value
  ...
  property :property_name, property_value
end
```

#### Attributes

- `resource`: The friendly name of the DSC resource

- `property`: `:property_name`, `property_value` pair for each property that must be set for the DSC resource.
`property_name` must be of the `Symbol`. The following types are supported for `property_value`, along with
their conversion into Powershell:

| Ruby Type                           | Powershell Type |
|-------------------------------------|-----------------|
| Fixnum                              | Integer         |
| Float                               | Double          |
| FalseClass                          | bool($false)    |
| TrueClass                           | bool($true)     |
| Chef::Util::Powershell:PSCredential | PSCredential    |
| Hash                                | Hashtable       |
| Array                               | Object[]        |

- `module_name` is the name of the module that the DSC resource comes from. If it is not provided, it will
  be inferred.

#### Actions

|Action|Description|
|------|------------------------|
|`:run`| Invoke the DSC resource|

#### Example

```ruby
dsc_resource "demogroupremove" do
  resource :group
  property :groupname, 'demo1'
  property :ensure, 'present'
end
 
dsc_resource "useradd" do
  resource :user
  property :username, "Foobar1"
  property :fullname, "Foobar1"
  property :password, ps_credential("P@assword!")
  property :ensure, 'present'
end
 
dsc_resource "AddFoobar1ToUsers" do
  resource :Group
  property :GroupName, "demo1"
  property :MembersToInclude, ["Foobar1"]
end
```
