<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->


### knife ssh has --exit-on-error option
`knife ssh` now has an --exit-on-error option that will cause it to
fail immediately in the face of an SSH connection error.  The default
behavior is move on to the next node.
