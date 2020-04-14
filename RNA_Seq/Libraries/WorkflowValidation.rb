# Cannon Mallory
# malloc3@uw.edu
#
# Module that validates workflow parameters at run time
needs 'Standard Libs/CommonInputOutputNames'
needs 'RNA_Seq/KeywordLib'

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
      total_inputs += op.input_array(INPUT_ARRAY).map! { |fv| fv.part }
      # x += thing preferred to x = x + thing
      total_outputs += op.output_array(OUTPUT_ARRAY).map! { |fv| fv.part }
    end

    # Confused about the set up -- each sample will be an op, or one operation will work with multiple samples?
    # If each sample is an individual, where is the array? Why is the variable "input array".
    # Spell out Field Value in variables -- makes it easier if someone wants to look up method in the API
    # TODO for myself -- come back to this later
    a = total_inputs.detect{ |item| total_inputs.count(item) > 1}
    raise "Item #{a.id} has been included multiple times in this job" if a != nil
    raise 'The number of Input Items and Output
            Items do not match' if total_inputs.length != total_outputs.length && inputs_match_outputs
    raise 'Too many Items for this job. Please re-lauch job with fewer Items' if total_inputs.length > MAX_INPUTS
    raise 'There are no Items for this job.' if total_inputs.length <= 0
  end

  # Displays all errored operations and items that failed QC
  # Walks through all validation fails.
  #
  # @param failed_ops [Hash] Key: Operation ID, Value: Array[Items]
  def show_errored_operations(failed_ops)
    show do 
      title "Some Operations have failed QC"
      note "<b>#{failed_ops.length}</b> Operations have Items that failed QC"
      note "The next few pages will show which Operations and Items
              are at fault"
    end

    failed_ops.each do |op, errored_items|
      show do
        title "Failed Operation and Items"
        note "Operation <b>#{op.id}</b> from Plan <b>#{op.plan.id}</b>"
        errored_items.each do |item|
          note "Item <b>#{item.id}</b>"
        end
      end
    end
  end

  # validate concentrations of items in the RNA_Prep protocol
  #
  # @params operations [OperationList] list of operations
  # @param range [Range] the range that the concentrations must be in ng/ul
  def validate_concentrations(operations, range)
    failed_ops = get_invalid_operations(operations, range)
    manage_failed_ops(operations, failed_ops)
  end

  # validates that all items have passed cDNA QC
  #
  # @params operations [OperationList] list of operations
  def validate_cdna_qc(operations)
    failed_ops = get_failed_cdna_ops(operations)
    manage_failed_ops(operations, failed_ops)
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


  # Validates the that the cDNA qc step was performed and all inputs passed
  # 
  # @param operations [OperationList] operation list used
  def get_failed_cdna_ops(operations)
    failed_ops = Hash.new
    operations.each do |op|
      failed_samples = get_failed_cdna(op)
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


  # Manages failed ops.  Coordinates what needs to happen with failed operations
  #
  # @param operations [OperationList] lis of operations
  # @param failed_ops [Hash] list of failed operations (OperationList okay too)
  def manage_failed_ops(operations, failed_ops)
    unless failed_ops.empty?

      #must remove all ops from the job that are in the same plan as the failed ops
      removed_ops = get_removed_ops(operations, failed_ops)

      #get the total number of items that were removed from the job
      num_items_removed = get_num_items(removed_ops) + get_num_items(failed_ops)

      #get total number of items originally in th job
      total_items = get_num_items(operations)

      #get the number of items still in the job
      num_items_left = total_items - num_items_removed
      
      if num_items_left == 0
        cancel_job = true
      else
        cancel_job = get_cancel_feedback(total_items, num_items_removed, num_items_left)
      end

      show_errored_operations(failed_ops)

      if cancel_job
        raise "This job was canceled because some items did not pass qc and the tech
                did not want to continue the job"
      else
        cancel_ops_and_pause_plans(operations, failed_ops, removed_ops)
      end
    end
  end


  # gets feed back from the technition on weather they want to continue with
  # the job or to cancel and re batch.
  #
  # @param total_items [Int] the total number of items in the job
  # @param num_failed [Int] number of failed items
  # @param num_left [Int] number of items left in job
  # @return cancel [Boolean] true if the job should be canceled
  def get_cancel_feedback(total_items, num_failed, num_left)
    cancel = nil
    10.times do 
      feedback_one = show do 
        title "Some Items in this Job failed QC"
        separator
        warning "Warning"
        separator
        note "<b>#{num_failed}</b> out of <b>#{total_items}</b> items were 
              removed from this job"
        note "Do you want to continue this job with the remaining <b>#{num_left}</b> items"
        select ["Yes", "No"], var: "continue".to_sym, label: "Continue?", default: 1
      end

      if feedback_one[:continue] == "No"
        feedback_two = show do
          title "Are You Sure?"
          note "Are you sure you want to cancel the whole job?"
          select ["Yes", "No"], var: "cancel".to_sym, label: "Cancel?", default: 1
        end
        if feedback_two[:cancel] == "Yes"
          return true
        end
      else
        return false
      end
    end
    raise "Job Canceled, answer was not consistant.  All Operations errored"
  end

  # get all the operations that may be in the same plan that should be removed
  # from the job but should not be canceled or errored.
  #
  # @param operations [OperationList] list of operations
  # @param failed_ops [Hash] hash of key op: value Array[Itmes]
  # @return removed_ops [Array] list of operationts that should be removed
  def get_removed_ops(operations, failed_ops)
    removed_ops = []
    failed_ops.each do |failed_op, errored_items|
      plan = failed_op.plan
      operations.each do |op|
        unless failed_ops.keys.include?(op) || removed_ops.include?(op) || op.plan != plan
          removed_ops.push(op)
        end
      end
    end
    removed_ops
  end



  # cancels all failed ops and removes from operations list
  # sets all like ops in same plans as failed ops to 'delayed'
  #
  # @param operations [OperationList] list of operations
  # @param failed_ops [Hash] list of failed operations
  # @param removed_ops [Array] list of ops that did not fail but need to be removed from plan
  def cancel_ops_and_pause_plans(operations, failed_ops, removed_ops)
    cancel_ops(operations, failed_ops)
    cancel_ops(operations, removed_ops)
    pause_like_ops(operations, failed_ops)
  end


  # 'delay' all like ops in plans that contained failed_ops
  #
  # @param operations [OperationList] list of operations
  # @param failed_ops [Hash] list of failed operations
  def pause_like_ops(operations, failed_ops)
    failed_ops.keys.each do |failed_op|
      plan = failed_op.plan
      like_ops = plan.operations.select{ |op| 
              op.operation_type.id == failed_op.operation_type.id}
      like_ops.each do |_op|
        unless _op == failed_op
          _op.set_status_recursively('delayed')
        end
      end
    end
  end

  # cancels all failed ops and removes them from operations list
  #
  # @param operations [OperationList] list of operations
  # @param remove_ops [Array] or [Hash] list of failed operations
  def cancel_ops(oeprations, remove_ops)

    if remove_ops.is_a?(Hash)
      remove_ops = remove_ops.keys
    end

    remove_ops.each do |op|
      op.set_status_recursively('delayed')
      operations.delete(op)
    end
  end

  # gets the number of input items in the input array of each op in list
  #
  # @param ops [Array] Operation List is acceptable of operations
  # @return nmum_items [Int] the number of input items (Hash is acceptable)
  def get_num_items(ops)

    if ops.is_a?(Hash)
      ops = ops.keys
    end

    num_items = 0
    ops.each do |op|
      num_items += op.input_array(INPUT_ARRAY).length
    end
    num_items
  end

end
