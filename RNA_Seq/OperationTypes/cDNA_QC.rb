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
needs 'Standard Libs/UploadHelper'
needs 'Collection_Management/CollectionDisplay'
needs 'Collection_Management/CollectionTransfer'
needs 'Collection_Management/CollectionActions'
needs 'Collection_Management/CollectionLocation'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/KeywordLib'
needs 'RNA_Seq/DataHelper'

class Protocol
  include CollectionDisplay
  include CollectionTransfer
  include CollectionActions
  include CommonInputOutputNames
  include KeywordLib
  include Debug
  include CollectionLocation
  include WorkflowValidation
  include UploadHelper
  include DataHelper

  TRANSFER_VOL = 20 # volume of sample to be transfered in ul
  PLATE_HEADERS = ['Plate',	'Repeat',	'End time',	'Start temp.',	'End temp.',	'BarCode'].freeze # freeze constant
  PLATE_LOCATION = 'TBD Location of file'

  BIO_HEADERS = ['Well',	'Sample ID',	'Range',	'ng/uL',	'% Total',	'nmole/L',	'Avg. Size',	'%CV'].freeze # freeze constant
  BIO_LOCATION = 'TBD Location of file'

  def main
    validate_inputs(operations)

    working_plate = make_new_plate(COLLECTION_TYPE)

    operations.retrieve

    operations.each do |op|
      input_field_value_array = op.input_array(INPUT_ARRAY)
      transfer_subsamples_to_working_plate(input_field_value_array, working_plate, TRANSFER_VOL)
    end

    store_input_collections(operations)

    dilution_factor_map = get_dilution_factors(working_plate)
    associate_value_to_parts(plate: working_plate, data_map: dilution_factor_map, key: DILUTION_FACTOR)

    plate_reader_csv, standards = take_duke_plate_reader_measurement(working_plate, PLATE_HEADERS, PLATE_LOCATION)
    slope, intercept = calculate_slope_intercept(point_one: standards[0], point_two: standards[1])

    concentration_map = calculate_concentrations(slope: slope, intercept: intercept, 
                  plate_csv: plate_reader_csv, dilution_map: dilution_factor_map)
    associate_value_to_parts(plate: working_plate, data_map: concentration_map, key: CON_KEY)
    

    bio_csv = take_bioanalizer_measurement(working_plate, BIO_HEADERS, BIO_LOCATION, 
                  measurement_type: 'library')
    ave_size_map = parse_csv_for_data(bio_csv, data_header: BIO_HEADERS[6], alpha_num_header: BIO_HEADERS[0])
    associate_value_to_parts(plate: working_plate, data_map: ave_size_map, key: AVE_SIZE_KEY)

    #todo do math on qc measurements
    show do
      title "Measured Data"
      note "Listed below are the data collected"
      note "Concentration (ng/ul):"
      table display_data(working_plate, CON_KEY)
      note "Avg. Size"
      table display_data(working_plate, AVE_SIZE_KEY)
    end

    trash_object(working_plate)
  end
end
