# RNA Prep

This preps RNA and makes cDNA.  The actual steps of RNA Prep are not illustrated well (by direction from Duke Genome Center).

Primarily this Protocol assists in batching of jobs.   Must be run after RNA QC
### Inputs


- **Input Array** [R] (Array) 
  - <a href='#' onclick='easy_select("Sample Types", "RNA Sample")'>RNA Sample</a> / <a href='#' onclick='easy_select("Containers", "Total RNA 96 Well Plate")'>Total RNA 96 Well Plate</a>



### Outputs


- **Output Array** [R] (Array) 
  - <a href='#' onclick='easy_select("Sample Types", "RNA Sample")'>RNA Sample</a> / <a href='#' onclick='easy_select("Containers", "96 Well Sample Plate")'>96 Well Sample Plate</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
#This precondition checks that all inputs into the operation have valid concentrations and are ready to be used.
#Parts are copied from the WorkflowValidation Lib see note below for explination

#Dont want to return false.  Only return true if it passes
def precondition(op)
  true 
  #_op = Operation.find(op.id)#

  #loops = _op.get("Loops".to_sym)
  #_op.associate("Initial_Loopos".to_sym, loops)
  #if loops.nil?
  #  loops = 0
  #else
  #  loops += 1
  #end

  #_op.associate("Loops".to_sym, loops)

#  pass = true
#  range = (50...100)#

  #_op.input_array("Input Array").each do |field_value|
  #  conc = field_value.part.get("Stock Conc (ng/ul)".to_sym)
  #  pass = false unless range.cover?(conc)
  #end

  ##if pass
    #_op.associate("Pass is true".to_sym, "Pass was true")
    #_op.associate("Pass is false".to_sym, "Its actually true now")
    #_op.status = 'pending'
    #_op.save
  #end
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
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
needs 'Collection_Management/CollectionLocation'
needs 'RNA_Seq/MiscMethods'
needs 'RNA_Seq/TakeMeasurements'
needs 'RNA_Seq/ParseCSV'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/KeywordLib'
needs 'RNA_Seq/DataHelper'
needs 'RNA_Seq/CSVDebugLib'

require 'csv'

class Protocol
  include Debug
  include Units
  include CollectionDisplay
  include CollectionTransfer
  include CollectionLocation
  include CommonInputOutputNames
  include CollectionActions
  include UploadHelper
  include WorkflowValidation
  include DataHelper
  include MiscMethods
  include TakeMeasurements
  include ParseCSV
  include KeywordLib
  include CSVDebugLib

  ADAPTER_TRANSFER_VOL = 12 # volume of adapter to transfer
  TRANSFER_VOL = 20 # volume of sample to be transferred in ul
  CONC_RANGE = (50...100).freeze # acceptable concentration range
  CSV_HEADERS = ['Plate ID', 'Well Location'].freeze
  CSV_LOCATION = 'Location TBD'.freeze
  ADAPTER_KEY = 'Adapter_key'.to_sym

  def main
    return if validate_inputs(operations, inputs_match_outputs: true)
    return if validate_qc(operations)

    working_plate = setup_job(operations, TRANSFER_VOL, qc_step: false)

    adapter_plates = make_adapter_plate(working_plate.parts.length)
    adapter_plates.each do |adapter_plate|
      working_plate.associate(ADAPTER_KEY, adapter_plate)
      associate_plate_to_plate(to_collection: working_plate,
                               from_collection: adapter_plate)
    end

    rna_prep_steps(working_plate)
    store_output_collections(operations, location: 'Freezer')
  end

  # Instructions for performing RNA_PREP
  #
  # @param working_plate [Collection] the plate that has all samples in it
  def rna_prep_steps(working_plate)
    show do
      title 'Run RNA-Prep'
      note "Run typical RNA-Prep Protocol with RNA plate #{working_plate.id}
                and adapter plate #{working_plate.get(ADAPTER_KEY).class}"
      table highlight_non_empty(working_plate, check: false)
    end
  end

  # Instructions for making an adapter plate
  #
  # @param num_adapter_needed [int] the number of adapters needed for job
  # @return adapter_plate [Array<collection>] plate with all required adapters
  #
  # TODO: Add feature so that they can specify the specific sample that the
  #   adapter needs to match with Or perhapses specify the specific groups that
  #   they need to go to (or a combination there of)
  def make_adapter_plate(num_adapters_needed)
    adapter_plates = []

    show do
      title 'Make Adapter Plate'
      note 'On the next page upload CSV of desired Adapters'
    end

    up_csv = get_validated_uploads(min_length: num_adapters_needed, 
                                   headers: CSV_HEADERS, 
                                   file_location: CSV_LOCATION)
    col_parts_hash = sample_from_csv(up_csv)

    col_parts_hash.each do |collection_item, parts|
      collection = Collection.find(collection_item.id)

      plates = make_and_populate_collection(parts,
                                            collection_type: COLLECTION_TYPE,
                                            add_column_wise: true,
                                            label_plates: false)
      plates.each do |adapter_plate|
        transfer_from_collection_to_collection(collection,
                                             to_collection: adapter_plate,
                                             transfer_vol: ADAPTER_TRANSFER_VOL,
                                             populate_collection: false,
                                             array_of_samples: parts)
        adapter_plates.push(adapter_plate)
      end
    end
    adapter_plates
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
      csv.drop(1).each do |row|
        collection = Collection.find(row[id_idx])
        part = part_alpha_num(collection, row[loc_idx])
        parts.push(part)
      end
    end
    parts.group_by(&:containing_collection)
  end
end

```
