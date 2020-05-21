# Assists with basic actions of items (eg trashing, moving, etc)

module ItemActions
    
  # Store all items used in input operations
  # Assumes all inputs are non nil
  #
  # @param operations [OperationList] the list of operations
  # @param location [String] the storage location
  # @param type [String] the type of items (item, collection, nil)
  def store_inputs(operations, location: nil, type: nil)
    store_io(operations, role: 'inputs', location: location, type: type)
  end
  
  # Stores all items used in output operations
  # Assumes all outputs are non nil
  #
  # @param operations [OperationList] the operation list where all
  #     output collections should be stored
  # @param location [String] the storage location
  # @param type [String] the type of items (item, collection, nil)
  def store_outputs(operations, location: nil, type: nil)
    store_io(operations, role: 'outputs', location: location, type: type)
  end
  
  # Stores all items of a certain role in the operations list
  # Creates instructions to store items as well
  #
  # @param operations [OperationList] list of Operations
  # @param role [String] whether material to be stored is an input or an output
  # @param location [String] the location to store the material
  # @param all_items [Boolean] an option to store all items not just collections
  # @param type [String] the type of items (item, collection, nil)
  def store_io(operations, role: 'input', location: nil, type: nil)
    items = []
    operations.each do |op|
      if role.downcase == 'inputs'
        field_values = op.inputs
      elsif role.downcase == 'outputs'
        field_values = op.outputs
      else
        raise 'Invalid role'
      end
  
      if type.downcase == 'collection'
        field_values.reject { |fv| fv.collection.nil? }
      elsif type.downcase == 'item'
        field_values.reject { |fv| !fv.collection.nil? }
      end
  
      items.concat(field_values.map(|fv| fv.item))
    end
    store_items(items, location: location)
  end
  
  # Instructions to store a specific item
  # TODO have them move the items first then move location in AQ
  #
  # @param items [Array<items>] the things to be stored
  # @param location [String] Sets the location of the items if included
  def store_items(items, location: nil)
    set_locations(items, location)
    tab =  create_location_table(items)
    show do
      title 'Put Away the Following Items'
      table tab
    end
  end
  
  # Sets the location of all objects in array to some given locations
  #
  # @param items Array[Collection] or Array[Items] an array of any objects
  # that extend class Item
  # @param location [String] the location to move object to
  # (String or Wizard if Wizard exists)
  def set_locations(items, location)
    items.each do |item|
      item.move_to(location)
      item.save
    end
  end
  
  # Creates table directing technician on where to store materials
  #
  # @param collection [Collection] the materials that are to be put away
  # @return location_table [Array<Array>] of Collections and their locations
  def create_location_table(items)
    location_table = [['ID', 'Object Type', 'Location']]
    items.each do |item|
      location_table.push([item.id, item.object_type.name, item.location])
    end
    location_table
  end
  
  # Gives directions to throw away objects (collection or item)
  #
  # @param items [Array<items>] Items to be trashed
  # @param hazardous [boolean] if hazardous then true
  def trash_object(items, waste_container: 'Biohazard Waste')
    set_locations(items, location: waste_container)
    tab = create_location_table(items)
    show do
      title 'Properly Dispose of the following items:'
      table tab
    end
    items.each {|item| item.mark_as_deleted}
  end 
end