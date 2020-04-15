# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# This is to facilitate sample management within collection
module SampleManagement

  ALPHA26 = ('A'...'Z').to_a

  # Gets the location string of a sample in a collection
  #
  # @param collection [Collection] the collection containing the sample
  # @param sample [Sample] the Sample that you want to locate
  # @return [String] the Alpha Numerica location(s) e.g. A1, A2
  def get_alpha_num_location(collection, sample)
    loc_array = get_item_sample_location(collection, sample) 
    # [[r0, c0],[r1, c0], [r2,c0]]
    location = []
    loc_array.each do |loc| # takes coords [2, 0] index=0
      location << ALPHA26[loc[0]] + (loc[1] + 1).to_s # 2,0 -> C1, 4,0 -> E1
    end
    location.join(",") # removes the ["A1"] the brackets and parantheses 
  end

  # Finds the location of an item or sample
  #
  # @param collection [Collection] the collection containing the item or sample
  # @param part [Item, Part, Sample] item, part, or sample to be found
  # @return [Array] Array of item, part, or sample locations in form [[r1,c1],[r2,c1]]
  def get_item_sample_location(collection, part)
    collection.find(part)
  end

  # Assigns samples to specific well locations
  #
  # @param samples [Array<FieldValue>]
  # @param working_plate [Collection]
  # @raise TODO add error information
  def add_samples_to_collection(samples, working_plate)
    # renamed from add_fv_array_samples_to_collection
    samples_to_add = []
    # collection, finds collection associated with child_item_id
    samples = samples.sort_by { |fv| [fv.collection.find(fv.sample).first[1], fv.collection.find(fv.sample).first[0]] }

    samples.each { |fv| samples_to_add << fv.sample }
    slots_left = working_plate.get_empty.length
    raise 'There are too many samples in this batch.' if samples_to_add.length > slots_left

    add_samples_row_wise(samples_to_add, working_plate)
    # TODO: add error checking for if the working_plate is full
  end

  # Adds samples to the first slot in the first available colum 
  # as apposed to column wise that the base version does.
  #
  # @param samples_to_add [Array<Samples>] an array of samples
  # @param collection [Collection] the collection to include samples
  def add_samples_row_wise(samples_to_add, collection)
    col_matrix = collection.matrix
    collumns = col_matrix.first.size
    rows = col_matrix.size
    samples_to_add.each do |sample|
      break_patern = false
      collumns.times do |col|
        rows.times do |row|
            if collection.part(row, col).nil?
                collection.set(row,col, sample)
                break_patern = true
                break
            end
        end
        break if break_patern
      end
    end
  end

  # Replaces operations.make
  # Ensures that all items in output_fv_array
  # remain together in one collection
  #
  # @param output_fv_array [Array<Field Values>] array of field values
  # @param working_plate [Collection] the destination collection
  def make_output_plate(output_fv_array, working_plate)
    output_fv_array.each do |fv|
      r_c = working_plate.find(fv.sample).first
      fv.set(collection: working_plate, row: r_c[0], column: r_c[1])
    end
  end

  # Finds a sample from an alpha numberical string location(e.g. A1, B1)
  #
  # @param collection [Collection] the collection that contains the part
  # @param loc [String] the location of the part within the collection (A1, B3, C7)
  # @return part [Item] the item at the given location
  def part_alpha_num(collection, loc)
    row = ALPHA26.find_index(loc[0 , 1])
    col = loc[1...].to_i - 1
    dem = collection.dimensions
    raise 'Location outside collection dimensions' if row > dem[0] || col > dem[1]

    part = collection.part(row, col)
  end
end
