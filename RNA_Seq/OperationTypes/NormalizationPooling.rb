#Cannon Mallory
#UW-BIOFAB
#03/04/2019
#malloc3@uw.edu

needs "Standard Libs/Debug"
needs "Standard Libs/CommonInputOutputNames"
needs "Standard Libs/Units"

needs "Collection_Management/CollectionDisplay"
needs "Collection_Management/CollectionTransfer"
needs "Collection_Management/CollectionActions"
needs "Collection_Management/CollectionLocation"
needs "RNA_Seq/WorkflowValidation"
needs "RNA_Seq/KeywordLib"

class Protocol
  include Debug
  include CollectionDisplay
  include CollectionTransfer
  include CollectionLocation
  include CollectionActions
  include WorkflowValidation
  include CommonInputOutputNames
  include KeywordLib

  TRANSFER_VOL = 20   #volume of sample to be transfered in ul


  def main

    validate_inputs(operations, inputs_match_outputs: true)
    validate_cdna_qc(operations)
    operations.retrieve

    working_plate = make_new_plate(COLLECTION_TYPE, label_plate: multi_plate)
    operations.each do |op|
      input_fv_array = op.input_array(INPUT_ARRAY)
      output_fv_array = op.output_array(OUTPUT_ARRAY)
      associate_field_values_to_plate(output_fv_array, working_plate)
      transfer_subsamples_to_working_plate(input_fv_array, working_plate, TRANSFER_VOL)
    end

    normalization_pooling(working_plate)
    store_output_collections(operations, location: 'Freezer')
  end

  # Instructions for performing RNA_PREP
  #
  # @param working_plate [Collection] the plate with samples

  def normalization_pooling(working_plate)
    show do
      title "Do the Normalization Pooling Steps"
      note "Run typical Normalization Pooling protocol with plate #{working_plate.id}"
      table highlight_non_empty(working_plate, check: false)
    end
  end
end