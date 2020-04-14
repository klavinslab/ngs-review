# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Module for working with collections
# These actions should involve the WHOLE plate not individual wells.
# NOTE: The collection is doing the whole action
# Thats what I thought -- but the way this is written in the protocol,
# each operation seems to deal with one sample, not the whole plate
module CollectionActions
  # Store all input collections from all operations
  #
  # @param operations [OperationList] the  list of operations
  # @param location [String] the location that the items are to be moved to
  def store_input_collections(operations, location: nil)
    show do
      title 'Put Away the Following Items'
      table table_of_job_object_location(operations, input_output: 'input',
              location: location)
    end
  end

  # stores all output collections from all operations
  #
  # @param operations [OperationList] the operation list that all output collections should be stored
  # @param location [String] optional location string
  def store_output_collections(operations, location: nil)
    show do
      title 'Put Away the Following Items'
      table table_of_job_object_location(operations, input_output: 'output',
              location: location)
    end
  end


  #Stores all input objects in operation list
  #
  # @param operations [OperationList] operation list
  # @location [String] the location that things are to be put
  def table_of_job_object_location(operations, input_output: "input", location: nil)
    obj_array = []
    operations.each do |op|
      array_of_fv = op.inputs.reject { |fv| 
              fv.collection.nil? } if input_output == 'input'
      array_of_fv = op.outputs.reject { |fv| 
              fv.collection.nil? } if input_output == 'output'
      obj_array.concat(get_obj_from_fv_array(array_of_fv))
    end
    obj_array = obj_array.uniq
    set_locations(obj_array, location) unless location.nil?
    get_collection_locations(obj_array)
  end

  # Get the obj  from the fv (either item or collection)
  #
  # @param array_of_fv [Array] array of field values
  # @return obj_array [Array] array of objects (eiter collections or items)
  def get_obj_from_fv_array(array_of_fv)
    obj_array = []
    array_of_fv.each do |fv|
      if !fv.collection.nil?
        obj_array.push(fv.collection)
      elsif !fv.item.nil?
        obj_array.push(fv.item)
      else
        raise "Invalid class.  Neither collection nor item. Class = #{fv.class}"
      end
    end
    obj_array.uniq
  end

  # Sets the location of all objects in array to some given locations
  #
  # @param obj_array  Array[Collection] or Array[Items] an array of any objects that extend class item
  # @param location [String] the location to be moved to (just string or Wizard if Wizard Exist)
  def set_locations(obj_array, location)
    obj_array.each do |obj|
      obj.move(location)
    end
  end

  # Instructions to store a specific collection
  #
  # @param collection [Collection] the collection that is to be put away
  # @return location_table [Array<Array>] of collections and their locations
  def get_collection_locations(obj_array)
    location_table = [['ID', 'Collection Type', 'Location']]
    obj_array.each do |obj|
      location_table.push([obj.id, obj.object_type.name, obj.location])
    end
    location_table
  end

  # Instructions to store a specific item
  #
  # @param obj_item [Item/Object] that extends class item or Array
  #        extends class item all items that need to be stored
  # @param location [String] Sets the location of the items if included
  def store_items(obj_item, location: nil)
    show do
      title 'Put Away the Following Items'
      if obj_item.class != Array
        set_locations([obj_item], location) if location.nil?
        table get_collection_locations([obj_item])
      else
        set_locations(obj_item, location) if location.nil?
        table get_item_location(obj_item)
      end
    end
  end

  # Gives directions to throw away an object (collection or item)
  #
  # @param obj or array of Item or Object that extends class Item  eg collection
  # @param hazardous [boolean] if hazardous then true
  def trash_object(obj_array, hazardous: true)
    # toss QC plate
    if obj_array.class != Array
      obj_array = [obj_array]
    end

    show do
      title 'Trash the following items'
      tab = [['Item', 'Waste Container']]
      obj_array.each do |obj|
        obj.mark_as_deleted
        if hazardous
          waste_container = 'Biohazard Waste'
        else
          waste_container = 'Trash Can'
        end
        tab.push([obj.id, waste_container])
      end
      table tab
    end
  end

  # makes a new plate and provides instructions to label said plate
  #
  # @param c_type [string] the collection type
  # @param label_plate [boolean] whether to get and label plate or no default true
  # @return working_plate [Collection]
  def make_new_plate(c_type, label_plate: true)
    working_plate = Collection.new_collection(c_type)
    get_and_label_new_plate(working_plate) if label_plate
    working_plate
  end

  # Instructions on getting and labeling new plate
  #
  # @param plate [Collection] plate to be retrieved and labeled
  def get_and_label_new_plate(plate)
    show do
      title 'Get and Label Working Plate'
      note "Get a <b>#{plate.object_type.name}</b> and label it ID: <b>#{plate.id}</b>"
    end
  end
end
