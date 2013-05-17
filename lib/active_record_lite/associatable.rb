require 'active_support/core_ext/object/try'
require 'active_support/inflector'

module Associatable
  def belongs_to(owner, params=nil)
    define_method(owner) do
      other_class = (params[:class_name].camelize || owner.class.camelize ).constantize
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

  def has_many(name, params=nil)
    define_method("#{name}") do
      other_class = (params[:class_name].camelize || name.class.singularize.camelize).constantize
      other_table_name = other_class.table_name
      primary_key = params[:primary_key] || "id"
      foreign_key = params[:foreign_key] || "#{other_class.class.downcase}_id"
    end
    
  end
end