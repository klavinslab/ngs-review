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
  PLATE_HEADERS = ['Plate',	'Repeat',	'End time',	'Start temp.',	'End temp.',	'BarCode'].freeze # freeze constant
  PLATE_LOCATION = 'TBD Location of file'

  BIO_HEADERS = ['Well', 'Sample ID',	'Conc. (ng/ul)',	'RQN',	'28S/18S'].freeze # freeze constant
  BIO_LOCATION = 'TBD Location of file'

  RIN_MIN = 3
  RIN_MAX = 10

  CONC_MIN = 8
  CONC_MAX = 100
  UP_MARG = 500
  LOW_MARG = 5

  def main
    return true if validate_inputs(operations) #validat_inputs retun true if invalid

    working_plate = make_new_plate(COLLECTION_TYPE)
    operations.retrieve

    #this is so if the protocol fails we dont end up with a bunch of 
    # plats in inventory that actually dont exist. 
    working_plate.mark_as_deleted
    working_plate.save

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
                  measurement_type: 'rna')
    rin_map = parse_csv_for_data(bio_csv, data_header: BIO_HEADERS[3], alpha_num_header: BIO_HEADERS[0])
    associate_value_to_parts(plate: working_plate, data_map: rin_map, key: RIN_KEY)

    rin_info = generate_data_range(key: RIN_KEY, minimum: RIN_MIN, maximum: RIN_MAX)
    conc_info = generate_data_range(key: CON_KEY, minimum: CONC_MIN, maximum: CONC_MAX, 
             lower_margin: LOW_MARG, upper_margin: UP_MARG)
    asses_qc_values(working_plate, [rin_info, conc_info])
    

    show_key_associated_data(working_plate, [QC_STATUS, CON_KEY, RIN_KEY])


    #TODO For some reason it will not overwrite the old association... Not sure why but it wont.
    # so once a qc has been established it is that way for ever
    associate_data_back_to_input(working_plate, [QC_STATUS, CON_KEY, RIN_KEY], operations)
    

    trash_object(working_plate)

    downstream_op_type = 'RNA Prep'
    return if stop_qc_failed_operations(operations, downstream_op_type)
  end
end