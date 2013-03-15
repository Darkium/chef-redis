include_recipe "redis::install"

bag = node.redis.data_bag_name

node.redis.instances.each do |instance|
  instance_data = data_bag_item( bag, instance )

  redis_instance instance do

    if node.redis.config.slaveof_ip
      send("slaveof_ip", node.redis.config.slaveof_ip)
    end
    
    instance_data.each do |attribute,value|
      
      if attribute == "port"
        send("slaveof_port", value)
      end
      
      send(attribute, value) unless attribute == "id"
    end
    
  end
end
