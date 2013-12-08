require_relative './db_connection'

module Searchable
  # takes a hash like { :attr_name => :search_val1, :attr_name2 => :search_val2 }
  # map the keys of params to an array of  "#{key} = ?" to go in WHERE clause.
  # Hash#values will be helpful here.
  # returns an array of objects
  def where(params)
    sql =<<-SQL
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{params.keys.map { |key| "#{key} = ?"}.join(" AND ")}
    SQL

    puts sql

    parse_all(DBConnection.execute(sql, *params.values))
  end
end