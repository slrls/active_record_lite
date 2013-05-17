class SQLObject < MassObject
  extend Searchable
  extend Associatable
  @table_name

  def self.set_table_name(name)
    @table_name = name
  end

  def self.table_name
    @table_name
  end

  def self.all 
    query = <<-SQL
      SELECT *
        FROM "#{self.table_name}"
    SQL

    all_objs = []
    rows = DBConnection.execute(query)
    # rows.each do |row|
    #   all_objs << self.new(row)
    # end

    # all_objs

    parse_all(rows)
  end

  def self.find(id)
    query = <<-SQL
      SELECT *
        FROM "#{self.table_name}"
       WHERE id = ?
    SQL

    row = DBConnection.execute(query, id)
    self.new(row.first)
  end

  def save
    if id.nil?
      create
    else
      update
    end
  end

  private
  
  def create
    q_array = Array.new(self.class.attributes.size) { "?" }
    
    hash = collect_data(true)
    
    query = <<-SQL
      INSERT INTO #{self.class.table_name} (#{self.class.attributes.join(', ')})
           VALUES (#{q_array.join(', ')})
    SQL

    DBConnection.execute(query, *hash.values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    hash = collect_data(false)

    changes = hash.map do |key, val|
      "'#{key}' = '#{val}'"
    end.join(', ')

    query = <<-SQL
      UPDATE #{self.class.table_name} 
         SET #{changes}
       WHERE  'id' = ?
    SQL

    DBConnection.execute(query, self.id)
  end

  def collect_data(create)
    hash = {}
    self.class.attributes.each do |attribute|
      next if attribute == "id" unless create
      hash[attribute] = send(attribute)
    end
    hash
  end
end
