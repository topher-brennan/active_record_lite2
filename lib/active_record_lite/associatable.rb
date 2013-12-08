require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams

  def initialize(name, params)
    @other_class_name = params[:other_class_name] || name.to_s.camelcase
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{name}_id"
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:other_class_name] ||
      name.to_s.singularize.camelcase
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{self_class.to_s.underscore}_id"
  end

  def type
  end
end

module Associatable

  def assoc_params
    @assoc_params
  end

  def belongs_to(name, params = {})
    @assoc_params ||= {}

    params_object = BelongsToAssocParams.new(name, params)

    @assoc_params[name] = params_object

    define_method(name) do
      sql = <<-SQL
        SELECT
          *
        FROM
          #{params_object.other_table}
        WHERE
          #{params_object.primary_key} = ?
      SQL
      results = DBConnection.execute(sql, send(params_object.foreign_key))
      params_object.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    params_object = HasManyAssocParams.new(name, params, self)
    define_method(name) do
      sql = <<-SQL
        SELECT
          *
        FROM
          #{params_object.other_table}
        WHERE
          #{params_object.foreign_key} = ?
      SQL
      results = DBConnection.execute(sql, self.send(params_object.primary_key))
      params_object.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      params_object1 = self.class.assoc_params[assoc1]
      params_object2 = params_object1.other_class.assoc_params[assoc2]

      join_on_string = "#{params_object1.other_table}." +
        "#{params_object2.foreign_key} = " +
        "#{params_object2.other_table}." +
        "#{params_object2.primary_key}"

      sql = <<-SQL
        SELECT
          #{params_object2.other_table}.*
        FROM
          #{params_object1.other_table}
        JOIN
          #{params_object2.other_table}
        ON
          #{join_on_string}
        WHERE
          #{params_object1.other_table}.#{params_object1.primary_key} = ?
      SQL

      results = DBConnection.execute(sql, send(params_object1.foreign_key))

      params_object2.other_class.parse_all(results).first
    end
  end
end
