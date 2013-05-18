require 'active_support/core_ext/object/try'
require 'active_support/inflector'

  
class HasManyAssocParams
  attr_reader :other_class, :other_table_name, :primary_key, :foreign_key

  def initialize(other, original, params)
    @other_class_name = (params[:class_name]|| other.to_s.singularize).camelize
    @other_class = @other_class_name.constantize
    @other_table_name = @other_class.table_name
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{original.class.name.underscore}_id".to_sym
  end
end

class BelongsToAssocParams
  attr_reader :other_class, :other_table_name, :primary_key, :foreign_key

  def initialize(owner, params)
    @other_class_name = params[:class_name] || owner.to_s.camelize
    @other_class = @other_class_name.constantize
    @other_table_name = @other_class.table_name
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{@other_class_name}_id".to_sym
  end
end

module Associatable

  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(owner, params = {})
    bt = BelongsToAssocParams.new(owner, params)
    assoc_params[owner] = bt

    define_method(owner) do
      query = <<-SQL
        SELECT other.*
          FROM #{bt.other_table_name} AS other
         WHERE other.#{bt.primary_key} = ?
      SQL

      result = DBConnection.execute(query, self.id)
      bt.other_class.parse_all(result)
    end
  end

  def has_many(other, params = {}, original)
    define_method(other) do
    hm = HasManyAssocParams.new(other, params, original)

      query = <<-SQL
        SELECT other.*
          FROM #{hm.other_table_name} AS other
         WHERE other.#{hm.foreign_key} = ?
      SQL

      result = DBConnection.execute(query, self.id)
      hm.other_class.parse_all(result)
    end    
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      puts "SUCCESS"
    end
  end
end
