# Self Documenting Resources

Chef has allowed organizations to embrace infrastructure as code, but with codified infrastructure comes the need for accurate documentation for that codebase. This RFC aims to improve the ability to document resources within Chef code, so that we can ensure documentation is accurate and automatically generated. This is applicable to both resources within chef-client and those which ship in cookbooks.

## Motivation

```
As an author of custom resources,
I want to manage code and documentation in a single location
so that I can have up to date documentation with minimal work

As a maintainer of chef
I want docs to automatically update when new chef-client releases are made
so that manual release steps and mistakes can be reduced

As a consumer of custom resources
I want accurate and up to date documentation
so that I can easily write cookbooks utilizing custom resources
```

## Specification

This design specifies 4 documentation methods in custom resources:

### description (resource level)

Description is a String value that allows the user to describe the resource and its functionality. This information would be similar to what you would expect to find in a readme or the Chef Docs site describing the usage of a resource.

### introduced (resource level)

Introduced is a String value that documents when the resource was introduced. In a cookbook, this would be a particular cookbook release. In the chef-client itself, this would be a chef-client release.

### examples (resource level)

Examples is a String value containing examples for how to use the resource. This allows the author to show and describe various ways the resource can be used.

### description (property level)

Description is a String value that documents the usage of the individual property. Useful information here would be allowed values, validation regexes, or input coercions.

### description (action level)

Description is a String that describes the functionality of the action.

## Example

```ruby
description 'The apparmor_policy resource is used to add or remove policy files from a cookbook file'

introduced '14.1'

property :source_cookbook,
         String,
         description: 'The cookbook to source the policy file from'
property :source_filename,
         String,
         description: 'The name of the source file if it differs from the apparmor.d file being created'

action :add do
  description 'Adds an apparmor policy'

  cookbook_file "/etc/apparmor.d/#{new_resource.name}" do
    cookbook new_resource.source_cookbook if new_resource.source_cookbook
    source new_resource.source_filename if new_resource.source_filename
    owner 'root'
    group 'root'
    mode '0644'
    notifies :reload, 'service[apparmor]', :immediately
  end

  service 'apparmor' do
    supports status: true, restart: true, reload: true
    action [:nothing]
  end
end
```

## Reasons for not using YARD

The goal of introducing minimal DSL changes is to extend the existing data already contained within each resource to include the necessary information to fully document resources. Documenting resources in YARD would require significant duplication of documentation, which most users probably won't do. Out of the box, even without these new DSL extensions, we can already document resources fairly well. These new extensions incentivize users to provide us with a small amount of additional information that would fully fill out the resource documentation. Within our own configuration management industry, other projects have gone different routes to document their equivalence of resources. One project uses a hybrid comment / code method, which feels bolted on and overly complex. The other project fully documents code in comments, which results in near 100% duplication of effort. Simple DSL extensions seem like they are more likely to be utilized and provide a better user experience.