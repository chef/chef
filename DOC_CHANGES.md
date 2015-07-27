<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

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
describe what changed) and deeper custom resources (ones that don't use recipes,
which we'll cover later).
