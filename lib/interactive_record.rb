require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    #hash of columns names
    #return them as a an array of strings
    column_names = []
    #DB[:conn].results_as_hash = true #not sure that this is needed since it is in the environment file

    sql = "PRAGMA table_info('#{table_name}')" #give you the hash of info
    table_info = DB[:conn].execute(sql)

    table_info.each do |col| #iterate over the array of hashes
      column_names << col["name"] #this gives you the value for the key "name"
    end
    column_names.compact #to get rid of any nulls
  end


  def initialize(options = {}) #pass in a hash
    options.each do |key,value|
      self.send(("#{key}="),value)
    end
  end

  def table_name_for_insert
    #returns the table name when called on an intance of a Student
    self.class.table_name
  end

  def col_names_for_insert
    #return the column names when called on an instance of Student
    #returns it as a string ready to be inserted into a sql statement
    self.class.column_names.delete_if {|column_name| column_name == "id"}.join (", ")
  end

  def values_for_insert
    #to insert data into db
    #formats the column names to be used in a SQL statement
    #use the column_names array, iterate over it to get the attribute names
    #and then user the attribute = method with send to assign the value
    values_array = []
    self.class.column_names.each do |column_name|
      #get the value for each attribute name
      values_array << "'#{send(column_name)}'" unless send(column_name).nil?
    end
    values_array.join(", ")
  end

  def save
    #insert data into db #save saves the student to the db
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attribute)
    #executes the SQL to find a row by the attribute passed into the method
    #WHERE name = ? OR grade = ? OR id = ?
    #attribute is a hash, so it has a key/value pair
    attribute_key = attribute.keys.join()
    attrubute_value = attribute.values.first
    sql =<<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{attribute_key} = "#{attrubute_value}"
      LIMIT 1
    SQL
    row = DB[:conn].execute(sql)
  end
  
=begin
this was the schools answer
 def self.find_by(attribute_hash)
    value = attribute_hash.values.first
    formatted_value = value.class == Fixnum ? value : "'#{value}'"
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{formatted_value}"
    DB[:conn].execute(sql)
  end
=end

end
