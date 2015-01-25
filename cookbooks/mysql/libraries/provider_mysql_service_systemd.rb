class Chef
  class Provider
    class MysqlService
      class Systemd < Chef::Provider::MysqlService
        action :start do
          template "#{new_resource.name} :start /usr/libexec/#{mysql_name}-wait-ready" do
            path "/usr/libexec/#{mysql_name}-wait-ready"
            source 'systemd/mysqld-wait-ready.erb'
            owner 'root'
            group 'root'
            mode '0755'
            variables(socket_file: socket_file)
            cookbook 'mysql'
            action :create
          end

          template "#{new_resource.name} :start /usr/lib/systemd/system/#{mysql_name}.service" do
            path "/usr/lib/systemd/system/#{mysql_name}.service"
            source 'systemd/mysqld.service.erb'
            owner 'root'
            group 'root'
            mode '0644'
            variables(
              config: new_resource,
              etc_dir: etc_dir,
              base_dir: base_dir
              )
            cookbook 'mysql'
            action :create
          end

          service "#{new_resource.name} :start #{mysql_name}" do
            service_name mysql_name
            provider Chef::Provider::Service::Systemd
            supports restart: true, status: true
            action [:enable, :start]
          end
        end

        action :stop do
          service "#{new_resource.name} :stop #{mysql_name}" do
            service_name mysql_name
            provider Chef::Provider::Service::Systemd
            supports status: true
            action [:disable, :stop]
            only_if { ::File.exist?("/usr/lib/systemd/system/#{mysql_name}.service") }
          end
        end

        action :restart do
          service "#{new_resource.name} :restart #{mysql_name}" do
            service_name mysql_name
            provider Chef::Provider::Service::Systemd
            supports restart: true
            action :restart
          end
        end

        action :reload do
          service "#{new_resource.name} :reload #{mysql_name}" do
            service_name mysql_name
            provider Chef::Provider::Service::Systemd
            action :reload
          end
        end

        def create_stop_system_service
          service "#{new_resource.name} :create mysql" do
            service_name 'mysqld'
            provider Chef::Provider::Service::Systemd
            supports status: true
            action [:stop, :disable]
          end
        end

        def delete_stop_service
          service "#{new_resource.name} :delete #{mysql_name}" do
            service_name mysql_name
            provider Chef::Provider::Service::Systemd
            supports status: true
            action [:disable, :stop]
            only_if { ::File.exist?("/usr/lib/systemd/system/#{mysql_name}.service") }
          end
        end
      end
    end
  end
end