# Cannon Mallory
# UW-BIOFAB
# 03/04/2019
# malloc3@uw.edu

# I moved this description to the protocol documentation page 
# Note todos with TODO
# TODO: Currently build plate needs a bit of work.  It works by order of input array and not by order of sample location on plate

needs "Standard Libs/Debug"
needs "Standard Libs/CommonInputOutputNames"
needs "Standard Libs/Units"
needs "Collection_Management/CollectionDisplay"
needs "Collection_Management/CollectionTransfer"
needs "Collection_Management/CollectionActions"
needs "Collection_Management/SampleManagement"
needs "RNA_Seq/WorkflowValidation"
needs "RNA_Seq/KeywordLib"

# Ruby style, put each include on its own line -- I alphabatize them but that's just Amy Cash style
class Protocol
  include CollectionActions
  include CollectionDisplay
  include CollectionTransfer
  include CommonInputOutputNames
  include Debug
  include KeywordLib
  include SampleManagement
  include WorkflowValidation 

  TRANSFER_VOL = 20   #volume of sample to be transfered in ul

  def main
    validate_inputs(operations)
    
    working_plate = make_new_plate(C_TYPE) # in collection actions library, return instance of class collection
    # Rename C_TYPE -- we have a protocol called C_DNA, so it's confusing. 
    # The name should reveal something about what it's for and I'm not sure what C is in this context?
    operations.retrieve

    operations.each do |op|
      input_fv_array = op.input_array(INPUT_ARRAY)
     # Same as before, not sure why initial samples are an array? I think I'm missing something 
      # Also, spell out field value 
      add_fv_array_samples_to_collection(input_fv_array, working_plate)
      # Transfer what? 
      transfer_from_array_collections(input_fv_array, working_plate, TRANSFER_VOL)
    end
    
    store_input_collections(operations)
    take_qc_measurements(working_plate)
    trash_object(working_plate)

  end


  # Instruction on taking the QC measurements themselves.
  # Currently not operational but associates random concentrations for testing
  #
  # TODO complete this and make it actually look at CSV Files
  def take_qc_measurments(working_plate)
    input_rcx = []
    operations.each do |op|
      input_array = op.input_array(INPUT_ARRAY)
      input_items = input_array.map{|fv| fv.item}
      arry_sample = input_array.map{|fv| fv.sample}
      input_items.each_with_index do |item, idx|
        item.associate(CON_KEY, rand(50..100))
        sample = arry_sample[idx]
        working_plate_loc_array = working_plate.find(sample)
        working_plate_loc_array.each do |sub_array|
          sub_array.push("#{item.get(CON_KEY)}")
          input_rcx.push(sub_array)
        end
      end
    end
# Single Quotes preferred unless you're using string interpolation 
    show do
      title 'Perform QC Measurements'
      note 'Please Attach excel files'
      note 'For testing purposes each sample will be given a random concentration from 50 to 100 ng/ul'
      note 'This will eventually come from a CSV file'
      table highlight_rcx(working_plate, input_rcx)
    end
  end
end
