# Cannon Mallory
# malloc3@uw.edu
#
# Module that validates workflow parameters at run time
needs "Standard Libs/CommonInputOutputNames"
needs "RNA_Seq/KeywordLib"

module WorkflowValidation
  include CommonInputOutputNames
  include KeywordLib

  # This is the Yard Doc Style -> More info here: https://rubydoc.info/gems/yard
  # Validates that total inputs (from all operations) are within the acceptable range
  #
  # @raise error if sample id is included twice
  # @raise error if there are more than 96 samples
  # @raise error if the number of inputs does not match the number of outputs
  # @raise error if there are no samples
  # @param operations [operationlist] list of all operations in the job
  # @param inputs_match_outputs [boolean] check if number of inputs matches number of outputs
  def validate_inputs(operations, inputs_match_outputs: false) # Keyword Arguments preferred to defaults
    total_inputs = []
    total_outputs = []
    operations.each do |op|
      total_inputs += op.input_array(INPUT_ARRAY).map!{|fv| fv.sample} # x += thing preferred to x = x + thing
     total_outputs += op.output_array(OUTPUT_ARRAY).map!{|fv| fv.sample}
    end
    # Confused about the set up -- each sample will be an op, or one operation will work with multiple samples?
    # If each sample is an individual, where is the array? Why is the variable "input array".
    # Spell out Field Value in variables -- makes it easier if someone wants to look up method in the API
    # TODO for myself -- come back to this later
    a = total_inputs.detect{ |sample| total_inputs.count(sample) > 1}
    raise "Sample #{a.id} has been included multiple times in this job" if a != nil
    raise 'The number of Input Samples and Output
            Samples do not match' if total_inputs.length != total_outputs.length && inputs_match_outputs
    raise 'Too many samples for this job. Please re-lauch job with fewer samples' if total_inputs.length > MAX_INPUTS
    raise 'There are no samples for this job.'  if total_inputs.length <= 0
  end

  # Validates the concentration of raw samples and ensures that they are within
  # range
  #
  # @raise error if outside range
  # @param operations [OperationList] list of operationlist
  # @param range [Range] numerical range of the item
  def validate_concentrations(operations, range)
    operations.each do |op|
      op.input_array(INPUT_ARRAY).each do |field_value|
        conc = field_value.part.get(CON_KEY)
        raise "Sample #{field_value.sample.id} doesn't have a valid
            concentration for this operation" unless range.cover? conc
      end
    end
  end

  def validate_cdna_qc(operations)
    operations.each do |op|
      op.input_array(INPUT_ARRAY).each do |field_value|
        qc = field_value.item.get(QC2_KEY)
        raise "Item #{field_value.item.id} doesn't have a valid
                C-DNA QC" unless qc == "Pass"
      end
    end
  end
end
