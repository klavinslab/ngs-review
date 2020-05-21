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
needs 'RNA_Seq/MiscMethods'
needs 'RNA_Seq/TakeMeasurements'
needs 'RNA_Seq/ParseCSV'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/KeywordLib'
needs 'RNA_Seq/DataHelper'
needs 'RNA_Seq/CSVDebugLib'

class Protocol
  include Debug
  include Units
  include CollectionDisplay
  include CollectionTransfer
  include CollectionLocation
  include CollectionActions
  include CommonInputOutputNames
  include WorkflowValidation
  include DataHelper
  include MiscMethods
  include TakeMeasurements
  include ParseCSV
  include KeywordLib
  include CSVDebugLib

  TRANSFER_VOL = 20   #volume of sample to be transferred in ul


  def main

    return if validate_inputs(operations, inputs_match_outputs: true)
        || validate_qc(operations)

    working_plate = setup_job(operations, TRANSFER_VOL, qc_step: false)

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