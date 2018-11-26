require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def initialize(options = {})
    options.each do |key, value|
      self.send("#{key}=", value) unless(value.nil?)
    end
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    columns = DB[:conn].execute("PRAGMA table_info(#{table_name})")

    columns.map do |col|
      col["name"]
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []

    self.class.column_names.each do |column|
      values << "'#{send(column)}'" unless(send(column).nil?)
    end

    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES(#{values_for_insert})
    SQL

    DB[:conn].execute sql
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name name
    sql = "SELECT * FROM #{table_name} WHERE name = ?"
    DB[:conn].results_as_hash = true

    DB[:conn].execute sql, name
  end

  def self.find_by column
    col_name, col_value = column.first

    sql = "SELECT * FROM #{table_name} WHERE #{col_name.to_s} = '#{col_value}'"
    DB[:conn].results_as_hash = true

    DB[:conn].execute sql
  end
end
