# frozen_string_literal: true

# Justin Vrana
#
# modified by:
# Cannon Mallory
# malloc3@uw.edu
#
# Modifications include:
# Optional Checkable boxes.  Additional Documentation

#
# This module is for displaying information about collections in effecient easy to use ways
module CollectionDisplay

  # Creates a table with the same dimensions as the input collection
  #
  # @param collection [Collection] the collection to be represented by the table
  def create_collection_table(collection)
    size = collection.object_type.rows * collection.object_type.columns
    slots = (1..size).to_a
    slots.each_slice(collection.object_type.columns).map do |row|
      row.map do |col|
        { content: col, class: 'td-empty-slot' }
      end
    end
  end

  # Highlights a specific location in a table (TODO TABLE CLASS)
  #
  # @param tbl [Table] the table which parts are being highlighted
  # @param row [Integer] the row
  # @param col [Integer] the column
  # @param id [String] what will be printed in the table
  #                    (TODO EMPTY STRING/DONT REPLACE CONTENT)
  # @param check [Boolean] optional determins if cell is checkable or not
  def highlight_cell(tbl, row, col, id, check: true)
    tbl[row][col] = { content: id, class: 'td-filled-slot', check: check }
  end

  # Highlights all cells in ROW/COLUMN/X  (TODO TABLE CLASS)
  # X can be any string that is to be displayed in cell
  #
  # @param table [table] the table with cells to be highlighted
  # @param rcx_list [array] array of [[row, column, x],...]
  #     row = int
  #     col = int
  #     x = string
  # @return [table]
  def highlight_rcx(table, rcx_list, check: true)
    raise "Passed Collection when Table needed.  You may want to use
          'highlight_collection_rcx' instead" if table.class == 'Collection'
    rcx_list.each do |rcx|
      rcx.push(check)
    end
    highlight_rcx_check(table, rcx_list)
    table
  end

  # Highlights all cells in ROW/COLUMN/X  (TODO TABLE CLASS)
  # X can be any string that is to be displayed in cell
  #
  # @param table [Table] the table with cells to be highlighted
  # @param rcx_list [Array] array of [[row, colum, x, check],...]
  #     row = int
  #     col = int
  #     x = string
  #     check = boolean
  # @return [Table]
  def highlight_rcx_check(table, rcx_check_list)
    rcx_check_list.each do |r, c, x, check|
      highlight_cell(table, r, c, x, check: check)
    end
    table
  end

  # Highlights all cells in ROW/COLUMN/X (CHANGED NAME)
  # X can be any string that is to be displayed in cell
  #
  # @param collection [Collection] the collection
  # @param rcx_list [Array] array of [[row, colum, x],...]
  #     row = int
  #     col = int
  #     x = string
  # @return [Table]
  def highlight_collection_rcx(collection, rcx_list, check: true)
    tbl = create_collection_table(collection)
    highlight_rcx(tbl, rcx_list, check: check)
  end

  # TODO: TABLE LIB
  # Highlights all cells listed in rc_list
  #
  # @param collection [Collection] the collection which should be highlighted
  # @param rc_list [Array] array of rc [[row,col],...]
  #                       row = int
  #                       col = int
  # @param check [Boolean] wheather cells should be Checkable
  # @param &rc_block [Block] to determine rc list
  # @return [Table]
  def highlight_rc(table, rc_list, check: true, &rc_block)
    rcx_list = rc_list.map { |r, c|
      block_given? ? [r, c, yield(r, c)] : [r, c, ""]
    }
    highlight_rcx(table, rcx_list, check: check)
  end

  # Highlights all cells listed in rc_list (CHANGED NAME)
  #
  # @param collection [Collection] the collection which should be highlighted
  # @param rc_list [Array] array of rc [[row,col],...]
  #                       row = int
  #                       col = int
  # @param check [Boolean] Optional wheather cells should be Checkable
  # @param &rc_block [Block] to determine rc list
  # @return [Table]
  def highlight_collection_rc(collection, rc_list,  check: true, &rc_block)
    rcx_list = rc_list.map { |r, c|
      block_given? ? [r, c, yield(r, c)] : [r, c, ""]
    }
    highlight_collection_rcx(collection, rcx_list, check: check)
  end

  # Highlights all non-empty slots in collection
  #
  # @param collection [Collection] the collection
  # @param check [Boolean] Optional weather cells should be Checkable
  # @param &rc_block [Block] Optional block to determin rc_list
  # @return [Table]
  def highlight_non_empty(collection, check: true, &rc_block)
    highlight_collection_rc(collection, collection.get_non_empty, check: check, &rc_block)
  end

  # Highlights all slots in all collections in operation list
  #
  # @param ops [OperationList] Operation list
  # @param id_block [Block] Optional Unkown
  # @param check [Boolean] Optional weather cells are checkable
  # @param &fv_block [Block] Optional Unknown
  # @return [Table]
  def highlight_collection(ops, id_block: nil, check: true, &fv_block)
    g = ops.group_by { |op| fv_block.call(op).collection }
    tables = g.map do |collection, grouped_ops|
      rcx_list = grouped_ops.map do |op|
        fv = fv_block.call(op)
        id = id_block.call(op) if id_block
        id ||= fv.sample.id
        [fv.row, fv.column, id]
      end
      tbl = highlight_collection_rcx(collection, rcx_list, check: check)
      [collection, tbl]
    end
    tables
  end

  # Unknown/TBD
  #
  # @param collection [Collection] the collection
  # @param r [Integer] row integer
  # @param c [Integer] column integer
  def r_c_to_slot(collection, r, c)
    rows, cols = collection.dimensions = collection.object_type.rows
    r*cols + c+1
  end

  # Makes an Alpha Numeric Table from Collection
  #
  # @param collection [Collection] the collection that the table is based from
  def create_alpha_numeric_table(collection)
    size = collection.object_type.rows * collection.object_type.columns
    slots = (1..size).to_a
    alpha_r = ('A'..'H').to_a
    slots.each_slice(collection.object_type.columns).each_with_index.map do |row, r_idx|
      row.each_with_index.map do |col, c_idx|
        { content: "#{alpha_r[r_idx]}#{c_idx + 1}", class: 'td-empty-slot' }
      end
    end
  end

  # Makes an alpha numerical display of collection wells listed in rc_list
  #
  # @param collection [Collection] the collection
  # @param rc_list [Array] Array of rows and colums [[row,col],...] row & col are int
  # @param check [Boolean] Default True weather cells are checkable
  # @param &rc_block [Block] Optional tbd
  def highlight_alpha_rc(collection, rc_list, check: true, &rc_block)
    rcx_list = rc_list.map { |r, c|
      block_given? ? [r, c, yield(r, c)] : [r, c, '']
    }
    highlight_alpha_rcx(collection, rcx_list, check: check)
  end

  # Makes an alpha numerical display of collection wells listed in rcx_list
  #
  # @param collection [Collection] the collection
  # @param rc_list [Array] Array of rows and colums [[row,col,x],...] row & col are int, x is string to be displayed in cell
  # @param check [Boolean] Default True weather cells are checkable
  # @param &rc_block [Block] Optional tbd
  def highlight_alpha_rcx(collection, rcx_list, check: true)
    tbl = create_alpha_numeric_table(collection)
    rcx_list.each do |r, c, x|
      highlight_cell(tbl, r, c, x, check: check)
    end
    tbl
  end

  # Highlights all non-empty slots in collection
  #
  # @param collection [Collection] the collection
  # @param check [Boolean] Optional weather cells should be Checkable
  # @param &rc_block [Block] Optional block to determin rc_list
  # @return [Table]
  def highlight_alpha_non_empty(collection, check: true, &rc_block)
    highlight_alpha_rc(collection, collection.get_non_empty, check: check, &rc_block)
  end
end
