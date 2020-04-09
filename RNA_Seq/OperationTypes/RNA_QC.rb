# frozen_string_literal: true

# Cannon Mallory
# UW-BIOFAB
# 03/04/2019
# malloc3@uw.edu

needs 'Standard Libs/Debug'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Units'
needs 'Standard Libs/UploadHelper'
needs 'Collection_Management/CollectionDisplay'
needs 'Collection_Management/CollectionTransfer'
needs 'Collection_Management/CollectionActions'
needs 'Collection_Management/SampleManagement'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/KeywordLib'

class Protocol
  include CollectionActions
  include CollectionDisplay
  include CollectionTransfer
  include CommonInputOutputNames
  include Debug
  include KeywordLib
  include SampleManagement
  include Units
  include UploadHelper
  include WorkflowValidation

  TRANSFER_VOL = 20 # volume of sample to be transfered in ul
  CSV_HEADERS = ['Well Position', 'Conc(ng/ul)'].freeze # freeze constant
  CSV_LOCATION = 'TBD Location of file'

  def main
    validate_inputs(operations)

    working_plate = make_new_plate(COLLECTION_TYPE)
    operations.retrieve

    operations.each do |op|
      input_field_value_array = op.input_array(INPUT_ARRAY)
      add_fv_array_samples_to_collection(input_field_value_array, working_plate)
      transfer_subsample_to_working_plate(input_field_value_array, working_plate, TRANSFER_VOL)
    end

    store_input_collections(operations)
    take_qc_measurements(working_plate)
    list_concentrations(working_plate)
    trash_object(working_plate)
  end

  # Instructions for taking the QC measurements
  # Currently not operational but associates random concentrations for testing
  #
  # @param working_plate [Collection] the plate of samples needing measurements
  def take_qc_measurements(working_plate)
    show do
      title "Load Plate #{working_plate.id} on Plate Reader"
      note 'Load plate on plate reader and take concentration measurements'
      note 'Save output data as CSV and upload on next page'
    end

    csv_uploads = get_validated_uploads(working_plate.parts.length,
        CSV_HEADERS: false, file_location: CSV_LOCATION)

    upload = csv_uploads.first
    csv = CSV.read(open(upload.url))
    conc_idx = csv.first.find_index(CSV_HEADERS[1])
    loc_idx = csv.first.find_index(CSV_HEADERS[0])
    csv.drop(1).each_with_index do |row, idx|
      alpha_loc = row[loc_idx]
      conc = row[conc_idx].to_i
      part = part_alpha_num(working_plate, alpha_loc)
      if !part.nil?
        part.associate(CON_KEY, conc)
        samp = part.sample
        operations.each do |op|
          op.input_array(INPUT_ARRAY).each do |field_value|
            if samp == field_value.sample
              field_value.part.associate(CON_KEY, conc)
            end
          end
        end
      end
    end
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
