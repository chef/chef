==========================================
windows_task
==========================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_windows_task.rst>`__

Use the **windows_task** resource to create, delete or run a Windows scheduled task. Requires Windows Server 2008 due to API usage.

*New in Chef Client 13.*

.. note:: ``:change`` action has been removed from ``windows_task`` resource. ``:create`` action can be used to update an existing task.

Syntax
==========================================
A **windows_task** resource creates, deletes or runs a Windows scheduled task.

.. code-block:: ruby

   windows_task 'name' do
     task_name                   String
     command                     String
     cwd                         String
     user                        String # defaults to SYSTEM
     password                    String
     run_level                   Symbol # defaults to :limited
     force                       TrueClass, FalseClass # defauls to false
     interactive_enabled         TrueClass, FalseClass # defauls to false
     frequency_modifier          Integer, String # defaults to 1
     frequency                   Symbol # defaults to :hourly
     start_day                   String
     start_time                  String
     day                         String, Integer
     months                      String
     idle_time                   Integer
     random_delay                String
     execution_time_limit        String
   end

where

* ``windows_task`` is the resource
* ``'name'`` is the name of the resource block
* ``command`` is the command to be executed by the windows scheduled task.
* ``frequency`` is the frequency with which to run the task. (default is :hourly. Other valid values include :minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :on_idle) :once requires start_time
* ``frequency_modifier`` Multiple for frequency. (15 minutes, 2 days). Monthly tasks may also use these values": ('FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY')

Actions
=====================================================
This resource has the following actions:

``:create``
   creates a task (or updates existing if user or command has changed)

``:delete``
   deletes a task

``:run``
   runs a task

``:end``
   ends a task

``:enable``
   enables a task

``:disable``
   disables a task

Properties
=====================================================
This resource has the following properties:

``task_name``
   **Ruby Type:** String
   Name attribute, The task name. ("Task Name" or "/Task Name")

``force``
   **Ruby Type:** TrueClass, FalseClass
   When used with create, will update the task.

``cwd``
   **Ruby Type:** String
   The directory the task will be run from.

``user``
   **Ruby Type:** String
   The user to run the task as. (defaults to 'SYSTEM')

``password``
   **Ruby Type:** String
   The user's password. (requires user)

``run_level``
   **Ruby Type:** Symbol
   Run with :limited or :highest privileges. Default is :limited.

``frequency``
   **Ruby Type:** Symbol
   Frequency with which to run the task (default is :hourly. Other valid values include :minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :on_idle).
   :once requires start_time.

``frequency_modifier``
   **Ruby Type:** Integer, String
   Multiple for frequency. (15 minutes, 2 days). Monthly tasks may also use these values": ('FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY')

``start_day``
   **Ruby Type:** String
   Specifies the first date on which the task runs. Optional string (MM/DD/YYYY)

``start_time``
   **Ruby Type:** String
   Specifies the start time to run the task. Optional string (HH:mm)

``interactive_enabled``
   **Ruby Type:** TrueClass, FalseClass
   Allow task to run interactively or non-interactively. Requires user and password.

``day``
   **Ruby Type:** String
   For monthly or weekly tasks, the day(s) on which the task runs. (MON - SUN, \* ,1 - 31)

``months``
   **Ruby Type:** String
   The Months of the year on which the task runs. (JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, \*). Multiple months should be comma delimited.

``idle_time``
   **Ruby Type:** Integer
   For :on_idle frequency, the time (in minutes) without user activity that must pass to trigger the task. (1 - 999)

Examples
=====================================================

.. tag windows_task_examples

**Create a scheduled task to run every 15 minutes**

.. code-block:: ruby

   windows_task 'chef-client' do
     user 'Administrator'
     password 'password'
     command 'chef-client'
     run_level :highest
     frequency :minute
     frequency_modifier 15
   end

**Create a scheduled task to run every 2 days**

.. code-block:: ruby

   windows_task 'chef-client' do
     user 'Administrator'
     password 'Password'
     command 'chef-client'
     run_level :highest
     frequency :daily
     frequency_modifier 2
   end

**Create a scheduled to run on specific days**

.. code-block:: ruby

   windows_task 'chef-client' do
     user 'Administrator'
     password 'Password'
     command 'chef-client'
     run_level :highest
     frequency :daily
     day 'Mon, Thu'
   end

**Create a scheduled to run only once**

.. code-block:: ruby

   windows_task 'chef-client' do
     user 'Administrator'
     password 'Password'
     command 'chef-client'
     run_level :highest
     frequency :once
     start_time "16:10"
   end

**Create a scheduled to run on current day every 3 weeks**

.. code-block:: ruby

   windows_task 'chef-client' do
     user 'Administrator'
     password 'Password'
     command 'chef-client'
     run_level :highest
     frequency :weekly
     frequency_modifier 3
     random_delay '60'
   end

**Create a scheduled to run every Monday, Friday every 2 weeks**

.. code-block:: ruby

   windows_task 'chef-client' do
     user 'Administrator'
     password 'Password'
     command 'chef-client'
     run_level :highest
     frequency :weekly
     frequency_modifier 2
     day 'Mon, Fri'
   end

**Create a scheduled to to run when computer is idle with idle duration 20 min**

.. code-block:: ruby

   windows_task 'chef-client' do
     user 'Administrator'
     password 'Password'
     command 'chef-client'
     run_level :highest
     frequency :on_idle
     idle_time 20
   end

**Delete a task named old task**

.. code-block:: ruby

   windows_task 'old task' do
     action :delete
   end

**Enable a task named chef-client**

.. code-block:: ruby

   windows_task 'chef-client' do
     action :enable
   end

**Disable a task named ProgramDataUpdater with TaskPath \\Microsoft\\Windows\\Application Experience\\**

.. code-block:: ruby

   windows_task '\Microsoft\Windows\Application Experience\ProgramDataUpdater' do
     action :disable
   end

.. end_tag
