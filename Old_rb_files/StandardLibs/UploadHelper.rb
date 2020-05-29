# helper function for uploading files
# note: data associations should be handled externally
module UploadHelper

  require 'csv'
  require 'open-uri'

  CSV_KEY = 'upload_csv'.freeze
  REAL_CHARACTERS = ('!'...'~').to_a

  # @param dirname - directory or full path including filename
  # @param exp_upload_num - expected number of files to upload
  # @param tries - max. number of attempts to upload expectedNum files
  #
  # @returns array of Upload items
  #
  # EXAMPLES of how to associate correctly:
  # data associations - 1st gel image
  # up_bef=ups[0]
  # op.plan.associate 'gel_image_bef', 'combined gel fragment', up_bef  # upload association, link
  # op.input(INPUT).item.associate 'gel_image_bef', up_bef              # regular association
  # op.output(OUTPUT).item.associate 'gel_image_bef', up_bef            # regular association
  #------------------------------------------
  def upload_data(dirname, exp_upload_num, tries)
    uploads = {} # result of upload block
    number_of_uploads = 0 # number of uploads in current attempt
    attempt = 0 # number of upload attempts

    loop do
      # if(number_of_uploads==exp_upload_num)
      # show {note 'Upload complete.'}
      # end
      break if (attempt >= tries) || (number_of_uploads == exp_upload_num)

      attempt += 1

      uploads = show do
        title "Select <b>#{exp_upload_num}</b> file(s)"
        note "File(s) location is: #{dirname}"
        if attempt > 1
          warning "Number of uploaded files (#{number_of_uploads}) was incorrect, please try again! (Attempt #{attempt} of #{tries})"
          note "Please hit <b>Okay</b> to try again"
        end
        upload var: 'files'
      end
      # number of uploads
      if !uploads[:files].nil?
        number_of_uploads = uploads[:files].length
      end
    end

    if number_of_uploads != exp_upload_num
      show {note "Final number of uploads (#{number_of_uploads}) not equal to expected number #{exp_upload_num}! Please check."}
      return nil
    end

    # format uploads before returning
    ups = [] # upload hashes
    if !uploads[:files].nil?
      uploads[:files].each_with_index do |upload_hash, ii|
        up = Upload.find(upload_hash[:id])
        ups[ii] = up
      end
    end
    ups
  end

  # Opens .csv file using its url and stores it line by line in a matrix
  #
  # @param upload [upload_obj] the file that you wish to read from
  # @return matrix [2D-Array] built from the csv
  def read_url(upload)
    url = upload.url
    matrix = []
    CSV.new(open(url)).each { |line| matrix.push(line) }
  end

  # Validates upload and ensures that it is correct
  #
  # @param upload_array Array array of  uploads
  # @param expected_num_inputs int the expected number of inputs
  # @param csv_headers array array of expected headers
  # @returns pass Boolean pass or fail (true is pass)
  def validate_upload(uploaded_files:, min_length: 0,
                      headers:, multiple_files: true)
    if uploaded_files.nil?
      show do
        title 'No File Attached'
        warning 'No File Was Attached'
        note 'Please hit <b>Okay</b> to try again'
      end
      return false
    end

    fail_message = ''

    # TODO: this makes no sense....should expect more than one file sometimes...
    if multiple_files == false
      if uploaded_files.length > 1
        fail_message += 'More than one file was uploaded, '
      end
      upload = uploaded_files.first
    end

    csv = CSV.read(open(upload.url))

    if csv.length - 1 < min_length
      fail_message += 'CSV length is shorter than expected, '
    end

    # TODO: Make this more robust. Sometimes CSV files contain unprintable
    # characters and mess everything up.
    first_row = csv.first
    first_row[0][0] = '' unless REAL_CHARACTERS.include?(first_row[0][0].upcase)

    headers.each do |header|
      unless first_row.include?(header)
        fail_message += "<b>#{header}</b> Header either does not exist or is in
                         wrong format, "
      end
    end

    return true unless fail_message.length.positive

    show do
      title 'Warning Uploaded CSV does not fit correct format'
      note fail_message.to_s
      note 'Please hit <b>Okay</b> to try again'
    end
    false
  end

  # Asks for tech to upload files and validates files
  # based on headers information
  #
  # @expected_data_points
  def get_validated_uploads(min_length:,
                            headers:, multi_files: false,
                            file_location: 'Unknown Location',
                            detailed_instructions: nil)
    tries = 1
    max_tries = 10
    pass = false
    until pass == true
      csv_uploads = upload_csv(tries: tries, max_tries: max_tries,
                               file_location: file_location, 
                               detailed_instructions: detailed_instructions)

      pass = validate_upload(uploaded_files: csv_uploads,
                             min_length: min_length,
                             headers: headers,
                             multiple_files: multi_files)
      tries += 1
      raise 'Too many failed upload attempts' if tries == max_tries && !pass
    end
    csv_uploads
  end

  # Instructions to upload CSV files of concentrations
  def upload_csv(tries: '', max_tries: '', file_location: 'Unknown Location',
                 detailed_instructions: nil)
    up_csv = show do
      title "Upload CSV (attempts: #{tries}/#{max_tries})"
      note "Please upload a <b>CSV</b> file located at #{file_location}"
      note detailed_instructions.to_s unless detailed_instructions.nil?
      upload var: CSV_KEY.to_sym
    end
    up_csv.get_response(CSV_KEY.to_sym)
  end
end
