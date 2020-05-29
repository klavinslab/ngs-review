# Normalization Pooling

#This protocol is for total Normalization Pooling of cDNA.  It Will take in a batch of samples, replate these
#samples together onto a 96 well plate that will then go through a normalization steps.

This must be run after RNA QC, RNA Prep, and cDNA QC
### Inputs


- **Input Array** [IA] (Array) 
  - <a href='#' onclick='easy_select("Sample Types", "RNA Sample")'>RNA Sample</a> / <a href='#' onclick='easy_select("Containers", "96 Well Sample Plate")'>96 Well Sample Plate</a>



### Outputs


- **Output Array** [IA] (Array) 
  - <a href='#' onclick='easy_select("Sample Types", "RNA Sample")'>RNA Sample</a> / <a href='#' onclick='easy_select("Containers", "96 Well Sample Plate")'>96 Well Sample Plate</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
#This precondition checks that all inputs into the operation have valid concentrations and are ready to be used.
#Parts are copied from the WorkflowValidation Lib see note below for explination

def precondition(_op)
  #pass = true
  #_op = Operation.find(_op.id)
  #_op.input_array("Input Array").each do |field_value|
  #  qc = field_value.item.get("cDNA QC")
  #  pass = false unless qc == "Pass"
  #end
  #_op.associate("Pass".to_sym, pass)
  #true if pass
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

# Normalization Pooling
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

  TRANSFER_VOL = 20 # volume of sample to be transferred in ul

  def main
    return if validate_inputs(operations, inputs_match_outputs: true)
    return if validate_qc(operations)

    working_plate = setup_job(operations, TRANSFER_VOL, qc_step: false)

    normalization_pooling(working_plate)
    store_output_collections(operations, location: 'Freezer')
  end

  # Instructions for performing RNA_PREP
  #
  # @param working_plate [Collection] the plate with samples
  def normalization_pooling(working_plate)
    show do
      title 'Do the Normalization Pooling Steps'
      note "Run Normalization Pooling protocol with plate #{working_plate.id}"
      table highlight_non_empty(working_plate, check: false)
    end
  end
end

```
