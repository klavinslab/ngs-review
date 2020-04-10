# frozen_string_literal: true

# Cannon Mallory
# UW-BIOFAB
# 03/04/2019
# malloc3@uw.edux

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
needs 'RNA_Seq/CsvDebugLib'

require 'csv'

class Protocol
  include Debug
  include CollectionDisplay
  include CollectionTransfer
  include SampleManagement
  include WorkflowValidation
  include CommonInputOutputNames
  include KeywordLib
  include CsvDebugLib
  include CollectionActions
  include UploadHelper

  ADAPTER_TRANSFER_VOL = 12 # volume of adapter to transfer
  TRANSFER_VOL = 20 # volume of sample to be transfered in ul
  CONC_RANGE = (50...100) # acceptable concentration range
  CSV_HEADERS = ['Plate ID', 'Well Location'].freeze
  CSV_LOCATION = 'Location TBD'

  def main

    validate_inputs(operations, inputs_match_outputs: true)
    validate_concentrations(operations, CONC_RANGE)

    working_plate = make_new_plate(COLLECTION_TYPE)
    operations.retrieve

    operations.each do |op|
      input_fv_array = op.input_array(INPUT_ARRAY)
      output_fv_array = op.output_array(OUTPUT_ARRAY)
      add_samples_to_collection(input_fv_array, working_plate)
      make_output_plate(output_fv_array, working_plate)
      transfer_subsamples_to_working_plate(input_fv_array, working_plate, TRANSFER_VOL)
    end

    adapter_plate = make_adapter_plate(working_plate.parts.length)
    associate_plate_to_plate(working_plate, adapter_plate, ADAPTER_PLATE, ADAPTER)
    store_input_collections(operations)
    rna_prep_steps(working_plate)
    store_output_collections(operations, location: 'Freezer')
  end

  # Instructions for performing RNA_PREP
  #
  # @param working_plate [collection] the plate that has all samples in it
  def rna_prep_steps(working_plate)
    show do
      title 'Run RNA-Prep'
      note "Run typical RNA-Prep Protocol with plate #{working_plate.id}"
      table highlight_non_empty(working_plate, check: false)
    end
  end

  # Instructions for making an adapter plate
  #
  # @param num_adapter_needed [int] the number of adapters needed for job
  # @return adapter_plate [collection] plate with all required adapters
  def make_adapter_plate(num_adapters_needed)
    adapter_plate = make_new_plate(COLLECTION_TYPE)

    show do
      title 'Upload CSV'
      note 'On the next page upload CSV of desired Adapters'
    end

    up_csv = get_validated_uploads(num_adapters_needed, CSV_HEADERS, false, file_location: CSV_LOCATION)
    col_parts_hash = sample_from_csv(up_csv)
    col_parts_hash.each do |collection_item, parts|
      collection = Collection.find(collection_item.id)
      adapter_plate.add_samples(parts)
      transfer_to_working_plate(collection, adapter_plate, arry_sample = parts, ADAPTER_TRANSFER_VOL)
    end
    adapter_plate
  end

  # Parses CSV and returns an array of all the samples
  #
  #
  # @param csv_uploads [array] array of uploaded CSV files
  # @returns hash [key: collection, array[parts]] hash of collection and samples
  def sample_from_csv(csv_uploads)
    parts = []
    csv = CSV.parse(csv_upload) if debug
    csv_uploads.each do |upload|
      csv = CSV.read(open(upload.url))

      first_row = csv.first
      first_row[0][0] = ''

      id_idx = first_row.find_index(CSV_HEADERS[0])
      loc_idx = first_row.find_index(CSV_HEADERS[1])
      csv.drop(1).each_with_index do |row, idx|
        collection = Collection.find(row[id_idx])
        part = part_alpha_num(collection, row[loc_idx])
        parts.push(part)
      end
    end
    parts.group_by { |part| part.containing_collection }
  end
end
