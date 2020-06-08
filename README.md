# Protocols for NGS

<b>Requires</b>: [StandardLibs](https://github.com/klavinslab/standard-libraries), [CollectionManagement](https://github.com/klavinslab/aq-collection-management)
<b>Note</b> Standard Libs may need update to ItemAction for this library to work properly

# General 
* [Style Guide I've been working on](https://gist.github.com/cashmonger/7b6bd95b04cefca14497211c4ac9ffb8)

## Spacing 
* Spaces (2) instead of tabs for indentation
* One space between # and comment text
* One empty line between method definitions

## Yard Doc Style: 
We use [YARD](https://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md) to generate documentation.
That link has a lot of information on style, but the main thing is to get the tag format right. 
There are tags for @return, @raise errors etc. 
They all work the same way -- @Tag variable_name [variable_type] Any other notes
```ruby
# Perform the Streak Plate Protocol for a single operation
#
# @param operation [Operation] the operation to be executed
def operation_task(operation)
    Method Body
end
```

## Variables 
* Avoid single letter variables unless they are defined very close to where they are being used 
* If you're using aquarium specific terms (e.g. FieldValue), write the words out.
* Someone who doesn't know our database/terms should still be able to understand what the variables mean.
* Try not to use structure names, unless the thing is that structure. That is, if it has array in the name, it should be an Array (in the Ruby sense of an array)
* But also, try not to use words like Array, List, etc. in variable names. e.g. `sample_plate` instead of `sample_table`, or `samples instead` of `sample_array` 


## More Ruby Style Stuff 
* Each include statement gets its own line 
* x += y is preferred over x = x + y
* Single quotes `'thing'` preferred over double, unless you need interpolation `"#{thing}"`  
* `nil?` preferred to `== nil`   

## House Style Stuff 
* Move intro information into documentation section of protocol, along with note on what protocols (if any) would follow or precede it.
* Use () when declaring parameters in method signature, and when calling methods. 
* Keyword Arguments `variable: default_value` preferred over defaults `variable = default`

