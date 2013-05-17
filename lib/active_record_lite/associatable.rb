require 'active_support/core_ext/object/try'
require 'active_support/inflector'

  
class HasManyAssocParams
  attr_reader :other_class, :other_table_name, :primary_key, :foreign_key, :own_table_name

  def initialize(other, original, params=nil)
    @other_class = (params[:class_name]|| other.to_s.singularize)
    @other_class = @other_class.camelize.constantize

    @other_table_name = @other_class.table_name
    @own_table_name = original.class.table_name

    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{@other_class.to_s.downcase}_id"
  end
end

class BelongsToAssocParams
  attr_reader :other_class, :other_table_name, :primary_key, :foreign_key, :own_table_name

  def initialize(owner, original, params)
    @other_class = (params[:class_name].camelize || owner.to_s.camelize ).constantize
    @other_table_name = other_class.table_name
    @own_table_name = original.class.table_name
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{other_class}_id"
  end
end

module Associatable

  def belongs_to(owner, params=nil)
    define_method(owner) do
      bt = BelongsToAssocParams.new(owner, self, params)

      query = <<-SQL
        SELECT other.*
          FROM #{bt.own_table_name} AS original 
          JOIN #{bt.other_table_name} AS other
            ON original.#{bt.foreign_key} = other.#{bt.primary_key}
         WHERE original.#{bt.primary_key} = ?
      SQL

      result = DBConnection.execute(query, self.id)
      bt.other_class.parse_all(result)
    end
  end

  def has_many(other, params=nil)
    define_method(other) do
      hm = HasManyAssocParams.new(other, self, params)

      query = <<-SQL
        SELECT other.*
          FROM #{hm.own_table_name} AS original 
          JOIN #{hm.other_table_name} AS other
            ON original.#{hm.primary_key} = other.#{hm.foreign_key}
         WHERE original.#{hm.primary_key} = ?
      SQL

      result = DBConnection.execute(query, self.id)
      hm.other_class.parse_all(result)
    end
    
  end
end
