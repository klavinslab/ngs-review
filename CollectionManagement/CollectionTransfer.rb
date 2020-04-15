# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Methods for transferring items into and out of collections
# Currently it only has collection --> collection transfers

# TODO: Item --> collection and collection --> item transfers.
# (not applicable for current project so not added)
needs 'Standard Libs/Units'
needs 'CollectionManagement/SampleManagement'

module CollectionTransfer

  include Units
  include SampleManagement

  # Provides instructions to transfer samples
  #
  # @param input_collection [Collection] the collection samples come from
  # @param working_collection [Collection] the collection samples will move to
  # @param transfer_vol [Integer] volume of sample to transfer (in ul)
  #
  # @param array_of_samples [Array<Sample>] Optional
  # an Array of samples to be transferred
  # if blank then all samples will be transfered
  # QUESTION -- what happens here if array_of_sampels is NOT nil?
  # or -- that is -- is it clear somewhere what you'd do to create the array?
  # This should really be three methods:
  # 1. get the item locations
  # 2. make Data associations
  # 3. give instructions
  def transfer_to_working_plate(input_collection, working_collection, transfer_vol, array_of_samples: nil)
    if array_of_samples.nil?
      array_of_samples = input_collection.parts.map { |part| part.sample if part.class != 'Sample' }
    end
    input_row_column_location = []
    output_row_column_location = []
    array_of_samples.each do |sample|
      input_locations = get_item_sample_location(input_collection, sample)
      # 2d array [[0, 0], [1, 1]]
      input_sample_location = get_alpha_num_location(input_collection, sample)
      # string "A1, B2"
      output_locations = get_item_sample_location(working_collection, sample)
      output_sample_location = get_alpha_num_location(input_collection, sample)

      input_locations.each do |coordinates|
        coordinates.push(input_sample_location) # [0,0,A1]
        input_row_column_location.push(coordinates)
      end

      output_locations.each do |coordinates|
        coordinates.push(output_sample_location)
        output_row_column_location.push(coordinates)
      end
    end

    associate_plate_to_plate(working_collection, input_collection, 'Input Plate', 'Input Item')

    show do
      title 'Transfer from Stock Plate to Working Plate'
      note "Please transfer <b>#{transfer_vol} #{MICROLITERS}</b> from stock plate (<b>ID:#{input_collection.id}</b>) to working
                                plate (<b>ID:#{working_collection.id}</b>) per tables below"
      separator
      note "Stock Plate (ID: <b>#{input_collection.id}</b>):"
      table highlight_collection_rcx(input_collection, input_row_column_location, check: false)
      note "Working Plate (ID: <b>#{working_collection}</b>):"
      table highlight_collection_rcx(working_collection, output_row_column_location, check: false)
    end
  end

  # Instructions to transfer physical samples from input plates to working_plates
  # Groups samples by collection for easier transfer
  # Uses transfer_to_working_plate method
  #
  # @param input_fv_array [Array<FieldValues>] an array of field values of collections
  # @param working_plate [Collection] (Should have samples already associated to it)
  # @param transfer_vol [Integer] volume in ul of sample to transfer
  def transfer_subsamples_to_working_plate(input_fv_array, working_plate, transfer_vol)
    # was transfer_to_collection_from_fv_array
    sample_array_by_collection = input_fv_array.group_by { |fv| fv.collection }
    sample_array_by_collection.each do |input_collection, fv_array|
      sample_array = fv_array.map { |fv| fv.sample }
      transfer_to_working_plate(input_collection, working_plate, transfer_vol, array_of_samples: sample_array)
    end
  end

  # Instructions on relabeling plates to new plate ID
  #
  # @param plate1 [Collection] plate to relabel
  # @param plate2 [Collection] new plate label
  def relabel_plate(plate1, plate2)
    show do
      title 'Rename Plate'
      note "Relabel plate <b>#{plate1.id}</b> with <b>#{plate2.id}</b>"
    end
  end

  # Determines if there are multiple plates
  #
  # @param operations [OperationList] list of operations in job
  # @param role [String], whether plates are for input or output
  # @returns boolean true if multiple plates
  def multiple_plates?(operations, role: 'input')
    return true if get_num_plates(operations, role) > 1
  end

  # gets the number of plates
  #
  # @param operations [OperationList] list of operations in job
  # @param role [String] indicates whether it's an input or output collection
  # @returns [Int] the number of plates
  def get_num_plates(operations, role)
    get_array_of_collections(operations, role).length
  end

  # gets the number of plates
  #
  # @param operations [OperationList] list of operations in job
  # @param role [String] indicates whether it's an input or output collection
  # @returns Array[collection] the number of plates
  def get_array_of_collections(operations, role)
    collection_array = []
    operations.each do |op|
      obj_array = op.inputs if role == 'input'
      obj_array = op.outputs if role == 'output'
      obj_array.each do |fv|
        if fv.collection != nil
          collection_array.push(fv.collection)
        end
      end
    end
    collection_array.uniq
  end

  # Creates Data Association between working plate items and input items
  # Associates corrosponding well locations that contain a part.
  #
  # @param working_plate [Collection] the plate that is getting the association
  # @param input_plate [Collection] the plate that is transfering the association
  # @param plate_key [String] "input plate"
  # @param item_key [String] "input item"
  def associate_plate_to_plate(working_plate, input_plate, plate_key, item_key)
    working_plate.associate(plate_key, input_plate)
    input_parts = input_plate.parts
    working_parts = working_plate.parts
    working_parts.each_with_index do |part, idx|
      part.associate(item_key, input_parts[idx])
    end
  end
end
