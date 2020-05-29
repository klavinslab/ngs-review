# RNA QC

Total RNA QC

Plates sub-samples onto a 96 well plate. Measures RNA concentration and associates it with the original samples.

Precursor to RNA_Prep
### Inputs


- **Input Array** [IS] (Array) 
  - <a href='#' onclick='easy_select("Sample Types", "RNA Sample")'>RNA Sample</a> / <a href='#' onclick='easy_select("Containers", "Total RNA 96 Well Plate")'>Total RNA 96 Well Plate</a>





### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# Cannon Mallory
# UW-BIOFAB
# 03/04/2019
# malloc3@uw.edu

needs 'Standard Libs/Debug'
needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/Units'
needs 'Standard Libs/UploadHelper'
needs 'Standard Libs/ItemActions'
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

# RNA QC
class Protocol
  include CollectionActions
  include CollectionDisplay
  include CollectionTransfer
  include CommonInputOutputNames
  include Debug
  include CollectionLocation
  include Units
  include UploadHelper
  include WorkflowValidation
  include DataHelper
  include MiscMethods
  include TakeMeasurements
  include ParseCSV
  include KeywordLib
  include ItemActions

  TRANSFER_VOL = 20 # volume of sample to be transferred in ul
  PLATE_HEADERS = ['Plate',	'Repeat',	'End time',
                   'Start temp.',	'End temp.',	'BarCode'].freeze
  PLATE_LOCATION = 'TBD Location of file'.freeze

  BIO_HEADERS = ['Well', 'Sample ID',	'Conc. (ng/ul)',
                 'RQN',	'28S/18S'].freeze
  BIO_LOCATION = 'TBD Location of file'.freeze

  RIN_MIN = 3
  RIN_MAX = 10

  CONC_MIN = 8
  CONC_MAX = 100
  UP_MARG = 500
  LOW_MARG = 5

  def main
    return true if validate_inputs(operations)

    working_plate = setup_job(operations, TRANSFER_VOL, qc_step: true)

    trash_object([working_plate])

    setup_and_take_plate_reader_measurements(working_plate, PLATE_HEADERS,
                                             PLATE_LOCATION)

    setup_ad_take_bioanalizer_measurements(working_plate, BIO_HEADERS,
                                           BIO_LOCATION, RIN_KEY, 0, 3)

    rin_info = generate_data_range(key: RIN_KEY, minimum: RIN_MIN,
                                   maximum: RIN_MAX)

    conc_info = generate_data_range(key: CON_KEY, minimum: CONC_MIN,
                                    maximum: CONC_MAX, lower_margin: LOW_MARG,
                                    upper_margin: UP_MARG)

    asses_qc_values(working_plate, [rin_info, conc_info])

    show_key_associated_data(working_plate, [QC_STATUS, CON_KEY, RIN_KEY])

    # TODO: For some reason it will not overwrite the old association...
    associate_data_back_to_input(working_plate, [QC_STATUS, CON_KEY, RIN_KEY],
                                 operations)

    trash_object([working_plate])

    downstream_op_type = 'RNA Prep'
    return if stop_qc_failed_operations(operations, downstream_op_type)
  end
end

```
