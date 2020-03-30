#Cannon Mallory
#malloc3@uw.edu
#
#This protocol is goes through determining what oligo adapters to use.
#This information is uploaded through a CSV and a plate design is created.
#The plate is then created and components are transfered to an intermidiate plate to be used later



needs "Standard Libs/Debug"
needs "Standard Libs/CommonInputOutputNames"
needs "Standard Libs/Units"

needs "Collection_Management/CollectionDisplay"
needs "Collection_Management/CollectionTransfer"
needs "Collection_Management/CollectionActions"
needs "Collection_Management/SampleManagement"
needs "RNA_Seq/KeywordLib"
needs "RNA_Seq/CsvDebugLib"

require 'csv'


class Protocol
  include Debug, CollectionDisplay, CollectionTransfer, SampleManagement, CollectionActions
  inclde CommonInputOutputNames, KeywordLib, CsvDebugLib

  PLATE_ID = "Plate ID"
  WELL_LOCATION = "Well Location"
  TRANSFER_VOL = 20


  def main

    #get the what sample to use
    upload_and_associate_csv

    #find all these parts
    col_parts_hash = sample_from_csv

    working_plate = make_new_plate(C_TYPE)

    col_parts_hash.each do |collection, parts|
      show do
        title "Collkectiuon and parts"
        note "collection id: #{collection.id}"
        parts.each do |part|
          note "Part ID: #{part.id}"
        end
      end
      transfer_to_working_plate(collection, working_plate, arry_sample = parts, TRANSFER_VOL)

    end




    #Assign this plate to the outputs of each operation (they are the same plate)
    # and should be associated with the output object
    #
    #This protocol makes the plate but they plate also has to coordinate with the proper jobs...
    #This is where batching really happens....  Right?  Theotically that would go together pretty
    #easily but must think on this a bit.  A good thing to talk with amy about.
    #
    #Maybe the solve is in the other plan if there is a mismatch in matrix demensions of the
    #RNA plate and the ligase adapter plate we could either error or provide a warning.
    #e.g. "The Ligase adapter plate has more samples than the RNA Plate.  Do you want to continue?"
    # or "The Ligase adapter plate does not have enough samples for the RNA plate.  This job is errored"
    #
    #
    #
    #transfer items properly to plate

  end



  #Gets CSV upload and associates each CSV file with the operation in question
  def upload_and_associate_csv
    operations.each do |op|
      up_csv = show do
        title "Upload CSV file of Adapters"
        note "Please upload a <b>CSV</B> file of all required adapters"
        note "Row 1 is Reserved for headers"
        note "Column 1: '#{PLATE_ID}'"
        note "Column 2: '#{WELL_LOCATION}' (e.g. A1, B1)"
        upload var: CSV_KEY.to_sym
      end
      if debug
        op.associate(CSV_KEY.to_sym, CSV_DEBUG)
      else
        op.associate(CSV_KEY.to_sym, up_csv.get_response(CSV_KEY.to_sym))
      end
    end
  end


  #Parses CSV and returns an array of all the samples required
  #returns hash[key: collection, array[parts]]
  def sample_from_csv
    parts = []
    operations.each do |op|
      csv = CSV.parse(op.get(CSV_KEY.to_sym))

      csv.each_with_index do |row, idx|
        if idx == 0
          plate_id = row[0]
          well_location = row[1]
          raise "Headers incorrect" if plate_id != PLATE_ID || well_location != WELL_LOCATION
        else
        collection = Collection.find(row[0])
        part = part_alpha_num(collection, row[1])
        parts.push(part)
        end
      end
    end
    return parts.group_by{|part| part.containing_collection}
  end

end