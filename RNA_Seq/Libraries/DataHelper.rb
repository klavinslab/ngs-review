

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


  # TODO
  # Gets the dilution factors used in the plate reader measurements
  # Need some guidance on how this is determined.  I expect that this is somthing
  # that can automatically be generated within aquarium.  But also may require
  # some user input?   For now leave it open for change
  #
  # @return dilution_factor_map [Array<r,c,x>] a map of dilution factors and location
  def get_dilution_factors(working_plate)
    show do 
      title "Dilution Factor"
      note "Need to determin how this is decided.  For now dilution is assumed to be
        100."
      note "A user input may be needed or further understanding and control of,
              the transfer step may be required..."
    end
    generate_100_dilution_factor_map(working_plate)
  end


  # Instructions for taking the QC Plate Reader measurements
  # 
  #
  # @param working_plate [Collection] the plate of samples needing measurements
  # @return parseable csv file map of fluorescense values
  def take_duke_plate_reader_measurement(working_plate, csv_headers, csv_location)
    standards = get_standards

    show do
      title "Load Plate #{working_plate.id} on Plate Reader"
      note 'Load plate on plate reader and take measurements'
      note 'Save output data as CSV and upload on next page'
    end

    csv_uploads = get_validated_uploads(working_plate.parts.length,
      csv_headers, false, file_location: csv_location)

    csv, plate_reader_info = pre_parse_plate_reader_data(csv_uploads)

    associate_data(working_plate, PLATE_READER_DATA_KEY, plate_reader_info)
    [csv.drop(6), standards]
  end


  # Instructions for taking Duke Bioanalyzer measurements 
  # 
  #
  # @param working_plate [Collection] the plate of samples needing measurements
  # @return parseable csv file map of fluorescense values
  def take_bioanalizer_measurement(working_plate, csv_headers, csv_location, measurement_type: nil)
    if measurement_type == 'library'
      description = 'Library DNA'
    elsif measurement_type == 'rna'
      description = 'RNA'
    else
      description = ''
    end
    
    show do
      title "Load Plate #{working_plate.id} onto the Bioanalyzer"
      note "Load plate onto the Bioanalyzer and take <b>#{description}</b> measurements"
      note 'Save output data as CSV and upload on next page'
    end

    csv_uploads = get_validated_uploads(working_plate.parts.length,
      csv_headers, false, file_location: csv_location)

    upload = csv_uploads.first
    csv = CSV.read(open(upload.url))

    associate_data(working_plate, BIOANALYZER_KEY, csv)
    csv
  end

  # Parses a csv for data assuming headers fit certain format
  #  Header 1    Header 2    Header 3
  #    loc         data      data
  #    loc         data       data
  # 
  # @param csv [CSV] the csv file
  # @param data_header [String] the string name of the header containg the inforamtion of interest
  # @param alpha_num_header [String] optional the name of the header containg the 
  #               alpha numerical well location
  def parse_csv_for_data(csv, data_header:, alpha_num_header:)
    data_idx = csv.first.index(data_header)
    loc_idx = csv.first.index(alpha_num_header)
    data_map = []
    csv.drop(1).each do |row|
      alpha_loc = row[loc_idx]
      data = row[data_idx]
      rc_loc = convert_alpha_to_rc(alpha_loc)
      data_map.push(rc_loc.push(data))
    end
    data_map
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
        get "number", var: "stan_1", label: "Concentration 1 (ng/ul)", default: ""
        get "number", var: "flo_1", label: "Fluorescence 1", default: ""
        separator
        get "number", var: "stan_2", label: "Concentrationn 2 (ng/ul)", default: ""
        get "number", var: "flo_2", label: "Fluorescence 2", default: ""
      end
      # This is because in this case  the lower concentration should always be first
      # else slope will be negative.   Rather do it here than in the slope calculation
      # because the slope calulation may be used other places and thus needs to be able
      # to report a neg slope.
      if response[:stan_1] > response[:stan_2]
        point_two = [response[:flo_1], response[:stan_1]]
        point_one = [response[:flo_2], response[:stan_2]]
      else
        point_one = [response[:flo_1], response[:stan_1]]
        point_two = [response[:flo_2], response[:stan_2]]
      end
      
      return [point_one, point_two] unless point_two.include?("") || point_one.include?("")

      raise "Too many attempts to input Plate Reader Standards information" if laps > tries - 1
      show do 
        title "Plate Reader Standards not Entered Properly"
        warning "Please input valid Standard Values"
        note "Hit okay to try again" 
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


  # Calculates the slope and intercept between two points
  #
  # @param point_one [Array<x,y>] the x,y coordinates of point one
  # @param point_two [Array<x,y>] the x,y coordinates of point two 
  def calculate_slope_intercept(point_one: standards[0], point_two: standards[1])
    x_1 = point_one[0]
    y_1 = point_one[1]
    x_2 = point_two[0]
    y_2 = point_two[1]
    
    slope = (y_2 - y_1).to_f/(x_2 - x_1)
    intercept = y_1 - (slope * x_1)
    [slope, intercept]
  end

  
  
  # Generates a standard dilution factor map.  Assumes that there was no dilution.
  #
  # @param working_plate [Collection] the collection that the map is being generated for
  # @return dilution_factor_map [Array<r,c,dilution_factor>] map of dilutions
  def generate_100_dilution_factor_map(working_plate)
    parts = working_plate.parts
    dilution_factor_map = []
    parts.each do |part|
      loc = working_plate.find(part).first
      loc.push(100)
      dilution_factor_map.push(loc)
    end
    dilution_factor_map
  end



  # calculates the concentrations of the samples from the slope, intercept, dilution factor
  # and the plate reader information.
  #
  # @param slope [Float] the slope of the calibration curve
  # @param intercept [Float] the intercept of the calibration curve
  # @param plate_csv [CSV] csv file partially parsed with plate reader values
  # @param dilution_map [Array<Array<r,c, dilution factor>>] the dilution factor map
  # @param concentration_map [Array<Array<r,c, concentration>>] map of concentrations
  def calculate_concentrations(slope:, intercept:, plate_csv:, dilution_map:)
    concentration_map = []
    dilution_map.each do |row, column, dilution|
      fluorescence = plate_csv[row][column].to_f
      concentration = ((fluorescence * slope + intercept)*dilution/1000).round(1)
      concentration_map.push([row,column,concentration])
    end
    concentration_map
  end
end