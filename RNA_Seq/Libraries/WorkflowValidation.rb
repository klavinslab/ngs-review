#Cannon Mallory
#malloc3@uw.edu
#
#This includes all moduels that validate workflow parameters at run time
needs "Standard Libs/CommonInputOutputNames"
needs "RNA_Seq/KeywordLib"

module WorkflowValidation
  include CommonInputOutputNames, KeywordLib

  
  
  #Validates that total inputs (from all operations)
  #Ensures that all inputs doesnt exeed max inputs
  #
  # @operations OperationList list of all operations in the job
  # @inputs_match_outputs Boolean if the number of inputs should match the number of outputs set as true
  def validate_inputs(operations, inputs_match_outputs = false)
    total_inputs = []
    total_outputs = []
    operations.each do |op|
      total_inputs = total_inputs + op.input_array(INPUT_ARRAY).map!{|fv| fv.sample}
     total_outputs = total_outputs + op.output_array(OUTPUT_ARRAY).map!{|fv| fv.sample}
    end

    a = total_inputs.detect{ |sample| total_inputs.count(sample) > 1}
    raise "Sample #{a.id} has been included multiple times in this job" if a != nil
    raise "The number of Input Samples and Output 
            Samples do not match" if total_inputs.length != total_outputs.length && inputs_match_outputs
    raise "Too many samples for this job. Please re-lauch job with fewer samples" if total_inputs.length > MAX_INPUTS
    raise "There are no samples for this job."  if total_inputs.length <= 0
  end


  def validate_concentrations(operations, range)
    operations.each do |op|
      op.input_array(INPUT_ARRAY).each do |fv|
        conc = fv.item.get(CON_KEY)
        raise "Sample #{fv.sample.id} doesn't have a valid concentration for this operation"if !range.cover? conc
      end
    end
  end

  def validate_cdna_qc(operations)
    operations.each do |op|
      op.input_array(INPUT_ARRAY).each do |fv|
        qc = fv.item.get(QC2_KEY)
        raise "Item #{fv.item.id} doesn't have a valid C-DNA QC" if qc != "Pass"
      end
    end
  end
  
  
end 
