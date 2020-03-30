#Cannon Mallory
#UW-BIOFAB
#03/04/2019
#malloc3@uw.edu
#
#
#This protocol is for total RNA QC.  It Will take in a batch of samples, replate these
#samples together onto a 96 well plate that will then go through a QC protocols including
#getting the concentrations of the original sampole.  These concentrations will then be associated
#with the original sample for use later.


#Currently build plate needs a bit of work.  It works by order of input array and not by order of sample location on plate


needs "Standard Libs/Debug"
needs "Standard Libs/CommonInputOutputNames"
needs "Standard Libs/Units"

needs "Collection_Management/CollectionDisplay"
needs "Collection_Management/CollectionTransfer"
needs "Collection_Management/CollectionActions"
needs "Collction_Management/SampleManagement"
needs "RNA_Seq/WorkflowValidation"
needs "RNA_Seq/KeywordLib"

class Protocol
  include Debug, CollectionDisplay, CollectionTransfer, SampleManagement, CollectionActions
  include WorkflowValidation, CommonInputOutputNames, KeywordLib
  C_TYPE = "96 Well Sample Plate"

  TRANSFER_VOL = 20   #volume of sample to be transfered in ul


  def main

    validate_inputs(operations, inputs_match_outputs = true)

    validate_cdna_qc(operations)

    multi_plate = multi_input_plates?(operations)

    working_plate = make_new_plate(C_TYPE, multi_plate)
  
    operations.retrieve

    operations.each do |op|
      input_fv_array = op.input_array(INPUT_ARRAY)
      output_fv_array = op.output_array(OUTPUT_ARRAY)
      add_fv_array_samples_to_collection(input_fv_array, working_plate)
      make_output_plate(output_fv_array, working_plate)
      transfer_from_array_collections(input_fv_array, working_plate, TRANSFER_VOL) if multi_plate
    end

    if !multi_plate
      input_plate = operations.first.input_array(INPUT_ARRAY).first.collection
      relabel_plate(input_plate,working_plate) if !multi_plate
      input_plate.mark_as_deleted
    else
      trash_object(get_array_of_collections(operations, 'input')) if multi_plate
    end

    normalization_pooling(working_plate)

    store_output_collections(operations, 'Freezer')
  end

  #Instructions for performing RNA_PREP
  #
  # @working_plate collection the plate that has all samples in it
  def normalization_pooling(working_plate)
    show do
      title "Do the Normalization Pooling Steps"
      note "Run typical Normalization Pooling protocol with plate #{working_plate.id}"
      table highlight_non_empty(working_plate)
    end
  end
end