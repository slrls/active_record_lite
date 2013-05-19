require 'active_support/core_ext/object/try'
require 'active_support/inflector'

class Helper
  attr_reader :primary_key, :foreign_key, :other_class_name

  def other_class
    @other_class_name.constantize
  end

  def other_table_name
    other_class.table_name
  end
end


class BelongsToAssocParams < Helper
  def initialize(owner, params)
    @other_class_name = (params[:class_name] || owner.to_s).camelcase
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{@other_class_name.downcase}_id".to_sym
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < Helper
  def initialize(other, params, owner)
    @other_class_name = (params[:class_name]|| other.to_s.singularize).camelcase
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{@owner.name.downcase}_id".to_sym
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
        SELECT #{bt.other_table_name}.*
          FROM #{bt.other_table_name}
         WHERE #{bt.other_table_name}.#{bt.primary_key} = ?
      SQL

      result = DBConnection.execute(query, self.send(bt.foreign_key))
      bt.other_class.parse_all(result)
    end
  end

  def has_many(other, params = {})
    define_method(other) do
    hm = HasManyAssocParams.new(other, params, self)
      query = <<-SQL
        SELECT #{hm.other_table_name}.*
          FROM #{hm.other_table_name}
         WHERE #{hm.other_table_name}.#{hm.foreign_key} = ?
      SQL

      result = DBConnection.execute(query, self.id)
      hm.other_class.parse_all(result)
    end    
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      ab = self.class.assoc_params[assoc1]
      bc = ab.other_class.assoc_params[assoc2]

      if (ab.type == :belongs_to) && (bc.type == :belongs_to)
        query = <<-SQL
          SELECT #{bc.other_table_name}.*
            FROM #{ab.other_table_name}
            JOIN #{bc.other_table_name}
              ON #{ab.other_table_name}.#{bc.foreign_key} = #{bc.other_table_name}.#{bc.primary_key}
           WHERE #{ab.other_table_name}.#{ab.primary_key} = ? 
        SQL

        result = DBConnection.execute(query, self.id)
        bc.other_class.parse_all(result)
      end

    end
  end
end

