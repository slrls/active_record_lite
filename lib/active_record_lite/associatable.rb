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

module Associatable

  def belongs_to(owner, params=nil)
    define_method(owner) do
      other_class = (params[:class_name].camelize || owner.to_s.camelize ).constantize
      other_table_name = other_class.table_name
      primary_key = params[:primary_key] || "id"
      foreign_key = params[:foreign_key] || "#{other_class}_id"

      query = <<-SQL
        SELECT other.*
          FROM #{self.class.table_name} AS original 
          JOIN #{other_table_name} AS other
            ON original.#{foreign_key} = other.#{primary_key}
         WHERE original.#{primary_key} = ?
      SQL

      result = DBConnection.execute(query, self.id)
      other_class.parse_all(result)
    end
  end

  def has_many(other, params=nil)
    define_method(other) do
      aps = HasManyAssocParams.new(other, self, params)

      query = <<-SQL
        SELECT other.*
          FROM #{self.class.table_name} AS original 
          JOIN #{aps.other_table_name} AS other
            ON original.#{aps.primary_key} = other.#{aps.foreign_key}
         WHERE original.#{aps.primary_key} = ?
      SQL

      puts query

      result = DBConnection.execute(query, self.id)
      aps.other_class.parse_all(result)
    end
    
  end
end
