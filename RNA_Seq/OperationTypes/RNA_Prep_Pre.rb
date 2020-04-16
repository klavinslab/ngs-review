# frozen_string_literal: true

# This precondition checks that all inputs into the operation have valid concentrations and are ready to be used.
# Parts are copied from the WorkflowValidation Lib see note below for explination

def precondition(_op)
  range = (50...100)
  _op = Operation.find(_op.id)
  valid_conc?(_op, range)
end

# Copied from "RNA_Seq/WorkflowValidation"
#
# Struggled to find a viable way to import libraries into Preconditions.  Decided I would come
# back to this issue later but for now just copy code.
#
# Validates if all the input concentrations in the input array are within the given range
#
# @param op [Operation] operation in question
# @param range [Range] acceptable numerical range of concentration
def valid_conc?(op, range)
  op.input_array('Input Array').each do |field_value|
    conc = field_value.part.get('Stock Conc (ng/ul)'.to_sym)
    return false unless range.cover?(conc)
  end
  true
end
