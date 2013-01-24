def load_current_resource
  # Because these attributes are loaded lazily
  # we have to call each one explicitly
  new_resource.vm_swap_file new_resource.vm_swap_file ||"/var/lib/redis/#{new_resource.name}.swap"
  new_resource.pidfile      new_resource.pidfile || "/var/run/redis/#{new_resource.name}.pid"
  new_resource.logfile      new_resource.logfile || "/var/log/redis/#{new_resource.name}.log"
  new_resource.dbfilename   new_resource.dbfilename || "#{new_resource.name}.rdb"
  new_resource.user         new_resource.user  || node.redis.user
  new_resource.group        new_resource.group || node.redis.group
  new_resource.init_style
  new_resource.configure_no_appendfsync_on_rewrite
  new_resource.configure_slowlog
  new_resource.configure_list_max_ziplist
  new_resource.configure_maxmemory_samples
  new_resource.configure_set_max_intset_entries
  new_resource.conf_dir


  new_resource.state

#  new_resource.appendonly
#  new_resource.appendfsync
#  new_resource.daemonize
#  new_resource.dir
#  new_resource.databases
#  new_resource.bind
#  new_resource.port
#  new_resource.loglevel
#  new_resource.rdbcompression
#  new_resource.timeout
#  new_resource.save
#  new_resource.activerehashing

#  new_resource.vm_max_memory
#  new_resource.vm_max_threads
#  new_resource.vm_page_size
#  new_resource.vm_pages

#  new_resource.slowlog_log_slower_than
#  new_resource.slowlog_max_len
#  new_resource.maxmemory_samples

#  new_resource.no_appendfsync_on_rewrite

#  new_resource.list_max_ziplist_entries
#  new_resource.list_max_ziplist_value

#  new_resource.set_max_intset_entries

end

action :create do
  create_user_and_group
  create_service
  create_config
  new_resource.updated_by_last_action(true)
end


action :destroy do
  disable_service
  new_resource.updated_by_last_action(true)
end

private

def create_user_and_group
  group new_resource.group

  user new_resource.user do
    gid new_resource.group
  end
end

def create_config
  directory new_resource.conf_dir do
    owner "root"
    group "root"
    mode 0755
  end

  directory new_resource.dir do
    owner new_resource.user
    group new_resource.group
    mode 0755
  end

  redis_service_name = redis_service
  template "#{new_resource.conf_dir}/#{new_resource.name}.conf" do
    source "redis.conf.erb"
    owner "root"
    group "root"
    mode 0644
    variables :config => new_resource.state
    notifies :restart, "service[#{redis_service_name}]", :immediate
  end
end

def create_service
  template "/etc/init.d/redis-#{new_resource.name}" do
    source "redis_init.erb"
    owner "root"
    group "root"
    mode 0755
    variables new_resource.to_hash
  end


  service redis_service do
    action [ :enable, :start ]
  end
end

def disable_service
  service redis_service do
    action [ :disable, :stop ]
  end
end

def redis_service
  redis_service = case node.platform_family
                  when "debian"
                    "redis-server-#{new_resource.name}"
                  when "rhel", "fedora"
                    "redis-#{new_resource.name}"
                  else
                    "redis-#{new_resource.name}"
                  end
end
