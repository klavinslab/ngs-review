# Cannon Mallory
# malloc3@uw.edu
#
# This module is to contain common actions done with collections
# This includes moving them, finding locations, putting away individual collections.
# or putting a whole collection on a machine etc
# These actions should involve the WHOLE plate not individual wells.  The collection is doing the whole action
module CollectionActions
    
    # stores all input collections from all operations
    #
    # @param operations [OperationsList] the operation list that all input collections should be stored
    # @param location [String] the location that the items are to be moved to
    def store_input_collections(operations, location = nil)
        show do 
           title "Put Away the Following Items"
           operations.each do |op|
              array_of_input_fv = op.inputs.reject{|fv| fv.collection == nil}
              table table_of_object_locations(array_of_input_fv, location)
          end
        end
    end
    
    # stores all output collections from all operations
    #
    # @param operations OperationsList the operation list that all output collections should be stored
    def store_output_collections(operations, location = nil)
        show do 
           title "Put Away the Following Items"
           array_of_input_fv = []
           operations.each do |op|
            array_of_input_fv = array_of_input_fv + op.outputs.reject{|fv| fv.collection == nil}
           end
           table table_of_object_locations(array_of_input_fv, location)
        end
    end
    
    #Shows the locations of all the collections in the array of FV.
    #Can move the location to optional "location"
    #
    # array_of_fv Array[FieldValues] an array of FieldValues
    # @location string Optional moves all collections to that location
    # Returns
    # @Table    Table   Returns a Table
    def table_of_object_locations(array_of_fv, location = nil)
        obj_array = []
        array_of_fv.each do |fv|
            if fv.collection != nil
                obj_array.push fv.collection
            elsif fv.item != nil
                obj_array.push fv.item
            else
                raise "Invalid class.  Neither collection nor item."
            end
        end
        obj_array = obj_array.uniq
        set_locations(obj_array, location) if location != nil
        return get_item_locations(obj_array)
    end


    #Sets the location of all objects in array to some given locations
    #
    # @obj_array  Array[Collection] or Array[Items] an array of any objects that extend class item
    # @location     String the location to be moved to (just string or Wizard if Wizard Exist)
    def set_locations(obj_array, location)
        obj_array.each do |obj|
            obj.move(location)
        end
    end
    
    #instructions to store a specific collection
    #
    # @collection Collection the collection that is to be put away
    # Returns:
    # @ Table of collections and their locations
    def get_item_locations(obj_array)
        tab = [['ID', 'Collection Type', 'Location']]
        obj_array.each do |obj|
            tab.push([obj.id, obj.object_type.name, obj.location])
        end
        return tab
    end
    
    #Instructions to store a specific item
    #
    # @obj_item Item/Object that extends class item or Array[Item/item that 
    #       extends class item]         all items that need to be stored
    # @location Optional String Sets the location of the items if included
    def store_items(obj_item, location = nil)
        show do
            title "Put Away the Following Items"
            if obj_item.class != Array
                set_locations([obj_item], location) if location != nil
                table get_item_locations([obj_item])
            else
                set_locations(obj_item, location) if location != nil
                table get_item_location(obj_item)
            end
        end
    end

    #Gives directions to throwaway an object (collection or item)
    #
    # @obj or array of Item or Object that extends class Item  eg collection
    # @hazardous boolean if hazardous then true
    def trash_object(obj_array, hazardous = true)
        #toss QC plate
        if obj_array.class != Array
            obj_array = [obj_array]
        end
        
        show do
            title "Trash the following items"
            tab = [['Item', 'Waste Container']]
            obj_array.each do |obj|
                obj.mark_as_deleted
                if hazardous
                    waste_container = "Biohazard Waste"
                else
                    waste_container = "Trash Can"
                end
                tab.push([obj.id, waste_container])
            end
            table tab
        end
    end

    #makes a new plate and provides instructions to label said plate
    #
    # @ c_type string the collection type
    # @ label_plate boolean weather to get and label plate or no default true
    # Returns
    # @collection collection the collection it makes
    def make_new_plate(c_type, label_plate = true)
        working_plate = Collection.new_collection(c_type)
        get_and_label_new_plate(working_plate) if label_plate
        return working_plate
    end



    #Instructions on getting and labeling new plate
    #
    #@plate Collection plate to be gotten and labeled
    def get_and_label_new_plate(plate)
        show do
        title "Get and Label Working Plate"
        note "Get a <b>#{plate.object_type.name}</b> and lable ID: <b>#{plate.id}</b>"
        end
    end
    
    
end
