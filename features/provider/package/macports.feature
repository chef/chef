@provider @package @macports
Feature: Macports integration
  In order to easily manage my OS X machines
  As a Developer
  I want to manage packages installed on OS X machines

  Scenario Outline: OS X package management
    Given that I have the MacPorts package system installed
    When I run chef-solo with the '<recipe>' recipe
    Then the run should exit '<exitcode>'
    And there <should> be a binary on the path called '<binary>'

  Examples:
    | recipe                                 | binary   | should     | exitcode |
    | packages::macports_install_yydecode    | yydecode | should     | 0        |
    | packages::macports_remove_yydecode     | yydecode | should not | 0        |
    | packages::macports_upgrade_yydecode    | yydecode | should     | 0        |
    | packages::macports_purge_yydecode      | yydecode | should not | 0        |
    | packages::macports_install_bad_package | fdsafdsa | should not | 1        |
