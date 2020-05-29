Library.find_by(name:'WorkflowValidation').source.load #(binding: binding)

def precondition(_op)
    range = (50...100)
    _op = Operation.find(_op.id)
    _op.associate("Pass".to_sym, 'started here')
    _op.associate("Passsss".to_sym, 'why not here')
    return true
end