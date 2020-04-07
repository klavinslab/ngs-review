#TODO send only failed ops to error and all other ops send to pending??

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
    operations.first.associate("Pass".to_sym, 'got inside')
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



  #TODO send only failed ops to error and all other ops send to pending
  #
  # Displays all errored operations and items that failed QC
  # Walks through all validation failes.  Then errors whole job
  #
  # @param failed_ops [Hash] Key: Operation ID, Value: Array[Items]
  def show_errored_operations(failed_ops)
    show do 
      title "Some Operations have failed QC"
      note "#{failed_ops.length} Operations have Items that failed QC"
      note "The next few pages will show which Operations and Items
              are at fault"
      warning "This job will then be canceled"
    end
    failed_ops.each do |op, errored_items|
      show do
        title "Failed Operation and Items"
        note "Operation #{op.id} from Plan #{op.plan.id}"
        errored_items.each do |item|
          note "Item #{item.id}"
        end
      end
    end

    #TODO send only failed ops to error and all other ops send to pending
    raise "Some item in this job failed to pass QC.  Please Reference previous pages
            for details."
  end




  # validate concentrations of items in the RNA_Prep protocol
  #
  # @params operations [OperationList] list of operations
  # @param range [Range] the range that the concentrations must be in ng/ul
  def validate_concentrations(operations, range)
    failed_ops = get_invalid_operations(operations, range)
    show_errored_operations(failed_ops) unless failed_ops.empty?
  end




  # Validates the concentration of raw samples and ensures that they are within
  # range
  #
  # @param operations [OperationList] list of operationlist
  # @param range [Range] acceptable numerical range of concentration
  def get_invalid_operations(operations, range)
    failed_ops = Hash.new
    operations.each do |op|
      failed_samples = get_invalid_concentrations(op, range)
      failed_ops[op] = failed_samples unless failed_samples.empty?
    end
    failed_ops
  end




  # Validates if all the input concentrations in the input array are within the given range
  #
  # @param op [Operation] operation in question
  # @param range [Range] acceptable numerical range of concentration
  def get_invalid_concentrations(op, range)
    failed_samples = []
    op.input_array(INPUT_ARRAY).each do |field_value|
      conc = field_value.part.get(CON_KEY.to_sym)
      failed_samples.push(field_value.part) unless range.cover?(conc)
    end
    failed_samples
  end





  # validates that all items have passed cDNA QC
  #
  # @params operations [OperationList] list of operations
  def validate_cdna_qc(operations)
    failed_ops = get_failed_cdna_ops(operations)
    show_errored_operations(failed_ops) unless failed_ops.empty?
  end




  # Validates the that the cDNA qc step was performed and all inputs passed
  # 
  # @param operations [OperationList] operation list used
  def get_failed_cdna_ops(operations)
    failed_ops = Hash.new
    operations.each do |op|
      failed_samples = get_failed_cdna(op, range)
      failed_ops[op] = failed_samples unless failed_samples.empty?
    end
    failed_ops
  end



  # validates that all input items have passed cdna qc
  # returns any items that did not pass QC
  # 
  # @param op [Operation] operation in question
  # @return failed_samples [Array] array of failed samples
  def get_failed_cdna(op)
    failed_samples = []
    op.input_array(INPUT_ARRAY).each do |field_value|
      failed_samples.push(field_value.part) unless field_value.item.get(QC2_KEY) == "Pass"
    end
    failed_samples
  end
end
