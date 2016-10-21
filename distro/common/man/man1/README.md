# Man pages for Knife

The source of the Chef Documentation is located at
http://docs.opscode.com/.

This README documents how the man pages for all of the Knife subcommands
that are built into the chef-client are managed.

## Source Files

The source files are located in the chef-docs repository:
https://github.com/chef/chef-docs

Each Knife subcommand has its own source folder. The folder naming
pattern begins with man_.

Each man page is a single file called index.html.

In the conf.py file, the following settings are unique to each man page:

`today` setting is used to define the Chef version. This is because we
don't want an arbitrary date populated in the file, yet we still need a
version number. For example: `today = 'Chef 11.8`. 

`project` setting is set to be the same as the name of the subcommand.
For example: `project = u'knife-foo'`.

`Options for man page output` settings are set to be similar across all
man pages, but each one needs to be tailored specifically for the name
of the man page.

All of the other settings in the General Configuration section should be
left alone. These exist to ensure that all of the doc builds are sharing
the right common elements and have the same overall presentation.

## Building Docs

The docs are built using Sphinx and must be set to the `-b man` output.
Currently, the man pages are built locally and then added to the Chef
builds in chef-master.

## Editing

These files should never be edited. All of the content is pulled in from
elsewhere in the chef-docs repo at build time. If changes need to be
made, those changes are done elsewhere and then the man pages must be
rebuilt. This is to help ensure that all of the changes are made across
all of the locations in which these documents need to live. For example,
by design, every Knife subcommand with a man page also has an HTML doc
at docs.opscode.com/knife_foo.html.

## License

[Creative Commons Attribution 3.0 Unported License](http://creativecommons.org/licenses/by/3.0/)

## Questions?

Open an [Issue](https://github.com/chef/chef-docs/issues) and ask.
