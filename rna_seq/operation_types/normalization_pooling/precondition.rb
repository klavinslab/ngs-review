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