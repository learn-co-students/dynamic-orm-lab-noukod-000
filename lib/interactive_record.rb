require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "pragma table_info(#{table_name})"

    info = DB[:conn].execute(sql)
    column_names = []
    info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  def initialize **options
    options.each do |key, value|
      send("#{key}=",value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    self.class.column_names.map do |col|
      "'#{send(col)}'" unless send(col).nil?
    end.compact.join(", ")
  end

  def save
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
    VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name name
    sql = <<-SQL
    SELECT * FROM #{table_name} WHERE name = ? LIMIT 1
    SQL
    DB[:conn].execute(sql,name)
  end

  def self.find_by **attr
    sql = <<-SQL
    SELECT * FROM #{table_name} WHERE #{attr.keys[0].to_s} = ? LIMIT 1
    SQL
    DB[:conn].execute(sql,attr.values[0].to_s)
  end

end
