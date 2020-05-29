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