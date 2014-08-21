<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### environment attribute to git provider

Similar to other environment options:

```
environment     Hash of environment variables in the form of {"ENV_VARIABLE" => "VALUE"}.
```

Also the `user` attribute should mention the setting of the HOME env var:

```
user      The system user that is responsible for the checked-out code.  The HOME environment variable will automatically be
set to the home directory of this user when using this option.
```

### Metadata `name` Attribute is Required.

Current documentation states:

> The name of the cookbook. This field is inferred unless specified.

This is no longer correct as of 12.0. The `name` field is required; if
it is not specified, an error will be raised if it is not specified.
### chef-zero port ranges

- to avoid crashes, by default, Chef will now scan a port range and take the first available port from 8889-9999.
- to change this behavior, you can pass --chef-zero-port=PORT_RANGE (for example, 10,20,30 or 10000-20000) or modify Chef::Config.chef_zero.port to be a po
rt string, an enumerable of ports, or a single port number.

### Encrypted Data Bags Version 3

Encrypted Data Bag version 3 uses [GCM](http://en.wikipedia.org/wiki/Galois/Counter_Mode) internally. Ruby 2 and OpenSSL version 1.0.1 or higher are required to use it.

### New windows_service resource

The windows_service resource inherits from the service resource and has all the same options but adds an action and attribute.

action :configure_startup - sets the startup type on the resource to the value of the `startup_type` attribute
attribute startup_type - the value as a symbol that the startup type should be set to on the service, valid options :automatic, :manual, :disabled

Note that the service resource will also continue to set the startup type to automatic or disabled, respectively, when the enabled or disabled actions are used.
