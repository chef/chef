=====================================================
Documentation Style Guide
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/style_guide.rst>`__

Chef reference documentation is written using restructuredText (reST) and built with Sphinx version 1.2.3.

We recommend that you use the conventions described in this guide when contributing to Chef reference documentation.

The HTML version of the doc set can be found at |url docs|.

Building
=====================================================

Run the command

   .. code-block:: bash

      make master

to build the doc set. Open ``build/index.html`` in a browser to see the results.

Basic Doc Template
=====================================================
All documents have a title and a body.

Topic Titles
-----------------------------------------------------
Each topic has a single topic title. Use the equals symbol (=) above and below the header name::

   =====================================================
   header name goes here
   =====================================================

Section Headers
=====================================================

The following sections describe the section header pattern that Chef is using for topic titles, H1s, H2s, H3s and H4s.

As a general rule, limit the number of heading levels to no more than two within a topic. There can be exceptions, especially if the document is very large, but remember that HTML TOC structures usually have width limitations (on the display side) and the more structure within a TOC, the harder it can be for users to figure out what's in it.

Unless the topics are about installing things or about API endpoints, the headers should never wrap. Keep them to a single line.

The width of header adornment must be at least equal to the length of the text in the header and the same width for headers is used everywhere. Consistent width is preferred.

H1
-----------------------------------------------------
If a topic requires sections, use the equals symbol (=) below the H1 header name::

   H1 Heading
   =====================================================
   This is the body.

H2
-----------------------------------------------------
Use the dash symbol (-) below the header name to indicate H2 headers::

   H2 Heading
   -----------------------------------------------------
   This is the body.

H3
-----------------------------------------------------
Use the plus symbol (+) below the header name to indicate H3 headers::

   H3 Heading
   +++++++++++++++++++++++++++++++++++++++++++++++++++++
   This is the body.

H4
-----------------------------------------------------
Use the caret symbol (^) below the header name to indicate H4 headers::

   H4 Heading
   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   This is the paragraph.

Other headers
-----------------------------------------------------
If you need more than four heading levels, use bold emphasis and then white space to provide the visual treatment and content separation::

   **header name goes here**         # bold emphasis
                                     # blank line
   content, as normally authored.

Lists and Tables
=====================================================
The following sections describe conventions for lists and tables in Chef docs.

Bulleted Lists
-----------------------------------------------------
Bulleted lists break up text blocks and draw attention to a group of items::

   * text goes here
   * text goes here
   * text goes here
   * text goes here

Use the asterisk symbol (*) only for bulleted lists, even though Sphinx supports using other symbols.

Numbered Lists
-----------------------------------------------------
Numbered lists are created like this::

   #. text goes here
   #. text goes here
   #. text goes here
   #. text goes here

Use the number symbol (#) to let Sphinx handle the actual ordering. If the number list needs to change later, you don't have to worry about making sure the numbers are in the correct order.

Definition Lists
-----------------------------------------------------
Definition lists are used to show the options available to a command line tool. These appear the same way in the HTML and print documentation as they appear in the man page output::

   ``--name-only``
      Show only the names of modified files.

   ``--name-status``
      Show only the names of files with a status of ``Added``, ``Deleted``, ``Modified``, or ``Type Changed``.

List Tables
-----------------------------------------------------
Chef docs use the list table for tables::

   .. list-table::
      :widths: 250 250
      :header-rows: 1

      * - Header
        - Description
      * - text or image
        - text or image
      * - text or image
        - text or image

The table cells support images and text. The widths can be changed and the number of columns can be changed too. In general, we keep the number of columns to three or fewer. When creating a list table, think about what it will look like in HTML, PDF, man-page, and other formats and keep in mind the width limitations inherent in print formats.

Sphinx tables (as opposed to list tables) are not used in Chef docs.

What the list table might look like in the source file::

   .. list-table::
      :widths: 60 420
      :header-rows: 1

      * - Header
        - Description
      * - .. image:: ../../images/image_style_guide_example.png
        - Lorem ipsum dolor. This is just an example.
      * - No image, just text!
        - Lorem ipsum dolor. This is just an example.
      * - Chef
        - Chef is a systems and cloud infrastructure automation framework that makes it easy to deploy servers and applications to any physical, virtual, or cloud location, no matter the size of the infrastructure.

Inline Markup
=====================================================
Adding emphasis within text strings can be done using **bold** and ``code strings``.

Bold
-----------------------------------------------------
Use two asterisks (*) to mark a text string as **bold**::

   **text goes here**

Code Strings
-----------------------------------------------------
Sometimes the name of a method or database field needs to be used inline in a paragraph. Use two backquotes to mark certain strings as code within a regular string of text::

   ``code goes here``

Links
=====================================================
Chef docs can contain and internal and external links.

Internal
-----------------------------------------------------
An internal link is one that resolves to another topic that is built by Sphinx::

   :doc:`essentials_nodes`

where ``:doc:`` tells Sphinx that what follows is a file name that Sphinx will encounter during the build process.

Internal w/short names
-----------------------------------------------------
Sometimes it's better to have the name of the link that displays be as short as possible (and different from the actual title of the topic)::

   :doc:`Actions </resource_common_actions>`

where ``:doc:`` tells Sphinx that what follows is a file name that Sphinx will encounter during the build process. ``Actions`` represents the short name that will display on the page in which this internal link is located, and then ``resource_common_actions`` is the filename and is contained within brackets (< >).

External
-----------------------------------------------------
An external link points to something that does not live on |url docs|. An external link requires an HTTP address. In general, it's better to spell out the HTTP address fully, in case the topic is printed out::

   http://www.codecademy.com/tracks/ruby

Code Blocks
=====================================================
Code blocks are used to show code samples, such as those for Ruby, JSON, and command-line strings.

Ruby
-----------------------------------------------------
Use this approach to show code blocks that use Ruby::

   .. code-block:: ruby

      default["apache"]["dir"]          = "/etc/apache2"
      default["apache"]["listen_ports"] = [ "80","443" ]

Bash
-----------------------------------------------------
Use this approach to show code blocks that use any type of shell command, such as for Knife or the chef-client or for any other command-line example that may be required::

   .. code-block:: bash

      $ knife data bag create admins

Javascript (and JSON)
-----------------------------------------------------
Use this approach to show code blocks that use any type of JavaScript, including any JSON code sample::

   .. code-block:: javascript

      {
         "id": "charlie",
         "uid": 1005,
         "gid":"ops",
         "shell":"/bin/zsh",
         "comment":"Crazy Charlie"
      }

Literal
-----------------------------------------------------
Literals should be used sparingly, but sometimes there is a need for a block of text that doesn't fit neatly into one of the options available for ``code-block``, such as showing a directory structure, basic syntax, or pseudocode. Use a double colon (::) at the end of the preceding paragraph, add a hard return, and then indent the literal text::

   Use a double colon (::) at the end of the preceding paragraph. What it looks like as reST::

      a block of literal text indented three spaces
      with more
      text as required to
      complete the block of text.
      end.

Tagged Regions
-----------------------------------------------------
Chef docs uses tags to indicate text that is used in more than one topic::

   .. tag chef

   Chef is a powerful automation platform that transforms infrastructure into code. Whether you’re operating in the cloud, on-premises, or in a hybrid environment, Chef automates how infrastructure is configured, deployed, and managed across your network, no matter its size.

   This diagram shows how you develop, test, and deploy your Chef code.

   .. image:: ../../images/start_chef.svg
      :width: 700px
      :align: center

   .. end_tag

The docs will only build if all tagged regions with the same tag name have the same content. The ``dtags`` utility is included to help synchronize tagged regions. Refer to the `README.md <https://github.com/chef/chef-web-docs/blob/master/README.md>`__ file in the `chef/chef-web-docs <https://github.com/chef/chef-web-docs>`__ repo for more information.

