<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# Chef Client Doc Changes:

### --validator option for `knife client create`
Boolean value. If set to true, knife creates a validator client o.w. it creates a user client. Default is false.

###  --delete-validators for `knife client delete`
Option that is required to be specified if user is attempting to delete a validator client. No effect while deleting a user client.

###  --delete-validators for `knife client bulk delete`
Option that is required to be specified if user is attempting to delete a validator client. If not specified users cannot delete a client if it's validator client. If specified knife asks users for confirmation of deleting clients and validator clients seperately. Some examples for scripting:

To delete all non-validator clients:
`knife client bulk delete regexp --yes`

To delete all clients including validators:
`knife client bulk delete regexp --delete-validators --yes`

### -r / --runlist option for chef-client
Option similar to `-o` which sets or changes the run_list of a node permanently.

### OHAI 7 Upgrade
Unless there are major issues, 11.12.0 will include OHAI 7. We already have ohai 7 docs in place. We probably need to add some notes to ohai 6 notes that one should now use the newer version when possible.
