require 'active_support/core_ext/object/try'
require 'active_support/inflector'

module Associatable
  def belongs_to(owner, params)
    define_method(:other) do
      other_class = constantize(params[:class_name].camelize || "#{owner.class}")
      other_table_name = owner.table_name
      primary_key = params[:primary_key] || "id"
      foreign_key = params[:foreign_key] || "#{owner.class.downcase}_id"

    end
  end
end