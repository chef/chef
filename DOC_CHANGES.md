<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### client.rb named run list setting

Policyfiles allow for multiple named run lists to be specified. To use
them in chef-client, one can either specify them on the command line
with:

```
chef-client --named-run-list NAME
```

or use the short option:

```
chef-client -n NAME
```

or specify the named run list in client.rb:

```ruby
named_run_list "NAME"
```

NOTE: ChefDK has supported named run lists in policyfiles for a few
releases, but is affected by a bug where named run lists can be deleted
from a Policyfile.lock.json during the upload. The fix will likely be
included in ChefDK 0.8.0. See: https://github.com/chef/chef-dk/pull/520

### client.rb policyfile settings

Chef client can be configured to run in policyfile mode by setting
`policy_name` and `policy_group` in client.rb. In order to use
policyfiles, _both_ settings should be set. Example:

```ruby
policy_name "appserver"
policy_group "staging"
```

As of Chef Client 12.5, when used in conjunction with Chef Server 12.3,
these settings can instead be set directly on the node object. Setting
them via the node JSON as described below will result in Chef Client
creating the node object with these settings.

### `chef-client -j JSON`

Chef client node JSON can now be used to specify the policyfile settings
`policy_name` and `policy_group`, like so:

```json
{
  "policy_name": "appserver",
  "policy_group": "staging"
}
```

Doing so will cause `chef-client` to switch to policyfile mode
automatically (i.e., the `use_policy` flag in `client.rb` is not
required).

Users who wish to take advantage of this functionality should upgrade
the Chef Server to at least 12.3, which is the first Chef Server release
capable of storing `policy_name` and `policy_group` in the node data.

### PSCredential Support for `dsc_script`

`dsc_script` now supports the use of `ps_credential` to create a PSCredential
object similar to `dsc_resource`. The `ps_credential` helper function takes in
a string and when `to_s` is called on it, produces an object that can be embedded
in your `dsc_script`. For example, you can write:

```ruby
dsc_script 'create-foo-user' do
  code <<-EOH
     User FooUser
     {
       UserName = 'FooUser'
       Password = #{ps_credential('FooBarBaz1!')}
     }
  EOH
  configuration_data <<-EOH
    @{
      AllNodes = @(
        @{
          NodeName = "localhost";
          CertificateID = 'A8DB81D8059F349F7EF19104399B898F701D4167'
        }
      )
    }
  EOH
end
```

Note, you **MUST** still do a one-time configuration of the `CertificateID` used in the recipe above with the DSC Local Configuration Manager (LCM) before this recipe fragment will succeed. The following Chef code could be used to configure the LCM to use the certificate `A8DB81D8059F349F7EF19104399B898F701D4167` stored in the Windows certificate store location `cert:localmachine\my`:

```ruby
lcm_cert_thumbprint = 'A8DB81D8059F349F7EF19104399B898F701D4167'

powershell_script 'lcm_cert_script' do
  code <<-EOH
Configuration 'lcm_cert_configuration' {
    node 'localhost' {
        localconfigurationmanager {
            CertificateID = "#{lcm_cert_thumbprint}"
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $false
            RefreshMode = 'PUSH'
        }
    }
}

lcm_cert_configuration

set-dsclocalconfigurationmanager -path .\\lcm_cert_configuration
EOH

  not_if "(Get-DscLocalConfigurationManager).certificateid -eq '#{lcm_cert_thumbprint}'"
end
```