Here are some guidelines for using tags:

* The amount of white space to the left of the ``tag`` and ``end_tag`` lines must be the same.
* The ``tag`` line should be followed by a blank line.
* The ``end_tag`` line should be preceded by a blank line.
* The content within the tag must be indented at least as much as the ``tag`` line.
* The name that follows ``tag`` must use only lowercase letters, digits and the underscore character.

Notes and Warnings
=====================================================
In general, notes and warnings are not the best way to present important information. Before using them ask yourself how important the information is. If you want the information to be returned in a search result, then it is better for the information to have its own topic or section header. Notes and warnings do provide a visual (because they have a different color than the surrounding text) and can be easily spotted within a doc. If notes and warnings must be used, the approach for using them is as follows.

Notes
-----------------------------------------------------
What a note looks like as reST::

   .. note:: This is a note.

What a note looks like after it's built:

.. note:: This is a note.

Warnings
-----------------------------------------------------
Use sparingly, so that when the user sees a warning it registers appropriately::

   .. warning:: This is a warning.

What a warning looks like after it's built:

.. warning:: This is a warning.

Images
=====================================================
Images::

   .. image:: ../../images/icon_chef_client.svg
      :width: 100px
      :align: center

Images should be 96 dpi and no larger than 600 pixels wide. Ideally, no larger than 550 pixels wide. This helps ensure that the image can be printed and/or built into other output formats more easily; in some cases, separate 300 dpi files should be maintained for images that require inclusion in formats designed for printing and/or presentations.

