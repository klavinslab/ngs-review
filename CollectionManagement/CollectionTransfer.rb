# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Methods for transferring items into and out of collections
# Currently it only has collection --> collection transfers

# TODO: Item --> collection and collection --> item transfers.
# (not applicable for current project so not added)
needs 'Standard Libs/Units'

module CollectionTransfer

  include Units

  # Provides instructions to transfer samples
  #
  # @param input_collection [Collection] the collection samples will be transfered from
  # @param working_collection [Collection] the collection samples will be transfered to
  # @param transfer_vol [Integer] volume in ul of sample to transfer
  #
  # @param array_of_samples  [Array<Sample>] Optional an array of all samples to be transfered
  # if blank then all samples will be transfered
  def transfer_to_working_plate(input_collection, working_collection, transfer_vol, array_of_samples: nil)
    if array_of_samples.nil?
      array_of_samples = input_collection.parts.map { |part| part.sample if part.class != 'Sample' }
    end
    input_rcx = []
    output_rcx = []
    array_of_samples.each do |sample|
      input_location_array = get_item_sample_location(input_collection, sample) # 2d array
      # [[0, 0], [1, 1]]
      input_sample_location = get_alpha_num_location(input_collection, sample) # String
      # "A1, B2"
      output_location_array = get_item_sample_location(working_collection, sample)
      output_sample_location = get_alpha_num_location(input_collection, sample)

      input_location_array.each do |sub_array|
        sub_array.push(input_sample_location) # [0,0,A1]
        input_rcx.push(sub_array)
      end

      output_location_array.each do |sub_array|
        sub_array.push(output_sample_location)
        output_rcx.push(sub_array)
      end
    end

    associate_plate_to_plate(working_collection, input_collection, 'Input Plate', 'Input Item')

    show do
      title 'Transfer from Stock Plate to Working Plate'
      note "Please transfer #{transfer_vol} #{MICROLITERS} from stock plate (ID:#{input_collection.id}) to working plate (ID:#{working_collection.id}) per tables below"
      note 'Separator'
      note "Stock Plate (ID: #{input_collection.id}):"
      table highlight_collection_rcx(input_collection, input_rcx, check: false)
      note "Working Plate (ID: #{working_collection}):"
      table highlight_collection_rcx(working_collection, output_rcx, check: false)
    end
  end

  # Instructions to transfer physical samples from input plates to working_plates
  # Groups samples by collection together for easier transfer
  # Uses transfer_to_working_plate method
  #
  # @param input_fv_array [Array<FieldValues>] an array of field values of collectionsy
  # @param working_plate [Collection] (Should have samples already associated to it)
  # @param transfer_vol [Integer] volume in ul of sample to transfer
  def transfer_subsamples_to_working_plate(input_fv_array, working_plate, transfer_vol) 
    # was transfer_to_collection_from_fv_array
    sample_array_by_collection = input_fv_array.group_by { |fv| fv.collection }
    sample_array_by_collection.each do |input_collection, fv_array|
      sample_array = fv_array.map { |fv| fv.sample }
      transfer_to_working_plate(input_collection, working_plate, sample_array, transfer_vol)
    end
  end

  # Instructions on relabeling plates to new plate ID
  #
  # @param plate1 [Collection] plate to be relabel
  # @param plate2 [Collection] new plate label
  def relabel_plate(plate1, plate2)
    show do
      title 'Rename Plate'
      note "Relabel plate #{plate1.id} with #{plate2.id}"
    end
  end

  # determines if there are multiple output plate
  #
  # @param operations [OperationList] list of operations in job
  # @returns boolean true if multiple plates
  def multi_input_plates?(operations)
    if get_num_plates(operations, 'input') > 1
      return true
    else
      return false
    end
  end

  # determines if there are multiple output plates
  #
  # @param operations [OperationList] list of operations in job
  # @returns boolean true if multiple plates
  def multi_output_plates?(operations)
    if get_num_plates(operations, 'output') > 1
      return true
    else
      return false
    end
  end

  # gets the number of plate
  #
  # @param operations [OperationList] list of operations in job
  # @param in_out [String] input or output determines if its input or output collections
  # @returns [Int] the number of plates 
  def get_num_plates(operations, in_out)
    return get_array_of_collections(operations, in_out).length
  end

  # gets the number of plate
  #
  # @param operations [OperationList] list of operations in job
  # @param in_out [String] input or output determines if its input or output collections
  # @returns Array[collection] the number of plates
  def get_array_of_collections(operations, in_out)
    collection_array = []
    operations.each do |op|
      obj_array = op.inputs if in_out = 'input'
      obj_array = op.outputs if in_out = 'output'
      obj_array.each do |fv|
        if fv.collection != nil
          collection_array.push(fv.collection)
        end
      end
    end
    collection_array.uniq
  end

  # associates all items in the added_plate to the items in the base plate
  # Associates corrosponding well locations.  Assocaites plate to plate and well to well
  # Only associates to wells that have a part in them
  # associate(key, value, upload = nil, options = { duplicates: false }) ⇒ Object#
  # @param base_plate [Collection] the plate that is getting the association
  # @param added_plate [Collection] the plate that is transfering the association
  # @param plate_key [String] "input plate"
  # @param item_key [String] "input item"
  def associate_plate_to_plate(base_plate, added_plate, plate_key, item_key)
    base_plate.associate(plate_key, added_plate) # {"input_plate" => added_plate}
    added_parts = added_plate.parts # items in added plate
    base_parts = base_plate.parts # items in base plate
    base_parts.each_with_index do |part, idx|
      part.associate(item_key, added_parts[idx]) # {"input item" => }
    end
  end
end
