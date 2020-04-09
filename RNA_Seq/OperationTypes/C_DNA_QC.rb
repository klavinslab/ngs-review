# frozen_string_literal: true

# Cannon Mallory
# UW-BIOFAB
# 03/04/2019
# malloc3@uw.edu
#
# This Protocol is to Quality check the C-DNA created.

needs 'Standard Libs/Debug'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Units'
needs 'Collection_Management/CollectionDisplay'
needs 'Collection_Management/CollectionTransfer'
needs 'Collection_Management/CollectionActions'
needs 'Collection_Management/SampleManagement'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/KeywordLib'

class Protocol
  include CollectionDisplay
  include CollectionTransfer
  include CollectionActions
  include CommonInputOutputNames
  include KeywordLib
  include Debug
  include SampleManagement
  include WorkflowValidation

  TRANSFER_VOL = 20 # volume of sample to be transfered in ul

  def main
    validate_inputs(operations)

    working_plate = make_new_plate(COLLECTION_TYPE)

    operations.retrieve

    operations.each do |op|
      input_fv_array = op.input_array(INPUT_ARRAY)
      add_fv_array_samples_to_collection(input_fv_array, working_plate)
      transfer_to_collection_from_fv_array(input_fv_array, working_plate, TRANSFER_VOL)
    end

    store_input_collections(operations)
    take_qc_measurments(working_plate)
    trash_object(working_plate)
  end

  # Gives instruction for taking the QC measurements
  # Currently not operational but associates random concentrations for testing
  #
  # @param working_plate [collection] the plate with samples
  def take_qc_measurments(working_plate)
    input_rcx = []
    operations.each do |op|
      input_array = op.input_array(INPUT_ARRAY)
      input_items = input_array.map { |fv| fv.item }
      arry_sample = input_array.map { |fv| fv.sample }
      input_items.each_with_index do |item, idx|
        item.associate(QC2_KEY, 'Pass')
        sample = arry_sample[idx]
        working_plate_loc_array = working_plate.find(sample)
        working_plate_loc_array.each do |sub_array|
          sub_array.push("#{item.get(QC2_KEY)}")
          input_rcx.push(sub_array)
        end
      end
    end

    show do
      title 'Perform QC Measurements'
      note 'Please Attach excel files'
      note 'For testing purposes each sample will assume to pass'
      note 'This will eventually come from a CSV file'
      table highlight_collection_rcx(working_plate, input_rcx, check: false)
    end
  end
end
