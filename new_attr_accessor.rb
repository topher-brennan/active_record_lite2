class Object
  def self.new_attr_accessor *instance_variables
    instance_variables.each do |instance_variable|
      send(:define_method, instance_variable) do
        instance_variable_get("@#{instance_variable.to_s}")
      end
      send(:define_method, instance_variable.to_s+"=") do |argument|
        instance_variable_set("@#{instance_variable.to_s}", argument)
      end
    end
  end
end