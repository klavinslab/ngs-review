

needs 'Standard Libs/CommonInputOutputNames'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/Units'
needs 'Standard Libs/UploadHelper'
needs 'Collection_Management/CollectionDisplay'
needs 'Collection_Management/CollectionTransfer'
needs 'Collection_Management/CollectionActions'
needs 'Collection_Management/CollectionLocation'
needs 'RNA_Seq/WorkflowValidation'
needs 'RNA_Seq/KeywordLib'
    
module DataHelper    
  include CollectionActions
  include CollectionDisplay
  include CollectionTransfer
  include CommonInputOutputNames
  include KeywordLib
  include CollectionLocation
  include Units
  include UploadHelper
  include WorkflowValidation
  include AssociationManagement

  PLATE_READER_DATA_KEY = "Plate Reader Data"


  # Instructions for taking the QC measurements
  # Currently not operational but associates random concentrations for testing
  # This only works for the csv format at duke genome center
  #
  # @param working_plate [Collection] the plate of samples needing measurements
  # @return parseable csv file map of fluorescense values
  def take_duke_plate_reader_measurement(working_plate, csv_headers, csv_location)
    standards = get_standards

    show do
      title "Load Plate #{working_plate.id} on Plate Reader"
      note 'Load plate on plate reader and take concentration measurements'
      note 'Save output data as CSV and upload on next page'
    end

    csv_uploads = get_validated_uploads(working_plate.parts.length,
      csv_headers, false, file_location: csv_location)

    csv, plate_reader_info = pre_parse_plate_reader_data(csv_uploads)

    associate_data(working_plate, PLATE_READER_DATA_KEY, plate_reader_infop)
    [csv.drop(6), standards]
  end

  # Gets the standards used and information about them from technition
  #
  # @param tries [Int] optional the number of tries the tech gets
  #   to input standard information
  # @return []  the standards used in plate reader measurement
  def get_standards(tries: 10)
    fluorescence = []
    standard = []

    tries.times do |laps|
      # TODO make this a table and not just a bunch of inputs
      response = show do
        title "Plate Reader Standards"
        note 'Please record the standards used and their fluorescence below'
        get "number", var: "stan_1", label: "Standard 1", default: ""
        get "number", var: "flo_1", label: "fluorescence 1", default: ""
        get "number", var: "stan_2", label: "Standard 2", default: ""
        get "number", var: "flo_2", label: "fluorescence 2", default: ""
      end
      fluorescence = [response[:flo_1], response[:flo_2]]
      standard = [response[:stan_1], response[:stan_2]]
      
      return [standard, fluorescence] unless fluorescence.include?("")|| standard.include?("")

      raise "Too many attempts to input Plate Reader Standards information" if laps > 9
      show do 
        title "Plate Reader Standards not entered properly"
        warning "Please put valid standards information" 
      end
    end
  end


  # Does initial formatting and parseing of csv files
  #
  # @param csv_uploads [Upload] raw uploaded csv files
  # @return [Array<csv, Hash>] retunrs an array containg the semi parse csv
  #    and a hash of general plate reader run info.
  def pre_parse_plate_reader_data(csv_uploads)
    upload = csv_uploads.first
    csv = CSV.read(open(upload.url))
    plate_reader_info = {
      'repeats' => csv[1][1],
      'end_time' => csv[1][2],
      'start_temp'  => csv[1][3],
      'end_temp' => csv[1][4],
      'bar_code' => csv[1][5]
      }
    [csv, plate_reader_info]
  end
    
    
end