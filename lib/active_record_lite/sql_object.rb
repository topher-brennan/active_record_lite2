require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name ||= self.to_s.underscore.pluralize
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    rows = []
    sql =<<-SQL
    SELECT
      *
    FROM
      #{@table_name}
    SQL
    DBConnection.execute(sql).each { |row_hash| rows << self.new(row_hash) }
    rows
  end


  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    sql =<<-SQL
    SELECT
     *
    FROM
      #{@table_name}
    WHERE
      id = ?
    SQL
    query_result = DBConnection.execute(sql, id).first
    return nil if query_result == nil
    self.new(query_result)
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
    values = self.class.attributes.map { |attribute| self.send(attribute) }
    sql =<<-SQL
    INSERT INTO
      #{@table_name}  #{self.class.attributes.join(", ")}
    VALUES
      #{['?']*10.join(", ")}
    SQL
    DBConnection.execute(sql, *values)
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    set_strings = self.class.attributes.map do |attribute|
      "#{attribute} = ?"
    end
    values = self.class.attributes.map { |attribute| self.send(attribute) }
    sql =<<-SQL
    UPDATE
      #{self.class.table_name}
    SET
      #{set_strings.join(', ')}
    WHERE
      id = #{id}
    SQL
    puts sql

    DBConnection.execute(sql, *values)
  end

  # call either create or update depending if id is nil.
  def save
    if id == nil
      create
    else
      update
    end
  end

  # helper method to return values of the attributes.
  def attribute_values
  end
end
