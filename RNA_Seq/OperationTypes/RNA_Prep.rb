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
needs "RNA_Seq/CsvDebugLib"

require 'csv'

class Protocol
  include Debug, CollectionDisplay, CollectionTransfer, SampleManagement, CollectionActions
  include WorkflowValidation, CommonInputOutputNames, KeywordLib, CsvDebugLib
  C_TYPE = "96 Well Sample Plate"
  CON_KEY = "Stock Conc (ng/ul)"

  PLATE_ID = "Plate ID"
  WELL_LOCATION = "Well Location"
  ADAPTER_TRANSFER_VOL = 12 #volume of adapter to transfer
  TRANSFER_VOL = 20   #volume of sample to be transfered in ul
  CONC_RANGE = (50...100)


  def main

    validate_inputs(operations, inputs_match_outputs = true)

    validate_concentrations(operations, CONC_RANGE)

    working_plate = make_new_plate(C_TYPE)

    adapter_plate = make_adapter_plate

    operations.retrieve

    operations.each do |op|
      input_fv_array = op.input_array(INPUT_ARRAY)
      output_fv_array = op.output_array(OUTPUT_ARRAY)
      add_fv_array_samples_to_collection(input_fv_array, working_plate)
      make_output_plate(output_fv_array, working_plate)
      transfer_from_array_collections(input_fv_array, working_plate, TRANSFER_VOL)
    end

    associate_plate_to_plate(working_plate, adapter_plate, ADAPTER_PLATE, ADAPTER)

    store_input_collections(operations)
    rna_prep_steps(working_plate)
    store_output_collections(operations, 'Freezer')
  end

  #Instructions for performing RNA_PREP
  #
  # @working_plate collection the plate that has all samples in it
  def rna_prep_steps(working_plate)
    show do
      title "Run RNA-Prep"
      note "Run typical RNA-Prep Protocol with plate #{working_plate.id}"
      table highlight_non_empty(working_plate)
    end
  end


  #Instructions for making an adapter plate
  #
  #returns:
  # @adapter_plate collection the adapter plate
  def make_adapter_plate
    adapter_plate = make_new_plate(C_TYPE)
    up_csv = upload_and_csv
    col_parts_hash = sample_from_csv(up_csv)
    validate_csv(col_parts_hash)
    col_parts_hash.each do |collection_item, parts|
      collection = Collection.find(collection_item.id)
      adapter_plate.add_samples(parts)
      transfer_to_working_plate(collection, adapter_plate, arry_sample = parts, ADAPTER_TRANSFER_VOL)
    end
    return adapter_plate
  end

  #Validates CSV information to make sure that it matches inputs
  #
  #@col_parts_hash  a hash of parts with the collection that they originate in as the key
  def validate_csv(col_parts_hash)
    total_samples = 0
    total_adapters = 0

    operations.each do |op|
      total_samples = total_samples + op.input_array(INPUT_ARRAY).length
    end

    col_parts_hash.each do |col, parts|
      total_adapters = total_adapters + parts.length
    end

    raise "Not enough adapters for all samples in job" if total_adapters < total_samples #TODO loop back to upload
    if total_adapters > total_samples  #TODO could have it loop back to upload here too
      show do 
        title "More Adapters than needed"
        note "The CSV uploaded adds more adapters than needed."
        note "Click OKAY to continue with this job or Cancel to Cancel"
      end
    end
  end

  #Gets CSV upload and associates each CSV file with the operation in question
  #
  #returns
  #@CSV CSV a csv file with the desired adapter plate wells
  def upload_and_csv
    up_csv = show do
      title "Make CSV file of Adapters"
      note "Please make a <b>CSV</B> file of all required adapters"
      note "Row 1 is Reserved for headers"
      note "Column 1: '#{PLATE_ID}'"
      note "Column 2: '#{WELL_LOCATION}' (e.g. A1, B1)"
      upload var: CSV_KEY.to_sym
    end
    if debug
      return CSV_DEBUG
    else
      return up_csv.get_response(CSV_KEY.to_sym)
    end
  end




  #Parses CSV and returns an array of all the samples required
  #@ CSV  CSV a csv file of thee adapter plate wells
  #
  #returns hash[key: collection, array[parts]]
  def sample_from_csv(csv_uploads)
    parts = []
    csv = CSV.parse(csv_upload) if debug
    csv_uploads.each do |upload|
      csv = CSV.read(open(upload.url))
      csv.each_with_index do |row, idx|
        if idx != 0
          collection = Collection.find(row[0])
          part = part_alpha_num(collection, row[1])
          parts.push(part)
        end
      end
    end
    return parts.group_by{|part| part.containing_collection}
  end
end
e
