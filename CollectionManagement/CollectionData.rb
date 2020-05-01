# for managing data associations of collections
# and ensuring that samples/item data is handled correctly

needs "Standard Libs/AssociationManagement"

module CollectionData

  include AssociationManagement
  
  # Associates data to parts in the collection based on the data map
  # Data map is an array of [[Row, Column, Value], ...]
  # All values are associated under the same key 
  #
  # @param plate [Collection] the plate that the parts exit in
  # @param data_map [Array<Array<r,c, value>, ...>] data map of all parts should be associated with value
  # @param key [String] the key that the association should be tagged to
  def associate_value_to_parts(plate:, data_map:, key:)
    data_map.each do |loc_val_array|
        loc_val_array[3] = key
    end
    associate_value_key_to_parts(plate: plate, data_map: data_map)
  end

  # Associates data to parts in the collection based on the data map
  # Data map is an array of [[Row, Column, Value, key], ...]
  # All values are associated under their respective key
  #
  # @param plate [Collection] the plate that the parts exit in
  # @param data_map [Array<Array<r,c, value, key>, ...>] data map of all parts should be associated with value
  def associate_value_key_to_parts(plate:, data_map:)
    data_map.each do |key_value_map|
        part = plate.part(key_value_map[0], key_value_map[1])
        data_value = key_value_map[2]
        key = key_value_map[3]
        associate_data(part, key.to_sym, data_value)
    end
  end

  # Associates data to every part in a plate
  #
  # @param plate [Collection] the collection
  # @param data [Anything] the data to be associated
  def assiate_to_all(plate:, data:, key:)
    data_map = []
    parts.each do |part|
        loc = plate.find(part)
        loc[2] = data
        loc[3] = key
        data_map.push(loc)
    end
    associate_value_key_to_parts(plate: plate, data_map: data_map)
  end




  # Adds provenence history to to_object from from_object
  #
  # @param from_obj [Krill Object] object that provenance is coming from
  # @param to_obj [Krill Object] the object that provenance is going to
  def from_obj_to_obj_provenance(to_obj, from_obj)
    from_obj_map = AssociationMap.new(from_obj)
    to_obj_map = AssociationMap.new(to_obj)
    add_provenance(from: from_obj, from_map: from_obj_map,
                    to: to_obj, to_map: to_obj_map)
    from_obj_map.save
    to_obj_map.save
  end

  #returns an array of all samples that are the same in both collections
  #
  # @param collection_a [Collection] a collection
  # @param collection_b [Collection] a collection
  # @return [Array<Sample>]
  def find_like_samples(collection_a, collection_b)
    samples_a = collection_a.parts.map!{|part| part.sample}
    samples_b = collection_b.parts.map!{|part| part.sample}
    samples_a & samples_b
  end

  # Adds x value to [R,C,X] list.  If x does not exist (eg [R,C])
  # then will append, if X does exist will replace or concatonate strings
  # based on inputs
  #
  # @param rc [Array<Row(int), Column(int), Optional(String)] the RC/RCX 
  #       list to be modified
  # @param x [String] string to be added to x values
  # @param append: [Boolea] default true.  Replace if false
  def append_x_to_rcx(rc, x, append: true)
    x = x.to_s
    if rc[2].nil? || !append
      rc[2] = x
    else
      rc[2] += ", " + x 
    end
    rc
  end

  # gives an array of parts in the collection that match the right sample
  #
  # @param collection [Collection] the collecton that the part exists in
  # @param sample [Sample] the sample searched for
  def parts_from_sample(collection, sample)
    part_loc = collection.find(sample)
    parts = []
    part_loc.each do |r_c|
      parts.push(collection.part(r_c[0], r_c[1]))
    end
    parts
  end
    
end