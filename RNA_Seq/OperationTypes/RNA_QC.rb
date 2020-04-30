# frozen_string_literal: true

# Cannon Mallory
# UW-BIOFAB
# 03/04/2019
# malloc3@uw.edu


needs 'RNA_Seq/DataHelper'
needs 'Standard Libs/Debug'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Units'
needs 'Standard Libs/UploadHelper'
needs 'Collection_Management/CollectionDisplay'
needs 'Collection_Management/CollectionTransfer'
needs 'Collection_Management/CollectionActions'
needs 'Collection_Management/CollectionLocation'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/KeywordLib'



class Protocol
  include CollectionActions
  include CollectionDisplay
  include CollectionTransfer
  include CommonInputOutputNames
  include Debug
  include KeywordLib
  include CollectionLocation
  include Units
  include UploadHelper
  include WorkflowValidation
  include DataHelper

  TRANSFER_VOL = 20 # volume of sample to be transfered in ul
  CSV_HEADERS = ['Plate',	'Repeat',	'End time',	'Start temp.',	'End temp.',	'BarCode'].freeze # freeze constant
  CSV_LOCATION = 'TBD Location of file'

  def main
    validate_inputs(operations)

    working_plate = make_new_plate(COLLECTION_TYPE)
    operations.retrieve

    operations.each do |op|
      input_field_value_array = op.input_array(INPUT_ARRAY)
      transfer_subsamples_to_working_plate(input_field_value_array, working_plate, TRANSFER_VOL)
    end

    store_input_collections(operations)
    plate_reader_data = take_duke_plate_reader_measurement(working_plate, CSV_HEADERS, CSV_LOCATION)

    #todo do math on qc measurements
    #list_concentrations(working_plate)
    #trash_object(working_plate)
  end



  # Lists the measured concentrations.
  # TODO write highlight heat map method for table
  #
  # @param working_plate [Collection] the plate being used
  def list_concentrations(working_plate)
    rcx_array = []
    parts = working_plate.parts
    parts.each do |part|
      loc_array = working_plate.find(part)
      loc_array.each do |loc|
        loc.push(part.get(CON_KEY))
        rcx_array.push(loc)
      end
    end
    show do
      title 'Measurements Take'
      note 'Recorded Concentrations are listed below'
      table highlight_collection_rcx(working_plate, rcx_array, check: false)
    end
  end
end
