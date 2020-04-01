# Protocols for NGS

# General 

## Spacing 
* One space between # and comment text 
* One empty line between method definitions

## Yard Doc Style: 
We use [YARD](https://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md) to generate documentation.
It has to follow a specific format. You can use tags for @return, @raise errors etc. 
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
* If you're using aquarium specific terms (e.g. FieldValue), write the words out. The question is -- if someone who didn't know our database/terms was reading this, would it would be clear what the variables stand for.

## More Ruby Style Stuff 
* Each include statement gets its own line 
* x += y is preferred over x = x + y
*  

## Etc. 
* Move intro information into documentation section of protocol, along with note on what protocols (if any) would follow or precede it.
