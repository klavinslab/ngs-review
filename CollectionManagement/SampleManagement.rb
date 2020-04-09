# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# This is to facilitate sample management within collection
module SampleManagement

  ALPHA26 = ('A'...'Z').to_a

  # Gets the location string of a sample in a collection
  # Returns Alpha numerical string eg A1 or if the sample is
  # in multiple locations will return A1, A2, A3
  #
  # @collection Collection the collection that the sample is in
  # @sample Sample the Sample that you want the Alpha Numerical location for
  def get_alpha_num_location(collection, sample)
    loc_array = get_item_sample_location(collection, sample)
    string = ''
    loc_array.each_with_index do |loc, idx|
      string += ', ' if idx.positive?
      loc.each_with_index do |rc, idx|
        if idx.even?
          string += ALPHA26[rc]
        else
          string += "#{rc+1}"
        end
      end
    end
    string
  end

  # Finds the location of the item or sample that is given
  #
  # @param collection [Collection] the collection containing the item or sample
  # @param part [Item, Part, Sample] item, part, or sample to be found
  # @return location_array [Array] Array of item, part, or sample locations
  def get_item_sample_location(collection, part)
    location_array = collection.find(part)
  end

  # Assigns samples to specific well locations
  #
  # @param input_array [Array<FieldValue>]
  # @param working_plate [Collection]
  # @raise TODO add error information
  def add_fv_array_samples_to_collection(input_array, working_plate)
    sample_array = []
    # collection, finds collection associated with child_item_id 
    input_array = input_array.sort_by { |fv| [fv.collection.find(fv.sample).first[1],
                                            fv.collection.find(fv.sample).first[0]] }
    input_array.each_with_index do |fv, idx|
      sample = fv.sample
      sample_array << sample
    end
    slots_left = working_plate.get_empty.length
    raise 'There are too many samples in this batch.' if sample_array.length > slots_left
    working_plate.add_samples(sample_array) # TODO: add error checking for if the working_plate is full
  end

  # This replaces the operations.make command.  It ensures that all items in output_fv_array
  # Remain in the same collection (instead of being put into different collections)
  #
  # @output_fv_array array[fv] array of field values
  # @working_plate collection the destination collection.
  def make_output_plate(output_fv_array, working_plate)
    output_fv_array.each do |fv|
        r_c = working_plate.find(fv.sample).first
        fv.set(collection: working_plate, row: r_c[0], column: r_c[1])
      end
  end

  # This finds a sample from an alpha numberical string location(e.g. A1, B1)
  #
  # @param collection [Collection] the collection that contains the part
  # @param loc [String] the location of the part within the collection (A1, B3, C7)
  # @return part [Item] the item at the given location
  def part_alpha_num(collection, loc)
    row = ALPHA26.find_index(loc[0,1])
    # col = loc[1...].to_i - 1

    dem = collection.dimensions 
    raise 'Location outside collection dimensions' if row > dem[0] || col > dem[1]
    part = collection.part(row, col)
  end
end
