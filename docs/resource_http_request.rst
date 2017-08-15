=====================================================
http_request
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_http_request.rst>`__

.. tag resource_http_request_summary

Use the **http_request** resource to send an HTTP request (``GET``, ``PUT``, ``POST``, ``DELETE``, ``HEAD``, or ``OPTIONS``) with an arbitrary message. This resource is often useful when custom callbacks are necessary.

.. end_tag

Syntax
=====================================================
A **http_request** resource block sends HTTP requests with an arbitrary message. For example, send a ``DELETE`` request to ``'http://www.chef.io/some_page?message=please_delete_me'``.

.. code-block:: ruby

   http_request 'please_delete_me' do
     url 'http://www.chef.io/some_page'
     action :delete
   end

The full syntax for all of the properties that are available to the **http_request** resource is:

.. code-block:: ruby

   http_request 'name' do
     headers                    Hash
     message                    Object # defaults to 'name' if not specified
     notifies                   # see description
     provider                   Chef::Provider::HttpRequest
     subscribes                 # see description
     url                        String
     action                     Symbol # defaults to :get if not specified
   end

where

* ``http_request`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``headers``, ``message``, ``provider``, and ``url`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:delete``
   Send a ``DELETE`` request.

``:get``
   Default. Send a ``GET`` request.

   Changed in Chef Client 12.0 to deprecate the hard-coded query string from earlier versions. Cookbooks that rely on this string need to be updated to manually add it to the URL as it is passed to the resource.

``:head``
   Send a ``HEAD`` request.

   Changed in Chef Client 12.0 to deprecate the hard-coded query string from earlier versions. Cookbooks that rely on this string need to be updated to manually add it to the URL as it is passed to the resource.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:options``
   Send an ``OPTIONS`` request.

``:post``
   Send a ``POST`` request.

``:put``
   Send a ``PUT`` request.

Properties
=====================================================
This resource has the following properties:

``headers``
   **Ruby Type:** Hash

   A Hash of custom headers. Default value: ``{}``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``message``
   **Ruby Type:** Object

   The message that is sent by the HTTP request. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``url``
   **Ruby Type:** String

   The URL to which an HTTP request is sent.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Send a GET request**

.. tag resource_http_request_send_get

.. To send a GET request:

.. code-block:: ruby

   http_request 'some_message' do
     url 'http://example.com/check_in'
   end

The message is sent as ``http://example.com/check_in?message=some_message``.

.. end_tag

**Send a POST request**

.. tag resource_http_request_send_post

To send a ``POST`` request as JSON data, convert the message to JSON and include the correct content-type header. For example:

.. code-block:: ruby

   http_request 'posting data' do
     action :post
     url 'http://example.com/check_in'
     message ({:some => 'data'}.to_json)
     headers({'AUTHORIZATION' => "Basic #{
       Base64.encode64('username:password')}",
       'Content-Type' => 'application/data'
     })
   end

.. end_tag

**Transfer a file only when the remote source changes**

.. tag resource_remote_file_transfer_remote_source_changes

.. To transfer a file only if the remote source has changed (using the |resource http request| resource):

.. The "Transfer a file only when the source has changed" example is deprecated in chef-client 11-6

.. code-block:: ruby

   remote_file '/tmp/couch.png' do
     source 'http://couchdb.apache.org/img/sketch.png'
     action :nothing
   end

   http_request 'HEAD http://couchdb.apache.org/img/sketch.png' do
     message ''
     url 'http://couchdb.apache.org/img/sketch.png'
     action :head
     if File.exist?('/tmp/couch.png')
       headers 'If-Modified-Since' => File.mtime('/tmp/couch.png').httpdate
     end
     notifies :create, 'remote_file[/tmp/couch.png]', :immediately
   end

.. end_tag
