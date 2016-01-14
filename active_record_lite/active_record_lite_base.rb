require_relative 'db_connection'
require 'active_support/inflector'

class AttrAccessorObject

  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method("#{name}") do
        instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |name_var|
        instance_variable_set("@#{name}", name_var)
      end
    end
  end
end

class SQLObject
  extend Associatable
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL
    .first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end

    def attributes
      @attributes ||= {}
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name
      @table_name
    else
      self.to_s.tableize
    end
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT #{self.to_s.tableize}.*
      FROM #{self.to_s.tableize}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT #{self.table_name}.*
      FROM #{self.table_name}
      WHERE #{id} = #{self.table_name}.id
      LIMIT 1
    SQL
    return nil if result.first.nil?
    self.new(result.first)
  end

  def initialize(params = {})
    params.each do |column, value|
      column_sym = column.to_sym
      fail "unknown attribute \'#{column}\'" unless self.class.columns.include?(column_sym)
      self.send("#{column.to_s}=", value)
    end
  end

  def attribute_values
    self.class.columns.map { |column| send(column) }
  end

  def insert
    columns = self.class.columns
    col_names = columns.join(", ")
    question_marks = (["?"] * columns.count).join(", ")
    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_col = self.class.columns.map { |column| "#{column} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_col}
      WHERE
        id = ?
    SQL
  end

  def save
    if id
      update
    else
      insert
    end
  end
end

module Searchable
  def where(params)
    where_line = params.map { |key, value| "#{key} = ?" }.join(" AND ")
    results = DBConnection.execute(<<-SQL, params.values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_line}
    SQL

    results.map { |result| self.new(result) }
  end
end

class SQLObject
  extend Searchable
end

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    Object.const_get(class_name)
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    if options[:foreign_key].nil?
      @foreign_key = "#{name}_id".to_sym
    else
      @foreign_key = options[:foreign_key]
    end

    if options[:primary_key].nil?
      @primary_key = :id
    else
      @primary_key = options[:primary_key]
    end

    if options[:class_name].nil?
      @class_name = name.to_s.camelcase
    else
      @class_name = options[:class_name]
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    if options[:foreign_key].nil?
      @foreign_key = "#{self_class_name.underscore}_id".to_sym
    else
      @foreign_key = options[:foreign_key]
    end

    if options[:primary_key].nil?
      @primary_key = :id
    else
      @primary_key = options[:primary_key]
    end

    if options[:class_name].nil?
      @class_name = name.to_s.singularize.camelcase
    else
      @class_name = options[:class_name]
    end
  end
end

module Associatable
  def assoc_options
    @assoc_hash ||= Hash.new
  end


  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    assoc_options[name] = options

    define_method(name) do
      options.model_class.where(options.primary_key => self.send(options.foreign_key)).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    assoc_options[name] = options
    define_method(name) do
      options.model_class.where(options.foreign_key => self.id)
    end
  end


end

module Associatable
  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]
    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]

      results = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key))
        SELECT #{source_options.table_name}.*
        FROM #{through_options.table_name}
        JOIN #{source_options.table_name} ON #{source_options.table_name}.id = #{through_options.table_name}.#{source_options.foreign_key}
        WHERE #{through_options.table_name}.id = ?
      SQL
      results.map { |result| source_options.model_class.new(result) }.first
    end
  end
end
