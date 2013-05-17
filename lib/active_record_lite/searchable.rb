module Searchable
  def where(params)
    args = []
    vals = []

    params.each do |key, val|
      args << "#{key} = ?"
      vals << val
    end

    query = <<-SQL
      SELECT *
        FROM #{self.table_name}
       WHERE #{args.join(' AND ')}
    SQL

    rows = DBConnection.execute(query, *vals)
    
    rows.map do |row|
      self.new(row)
    end
  end
end