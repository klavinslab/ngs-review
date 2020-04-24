# Cannon Mallory
# malloc3@uw.edu
#
# This is to facilitate sample management within collection
module CollectionLocation

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
      location << convert_rc_to_alpha(loc) # 2,0 -> C1, 4,0 -> E1
    end
    location.join(",") # removes the ["A1"] the brackets and parantheses 
  end

  # converts an array of R,C to alpha numerical location
  #
  # @param loc [Array<r,c>] array of row and column
  # @return [String] alpha numerical location
  def convert_rc_to_alpha(loc)
    ALPHA26[loc[0]] + (loc[1]+1).to_s
  end

  # Converts alpha numerical location to Array<r,c>
  #
  # @param alpha [String] alpha numerical location
  # @return [Arrray<r,c>] array of row and column
  def convert_alpha_to_rc(alpha)
    row = ALPHA26.find_index(alpha[0 , 1])
    col = alpha[1...].to_i - 1
    [row,col]
  end

  # Finds the location of an item or sample
  #
  # @param collection [Collection] the collection containing the item or sample
  # @param part [Item, Part, Sample] item, part, or sample to be found
  # @return [Array] Array of item, part, or sample locations in form [[r1,c1],[r2,c1]]
  def get_item_sample_location(collection, part)
    collection.find(part)
  end


  # Finds a sample from an alpha numberical string location(e.g. A1, B1)
  #
  # @param collection [Collection] the collection that contains the part
  # @param loc [String] the location of the part within the collection (A1, B3, C7)
  # @return part [Item] the item at the given location
  def part_alpha_num(collection, loc)
    row,col = convert_alpha_to_rc(loc)
    dem = collection.dimensions
    raise 'Location outside collection dimensions' if row > dem[0] || col > dem[1]

    part = collection.part(row, col)
  end

  #gets the rcx list of samples in the collection.
  # R is Row
  # C is column
  # x is the alpha numerical location (in this case)
  #
  # Returns in the same order as sample array
  #
  # @param collection [Collection] the collection that items are going to
  # @param samples [The samples that locations are wanted from]
  #
  # @return [Array<Array<r, c, x>] 
  def get_rcx_list(collection, samples)
    rcx_list = []
    array_of_samples.each do |sample|
      sample_rc = get_item_sample_location(from_collection, sample)
      sample_alpha = get_alpha_num_location(from_collection, sample)

      sample_rc.each do |coordinates|
        coordinates.push(sample_alpha) # [0,0,A1]
        locations.push(coordinates)
      end
    end
    rcx_list
  end

end