### chef-client -j JSON
Add to the [description of chef-client options](https://docs.chef.io/ctl_chef_client.html#options):

> This option can also be used to set a node's `chef_environment`. For example,
running `chef-client -j /path/to/file.json` where `/path/to/file.json` is
similar to:
```
{
  "chef_environment": "pre-production"
}
```
will set the node's environment to `"pre-production"`.

> *Note that the environment specified by `chef_environment` in your JSON will
take precedence over an environment specified by `-E ENVIROMENT` when both options
are provided.*

### Resources Made Easy

Resources are central to Chef. The system is extensible so that you can write
your own reusable resources, and use them in your recipes, and even publish them
so that others can use them too!

However, writing these resources has not been as easy as we would have liked. In
Chef 12.5, we are fixing this with a large number of DSL improvements designed
to reduce the number of things you need to type and think about when you create
a resource. Resources should be your go-to solution for many Chef problems, and
these changes make them easy enough to dash off in an instant, while retaining
all the power you're accustomed to.

The process to create a resource is now:

1. Make a resource file in your cookbook (like `resources/my_resource.rb`).
2. Add the recipes defining your actions using the `action :create <recipe>` DSL.
3. Add properties so the user can tweak some knobs on your resource (like paths,
   or preferences), using the `property :my_property, <type>, <options>` DSL.
4. Use the resource in your recipe!

There are other things you can do, but this is the most basic (and the first)
thing you will start with.

Let's demonstrate the new features by taking a simple recipe from the awesome
[learnchef tutorial](https://learn.chef.io/learn-the-basics/rhel/configure-a-package-and-service/),
and turning it into a reusable resource:

```ruby
package 'httpd'

service 'httpd' do
  action [:enable, :start]
end

file '/var/www/html/index.html' do
  content '<html>
  <body>
    <h1>hello world</h1>
  </body>
</html>'
end

service 'iptables' do
  action :stop
end
```

We'll design a resource that lets you write this recipe instead:

```ruby
single_page_website 'mysite' do
  homepage '<html>
    <body>
      <h1>hello world</h1>
    </body>
  </html>'
end
```

#### Declaring the Resource

The first thing we do is declare the resource. We can do that by creating an
empty file, `resources/single_page_website.rb`, in our cookbook.

When you do this, the `single_page_website` resource will work in all recipes!

```ruby
single_page_website 'mysite'
```

It won't do anything yet, though :)

#### Declaring an Action

Let's make our resource do something. To start with, we'll just have it do exactly
what the learnchef tutorial does, but in the resource.  Put this in
`resources/single_page_website.rb`:

```ruby
action :create do
  package 'httpd'

  service 'httpd' do
    action [:enable, :start]
  end

  file '/var/www/html/index.html' do
    content '<html>
      <body>
        <h1>hello world</h1>
      </body>
    </html>'
  end

  service 'iptables' do
    action :stop
  end
end
```

Now, your simple recipe can use this resource to do what learnchef did:

```ruby
single_page_website 'mysite'
```

We've got ourselves an httpd!

You will notice the only thing we've done is to add `action :create` around the
recipe. The `action` keyword lets you declare a recipe inline, which will be
executed when the user uses your resource in a recipe.

#### Declaring a resource property: "homepage"

This isn't super reusable yet--you might want your webpage to say something other
than "hello world".  Let's add a couple of properties for that, by putting this
at the top of `resources/single_page_website`, and modifying the recipe to use
"title" and "body":

```ruby
property :homepage, String, default: '<h1>hello world</h1>'

action :create do
  package 'httpd'

  service 'httpd' do
    action [:enable, :start]
  end

  file '/var/www/html/index.html' do
    content homepage
  end

  service 'iptables' do
    action :stop
  end
end
```

Now you can run this recipe:

```ruby
single_page_website 'mysite' do
  homepage '<h1>My own page</h1>'
end
```

And you've got a website with your stuff!

What you've done here is add *properties*. Properties are the *desired state* of
a resource, in this case, `homepage` defines the text on the website. When you
add a property, you're letting a user give it whatever value they want.

When you define a property, there are three bits:
`property :<name>, <type>, <options>`. *Name* defines the name of the property,
so that people can set the property using `name <value>` when they use your
resource. *Type* defines the type of the property: for example, String, Integer
and Array are all possible types. Type is optional. *Options* define a large
number of validation and other options. You've seen `default` already now,
but there are a ton of others.

#### Adding another property: "not_found_page"

What if we want a custom 404 page for when people try to go to other pages in
our website? Let's add one more property, to make this even nicer:

```ruby
property :homepage, String, default: '<h1>hello world</h1>'
property :not_found_page, String, default: '<h1>No such page! Sorry. 404.</h1>'

action :create do
  package 'httpd'

  service 'httpd' do
    action [:enable, :start]
  end

  file '/var/www/html/index.html' do
    content homepage
  end

  # These together tell Apache to use your custom 404 page:
  file '/var/www/html/404.html' do
    content not_found_page
  end
  file '/var/www/html/.htaccess' do
    content 'ErrorDocument 404 /404.html'
  end

  service 'iptables' do
    action :stop
  end
end
```

Now you can run this recipe:

```ruby
single_page_website 'mysite' do
  homepage '<h1>My own page</h1>'
  not_found_page '<h1>Grr. Page not found. Sorry. (404)</h1>'
end
```

#### Adding another action: "stop"

What if we want to stop the website? Just add another action into the bottom of
`resources/single_page_website.rb`:

```ruby
action :stop do
  service 'httpd' do
    action :stop
  end
end
```

This action looks a lot like the other.

There are a ton of other things you can do to create resources, but this should
give you a pretty basic idea.

### Advanced Resource Capabilities

#### Ruby Developers: Resources as Classes

If you are a Ruby developer, we've made it easier to create a Resource outside
of a cookbook (or in a library) by declaring a class! Declare
`class SinglePageWebsite < Chef::Resource` and put the entire resource
declaration inside, and the `single_page_website` resource will work!

#### Reading the current value: load_current_value

There is a pitfall inherent in a resource, where users will sometimes omit a
property from a resource, and become surprised when the system overwrites it
with the default! For example, if your website already exists, this recipe
will replace the *homepage* with "hello world":

```ruby
single_page_website 'mysite' do
  not_found_page '<h1>nice</h1>'
end
```

It's not at all clear that that's what the user wanted--they didn't say anything
about the homepage, so why did something happen to it?

To guard against this, you can implement `load_current_value` in your resource.
Put this in `resources/single_page_website.rb`:

```ruby
load_current_value do
  if File.exist?('/var/www/html/index.html')
    homepage IO.read('/var/www/html/index.html')
  end
  if File.exist?('/var/www/html/404.html')
    not_found_page IO.read('/var/www/html/404.html')
  end
end
```

Now, the above recipe knows what the current homepage is, and will not change it!

This capability is also used for several other things, including reporting (to
describe what changed) and pure Ruby actions.

#### Pure Ruby Actions

Some resources need to talk directly to Ruby to do their dirty work, rather than using other resources. In those cases, you need to:

- Make the updates only if the user specified properties that *need* to change.
- Make sure and call updates if the resource does not exist (need to be created).
- Print useful green text if the update is happening.
- Not actually make any changes in why-run mode!

`converge_if_changed` handles all of the above by comparing the user's desired
property values against the *current* value as loaded by `load_current_value`.
Simply wrap the part of your recipe that does a set in `converge_if_changed`.
As an example, here is a basic `my_file` resource that creates a file with the
given content:

```ruby
# resources/my_file.rb
property :path, String, name_property: true
property :content, String

load_current_value do
  if File.exist?(path)
    content IO.read(path)
  end
end

action :create do
  converge_if_changed do
    IO.write(path, content)
  end
end
```

The above code will only call `IO.write` if the file does not exist, or if the
user specified content that is different from what is on disk. It will print out
something like this, showing the changes:

```ruby
Recipe: basic_chef_client::block
  * my_file[blah] action create
    - update my_file[blah]
    -   set content to "hola mundo" (was "hello world")
 ```

##### Handling Multiple Operations

If you have two separate, expensive operations to handle converge, `converge_if_changed`
can be called multiple times with multiple properties. Adding `mode` to `my_file`
demonstrates this:

```ruby
# resources/my_file.rb
property :path, String, name_property: true
property :content, String
property :mode, String

load_current_value do
  if File.exist?(path)
    content IO.read(path)
    mode File.stat(path).mode
  end
end

action :create do
  # Only change content here
  converge_if_changed :content do
    IO.write(path, content)
  end
  # Only change mode here
  converge_if_changed :mode do
    File.chmod(mode, path)
  end
end
```
