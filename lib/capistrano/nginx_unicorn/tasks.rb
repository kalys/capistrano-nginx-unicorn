require 'capistrano'
require 'erb'
require 'byebug'

def set_default(name, value)
  set(name, value) if fetch(name).nil?
end

def template(template_name, target)
  config_file = "#{fetch(:templates_path)}/#{template_name}"
  # if no customized file, proceed with default
  unless File.exists?(config_file)
    config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/nginx_unicorn/templates/#{template_name}")
  end
  config_stream = StringIO.new(ERB.new(File.read(config_file)).result(binding))
  upload! config_stream, target
end

set_default(:templates_path, "config/deploy/templates")

set_default(:nginx_server_name, proc { ask(:nginx_server_name, "Nginx server name: "); fetch(:nginx_server_name) })
set_default(:nginx_use_ssl, false)
set_default(:nginx_pid, "/run/nginx.pid")
set_default(:nginx_ssl_certificate, proc { ask(:nginx_ssl_certificate, "Local path to ssl certificate: "); fetch(:nginx_ssl_certificate) })
set_default(:nginx_ssl_certificate_key, proc { ask(:nginx_ssl_certificate_key, "Local path to ssl certificate key: "); fetch(:nginx_ssl_certificate_key) })
set_default(:nginx_upload_local_certificate, true)
set_default(:nginx_ssl_certificate_local_path, proc { ask(:nginx_ssl_certificate_local_path, "Local path to ssl certificate: "); fetch(:nginx_ssl_certificate_local_path) })
set_default(:nginx_ssl_certificate_key_local_path, proc { ask(:nginx_ssl_certificate_key_local_path, "Local path to ssl certificate key: "); fetch(:nginx_ssl_certificate_key_local_path) })

set_default(:unicorn_pid, shared_path.join("pids/unicorn.pid"))
set_default(:unicorn_config, shared_path.join("config/unicorn.rb"))
set_default(:unicorn_log, shared_path.join("log/unicorn.log"))
set_default(:unicorn_user, fetch(:user))
set_default(:unicorn_workers, proc { ask(:unicorn_workers, "Number of unicorn workers: "); fetch(:unicorn_workers) })

set_default(:nginx_config_path, "/etc/nginx/sites-available")

namespace :nginx do
  desc "Setup nginx configuration for this application"
  task :setup do
    on roles(:web) do
      template("nginx_conf.erb", "/tmp/#{fetch(:application)}")
      if fetch(:nginx_config_path) == "/etc/nginx/sites-available"
        execute "#{fetch(:sudo)} mv /tmp/#{fetch(:application)} /etc/nginx/sites-available/#{fetch(:application)}"
        execute "#{fetch(:sudo)} ln -fs /etc/nginx/sites-available/#{fetch(:application)} /etc/nginx/sites-enabled/#{fetch(:application)}"
      else
        execute "#{fetch(:sudo)} mv /tmp/#{fetch(:application)} #{fetch(:nginx_config_path)}/#{fetch(:application)}.conf"
      end

      if fetch(:nginx_use_ssl)
        if fetch(:nginx_upload_local_certificate)
          upload! fetch(:nginx_ssl_certificate_local_path), "/tmp/#{fetch(:nginx_ssl_certificate)}"
          upload! fetch(:nginx_ssl_certificate_key_local_path), "/tmp/#{fetch(:nginx_ssl_certificate_key)}"
          
          execute "#{fetch(:sudo)} mv /tmp/#{fetch(:nginx_ssl_certificate)} /etc/ssl/certs/#{fetch(:nginx_ssl_certificate)}"
          execute "#{fetch(:sudo)} mv /tmp/#{fetch(:nginx_ssl_certificate_key)} /etc/ssl/private/#{fetch(:nginx_ssl_certificate_key)}"
        end
        
        execute "#{fetch(:sudo)} chown root:root /etc/ssl/certs/#{fetch(:nginx_ssl_certificate)}"
        execute "#{fetch(:sudo)} chown root:root /etc/ssl/private/#{fetch(:nginx_ssl_certificate_key)}"
      end
    end
  end

  desc "Reload nginx configuration"
  task :reload do
    on roles(:web) do
      execute "#{fetch(:sudo)} /etc/init.d/nginx reload"
    end
  end
end

namespace :unicorn do
  desc "Setup Unicorn initializer and app configuration"
  task :setup do
    on roles(:app) do
      execute :mkdir, "-p", shared_path.join("config")
      execute :mkdir, "-p", shared_path.join("log")
      execute :mkdir, "-p", shared_path.join("pids")
      template "unicorn.rb.erb", fetch(:unicorn_config)
      template "unicorn_init.erb", "/tmp/unicorn_init"
      execute "chmod +x /tmp/unicorn_init"
      execute "#{fetch(:sudo)} mv /tmp/unicorn_init /etc/init.d/unicorn_#{fetch(:application)}"
      execute "#{fetch(:sudo)} update-rc.d -f unicorn_#{fetch(:application)} defaults"
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
    execute "#{fetch(:sudo)} mv /tmp/#{fetch(:application)}_logrotate /etc/logrotate.d/#{fetch(:application)}"
    execute "#{fetch(:sudo)} chown root:root /etc/logrotate.d/#{fetch(:application)}"
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


