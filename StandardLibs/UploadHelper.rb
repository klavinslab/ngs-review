# frozen_string_literal: true

# helper function for uploading files
# note: data associations should be handled externally
module UploadHelper

  require 'csv'
  require 'open-uri'

  CSV_KEY = 'upload_csv'

  #
  # @param dirname - directory where files are located, or full path including filename
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

  # Opens .csv file upload item using its url and stores it line by line in a matrix
  #
  # @param upload [upload_obj] the file that you wish to read from
  # @return matrix [2D-Array] is the array of arrays of the rows read from file, if csv
  def read_url(upload)
    url = upload.url
    matrix = []
    CSV.new(open(url)).each { |line| matrix.push(line) }
    # open(url).each { |line| matrix.push(line.split(',') }
  end

  # Validates upload and ensures that it is correct
  #
  # @param uplaod_array Array array of  uploads
  # @param expected_num_inputs int the expected number of inputs
  # @param csv_headers array array of expected headers
  # @returns pass Boolean pass or fail (true is pass)
  def validate_upload(upload_array, expected_num_inputs, csv_headers, multiple_files: true)
    if upload_array.nil?
      show do
        title 'No File Attached'
        warning 'No File Was Attached'
      end
      return false
    end

    fail_message = ''

    if multiple_files == false
      fail_message += 'More than one file was uploaded, ' if upload_array.length > 1
      upload = upload_array.first
    end

    csv = CSV.read(open(upload.url))
    fail_message += 'CSV length is shorter
        than expected, ' if csv.length - 1 < expected_num_inputs

    first_row = csv.first
    # Should remove leading blank space from CSV
    first_row[0][0] = ''

    csv_headers.each do |header|
      fail_message += "<b>#{header} Header</b> either does not exist or
        is in wrong format, " if !first_row.include?(header)
    end

    if fail_message.length > 0
      show do
        title 'Warning Uploaded CSV does not fit correct format'
        note "#{fail_message}"
      end
      return false
    else
      return true
    end
  end

  # Needs documentation
  def get_validated_uploads(expected_data_points, headers, multi_files, file_location: 'Unknown Location')
    tries = 1
    max_tries = 10
    pass = false
    until pass == true
      csv_uploads = upload_csv(tries, max_tries, file_location: file_location)
      pass = validate_upload(csv_uploads, expected_data_points, headers, multi_files)
      tries += 1
      raise 'Too many failed upload attempts' if tries == max_tries && !pass
    end
    csv_uploads
  end

  # Instructions to upload CSV files of concentrations
  def upload_csv(tries = nil, max_tries = 'NA', file_location: 'Unknown Location')
    up_csv = show do
      title "Upload CSV (attempts: #{tries}/#{max_tries})"
      note "Please upload a <b>CSV</b> file located at #{file_location}"
      upload var: CSV_KEY.to_sym
    end
    up_csv.get_response(CSV_KEY.to_sym)
  end
end
