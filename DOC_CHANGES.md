<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# Chef CLient Doc Changes:

### --validator option for `knife client create`
Boolean value. If set to true, knife creates a validator client o.w. it creates a user client. Default is false.

###  --force for `knife client delete`
Option that is required to be specified if user is attempting to delete a validator client. No effect while deleting a user client. 

### -r / --runlist option for chef-client
Option similar to `-o` which sets or changes the run_list of a node permanently.