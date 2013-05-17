class MassObject
  @attributes = []

  def self.set_attrs(*attributes)
    attributes.each do |attribute|
      send(:attr_accessor, attribute)
    end
    @attributes = attributes
  end

  def self.attributes
    @attributes
  end

  def initialize(params)
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        send("#{attr_name}=", value)
      else
        raise Exception.new("mass assignment to unregistered
      attribute #{attr_name}")
      end
    end
  end

  def self.parse_all(results)
    results.map do |row|
      self.new(row)
    end
  end
end
