# Root Aliases in Cookbooks

There are several common cases when writing Chef cookbooks that result in a
folder containing a single file, usually called `default.rb`. Root aliases
allow for using a single file instead of a folder.

## Motivation

    As a cookbook author,
    I want to less complex directory layouts,
    so that learning and maintenance is easier.

## Specification

There are two common cases where a single-file-in-folder comes up:

1. `attributes/default.rb`
2. `recipes/default.rb`

With `attributes`, this single-file-in-folder case is common to the point of almost 
complete irrelevance of other layouts, given that all attribute files are always 
loaded. `recipes` are not exclusively a single-file-in-folder case, but it is common 
enough to warrant a special case.

With this in mind, aliases are available for each:

1. `attributes.rb`
2. `recipe.rb`

It is an error for a cookbook to contain both an alias and its target, or two
aliases for the same target.

No aliases are provided for other types as they are generally a more advanced
use case where the worry about learning curve is reduced.

Aliases are equivalent to their target file for purposes of loading either via
standard cookbook loading, or methods like `include_recipe`.

## Rationale

This meshes well with RFC017 towards a goal of reducing the file layout
complexity of simple cookbooks. There can be compatibility issues with tools
that parse the cookbook manifest data and presume that all files from a given
segment reside under the previously required folder. The author knows
of no such tools, and given that the manifest format is mostly an internal
representation, this is not considered a blocker. Overall, the goal of these RFCs
is to remove the frequent use of single-child folders.

The choice of which aliases to provide and what to name them is mostly driven
by the common cases, but is not exhaustive. `attributes.rb` and `recipe.rb` are
chosen to match their usage grammatically. An additional alias of `recipes.rb`
could be provided to match the folder name, but this is left for a future
improvement based on usage feedback.