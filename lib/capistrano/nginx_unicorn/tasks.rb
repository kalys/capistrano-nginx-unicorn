require 'capistrano'

def set_default(name, *args, &block)
  set(name, *args, &block) unless fetch(name).nil?
end

def template(template_name, target)
  config_file = "#{templates_path}/#{template_name}"
  # if no customized file, proceed with default
  unless File.exists?(config_file)
    config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/nginx_unicorn/templates/#{template_name}")
  end
  put ERB.new(File.read(config_file)).result(binding), target
end

set_default(:templates_path, "config/deploy/templates")

set_default(:nginx_server_name) { Capistrano::CLI.ui.ask "Nginx server name: " }
set_default(:nginx_use_ssl, false)
set_default(:nginx_pid) { "/run/nginx.pid" }
set_default(:nginx_ssl_certificate) { "#{nginx_server_name}.crt" }
set_default(:nginx_ssl_certificate_key) { "#{nginx_server_name}.key" }
set_default(:nginx_upload_local_certificate) { true }
set_default(:nginx_ssl_certificate_local_path) {Capistrano::CLI.ui.ask "Local path to ssl certificate: "}
set_default(:nginx_ssl_certificate_key_local_path) {Capistrano::CLI.ui.ask "Local path to ssl certificate key: "}

set_default(:unicorn_pid) { "#{current_path}/tmp/pids/unicorn.pid" }
set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
set_default(:unicorn_log) { "#{shared_path}/log/unicorn.log" }
set_default(:unicorn_user) { user }
set_default(:unicorn_workers) { Capistrano::CLI.ui.ask "Number of unicorn workers: " }

set_default(:nginx_config_path) { "/etc/nginx/sites-available" }

namespace :nginx do
  desc "Setup nginx configuration for this application"
  task :setup do
    on roles(:web) do
      template("nginx_conf.erb", "/tmp/#{fetch(:application)}")
      if nginx_config_path == "/etc/nginx/sites-available"
        execute "#{sudo} mv /tmp/#{fetch(:application)} /etc/nginx/sites-available/#{fetch(:application)}"
        execute "#{sudo} ln -fs /etc/nginx/sites-available/#{fetch(:application)} /etc/nginx/sites-enabled/#{fetch(:application)}"
      else
        execute "#{sudo} mv /tmp/#{fetch(:application)} #{nginx_config_path}/#{fetch(:application)}.conf"
      end

      if nginx_use_ssl
        if nginx_upload_local_certificate
          put File.read(nginx_ssl_certificate_local_path), "/tmp/#{nginx_ssl_certificate}"
          put File.read(nginx_ssl_certificate_key_local_path), "/tmp/#{nginx_ssl_certificate_key}"
          
          execute "#{sudo} mv /tmp/#{nginx_ssl_certificate} /etc/ssl/certs/#{nginx_ssl_certificate}"
          execute "#{sudo} mv /tmp/#{nginx_ssl_certificate_key} /etc/ssl/private/#{nginx_ssl_certificate_key}"
        end
        
        execute "#{sudo} chown root:root /etc/ssl/certs/#{nginx_ssl_certificate}"
        execute "#{sudo} chown root:root /etc/ssl/private/#{nginx_ssl_certificate_key}"
      end
    end
  end

  desc "Reload nginx configuration"
  task :reload do
    on roles(:web) do
      execute "#{sudo} /etc/init.d/nginx reload"
    end
  end
end

namespace :unicorn do
  desc "Setup Unicorn initializer and app configuration"
  task :setup do
    on roles(:app) do
      execute :mkdir, "-p", shared_path.join("config")
      template "unicorn.rb.erb", fetch(:unicorn_config)
      template "unicorn_init.erb", "/tmp/unicorn_init"
      execute "chmod +x /tmp/unicorn_init"
      execute "#{sudo} mv /tmp/unicorn_init /etc/init.d/unicorn_#{fetch(:application)}"
      execute "#{sudo} update-rc.d -f unicorn_#{fetch(:application)} defaults"
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} unicorn"
    task command do
      on roles(:app) do
        execute "service unicorn_#{fetch(:application)} #{command}"
      end
    end
  end

  # ensure that unicorn is setup before attempting to restart...
  before :restart, "unicorn:setup"
end

desc "Setup logs rotation for nginx and unicorn"
task :logrotate do
  on roles(:web, :app) do
    template("logrotate.erb", "/tmp/#{fetch(:application)}_logrotate")
    execute "#{sudo} mv /tmp/#{fetch(:application)}_logrotate /etc/logrotate.d/#{fetch(:application)}"
    execute "#{sudo} chown root:root /etc/logrotate.d/#{fetch(:application)}"
  end
end

namespace :deploy do

  after :finishing, "nginx:setup"
  after :finishing, "nginx:reload"
  after :finishing, "unicorn:setup"
  after :finishing, "unicorn:start"
  after :restart, "unicorn:restart"
  after :finishing, "logrotate"

end