Grammar
=====================================================
Chef does not follow a specific grammar convention. Be clear and consistent as often as possible. Follow the established patterns in the docs.

Tautologies
-----------------------------------------------------
A tautology, when used as a description for a component, setting, method, etc. should be avoided. If a string is a tautology, some effort should be made to make it not so. An example of a tautology is something like "Create a new user" (by its very nature, a user created **is** a new user) or (for a setting named ``cidr_block``) "The CIDR block for the VPC."

Doc Repo
=====================================================
The Chef reference documentation is found at

https://github.com/chef/chef-web-docs

* The chef-web-docs repo contains a ``chef_master/source`` directory which holds most the reST files in the doc set.
* The ``images`` directory stores the image files used in the docs.
* The ``conf.py`` tells Sphinx what to do when it's asked to build Chef docs. Don't modify this file.

The ``build`` directory contains the output of the ``make`` command.

In the past, the chef-web-docs repo contained documentation for prior verions of Chef components. Currently, the repo is limited to the current major versions of Chef components.

When submitting a GitHub pull request or issue to chef-web-docs, remember:

* Look in the ``chef_master/source`` directory to find the topic/files
* Focus on the actual content. If your change causes inconsistencies in the tagged regions (see above), this will be noted in your pull request by the CI system. You don't need to fix this error unless you want to. The Chef docs team will do this prior to accepting the pull request.

You can send email to docs@chef.io if you have questions.

Official Names
=====================================================
For Chef applications and components, use:

* ``Chef`` for Chef, the company, and for the Chef client, server and development kit .
* ``Chef server`` for the Chef server
* ``chef-client`` for the Chef client
* ``Chef Automate`` for the Chef Automate product

TOC Trees
=====================================================
A TOC tree defines all of the topics that are children of this topic. In Sphinx outputs, the Previous and Next patterns use this topic structure to determine these links. In addition, a visible TOC will use the structure defined by the ``toctree`` directive. In general, Chef is not using the visible TOC tree, but they still need to be present in the topics to keep Sphinx happy. What the hidden ``toctree`` looks like as reST::

   .. toctree::
      :hidden:

      chef_overview
      just_enough_ruby_for_chef
      ...

The TOC tree for Chef docs is located at the bottom of the file ``chef_master/source/index.rst``.

Localization
=====================================================
Sphinx supports localization into many languages.

.pot files
-----------------------------------------------------
.pot files are used by localization teams as an intermediate step in-between the native English content and the localized content. Opscode needs to build the .pot files so that localization teams can feed them into their tools as part of their localization process.

.. warning:: .pot files should be recompiled, not modified.

.. warning:: .pot files are built only for the current release of documentation, which is the same as the ``chef_master`` source collection in git.

The .pot file is built using much the same process as a regular Sphinx content build. For example, a regular content build:

.. code-block:: bash

   sphinx-build -b html /path/to/source /path/to/build

and then for the .pot files:

.. code-block:: bash

   sphinx-build -b gettext /path/to/source /path/to/translate

with the very important difference of the ``/build`` vs. ``/translate`` folders for the output.

.pot files should be checked into the github repository like every other source file and even though they are output of the source files, should be treated as if they are source files.

.. note:: The /translate folder in the github source contains a regularly updated set of .pot files. That said, it is recommended that if you want to localize the Chef documentation, check with Chef (send email to docs@chef.io) and let us know that you want to participate in the localization process and we can sync up. Or just update the .pot files locally to make sure they are the most current versions of the .pot files.

conf.py Settings
=====================================================
Every Sphinx build has a configuration file.

rst_prolog
-----------------------------------------------------
Chef has added this configuration setting to every conf.py file to help streamline the inclusion of files at the beginning of the build process and to help support localization efforts. This setting is added to the general configuration settings and looks like this:

.. code-block:: python

   # A string of reStructuredText that will be included at the beginning of every source file that is read.
   rst_prolog = """
   .. include:: ../../swaps/swap_descriptions.txt
   .. include:: ../../swaps/swap_names.txt
   """

