# frozen_string_literal: true

# Helper functions for uploading files
# Note: data associations should be handled externally
module UploadHelper

  require 'csv'
  require 'open-uri'

  CSV_KEY = 'upload_csv'

  # @param dirname [String] the directory where files are located, or
  # the full path including filename
  # @param expected_uploads [Integer] the number of files to upload
  # @param tries [Integer] the maximum number of attempts to upload
  # the files
  #
  # @returns [Array] the Upload items
  #
  # EXAMPLES of how to associate correctly:
  # data associations - 1st gel image
  # up_bef=ups[0]
  # op.plan.associate 'gel_image_bef', 'combined gel fragment', up_bef
  # upload association, link
  # op.input(INPUT).item.associate 'gel_image_bef', up_bef
  # regular association
  # op.output(OUTPUT).item.associate 'gel_image_bef', up_bef
  # regular association
  def upload_data(dirname, expected_uploads, tries)
    uploads = {} # result of upload block
    number_of_uploads = 0 # number of uploads in current attempt
    attempt = 0 # number of upload attempts

    loop do
      # if(number_of_uploads==expected_uploads)
      # show {note 'Upload complete.'}
      # end
      break if (attempt >= tries) || (number_of_uploads == expected_uploads)

      attempt += 1

      uploads = show do
        title "Select <b>#{expected_uploads}</b> file(s)"
        note "File(s) location is: #{dirname}"
        if attempt > 1
          warning "Number of uploaded files (#{number_of_uploads}) was incorrect, please try again! (Attempt #{attempt} of #{tries})"
        end
        upload var: 'files'
      end
      unless uploads[:files].nil?
        number_of_uploads = uploads[:files].length
      end
    end

    if number_of_uploads != expected_uploads
      show { note "Final number of uploads (#{number_of_uploads}) not equal to expected number #{expected_uploads}! Please check." }
      return nil
    end

    # format uploads before returning
    uploaded_hashes = []
    unless uploads[:files].nil?
      uploads[:files].each_with_index do |upload_hash, idx|
        uploaded_hashes[idx] = Upload.find(upload_hash[:id])
      end
    end
    ups
  end

  # Opens .csv file upload item using its url and stores it line by line in a matrix
  #
  # @param upload [upload_obj] the file that you wish to read from
  # @return matrix [Array] the 2D array of the rows read from file, if csv
  def read_url(upload)
    url = upload.url
    matrix = []
    CSV.new(open(url)).each { |line| matrix.push(line) }
    # open(url).each { |line| matrix.push(line.split(',') }
  end

  # Validates upload and ensures that it is correct
  #
  # @param uplaod_array [Array] array of uploads
  # @param expected_num_inputs [Integer] the expected number of inputs
  # @param csv_headers [Array] number of headers expected
  # @returns pass [Boolean]
  def validate_upload(upload_array, expected_num_inputs, csv_headers, multiple_files: true)
    if upload_array.nil?
      show do
        title 'No File Attached'
        warning 'No File Was Attached'
      end
      return false
    end

    fail_message = ''

    if multiple_files == false && upload_array.length > 1
      fail_message += 'More than one file was uploaded, '
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

    if fail_message.empty?
      return true
    end

    show do
      title 'Warning Uploaded CSV does not fit correct format'
      note fail_message.to_s
    end
    return false
  end

  # Attempt to upload a CSV
  #
  # @param expected_data_points [Integer]
  # @param headers
  # @param multi_files
  # @param file_location
  def get_validated_uploads(expected_data_points, headers, multi_files, file_location: 'Unknown Location')
    tries = 1
    max_tries = 10
    pass = false
    until pass == true
      csv_uploads = upload_csv(tries, max_tries, file_location: file_location)
      pass = validate_upload(csv_uploads, expected_data_points, headers, multiple_files: multi_files)
      tries += 1
      raise 'Too many failed upload attempts' if tries == max_tries && !pass
    end
    csv_uploads
  end

  # Instructions to upload CSV files of concentrations
  #
  # @param tries [Integer]
  # @param max_tries [String]
  # @param file_location [String]
  def upload_csv(tries: nil, max_tries: 'NA', file_location: 'Unknown Location')
    upload_csv = show do
      title "Upload CSV (attempts: #{tries}/#{max_tries})"
      note "Please upload the <b>CSV</b> file located at #{file_location}"
      upload var: CSV_KEY.to_sym
    end
    upload_csv.get_response(CSV_KEY.to_sym)
  end
end
