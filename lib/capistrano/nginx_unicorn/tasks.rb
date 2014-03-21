require 'capistrano'
require 'erb'

load File.expand_path("../tasks/nginx.rake", __FILE__)
load File.expand_path("../tasks/unicorn.rake", __FILE__)

def template(template_name, target)
  config_file = "#{fetch(:templates_path)}/#{template_name}"
  # if no customized file, proceed with default
  unless File.exists?(config_file)
    config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/nginx_unicorn/templates/#{template_name}")
  end
  config_stream = StringIO.new(ERB.new(File.read(config_file)).result(binding))
  upload! config_stream, target
end

desc "Setup logs rotation for nginx and unicorn"
task :logrotate do
  on roles(:web, :app) do
    template("logrotate.erb", "/tmp/#{fetch(:application)}_logrotate")
    execute "#{fetch(:sudo)} mv /tmp/#{fetch(:application)}_logrotate /etc/logrotate.d/#{fetch(:application)}"
    execute "#{fetch(:sudo)} chown root:root /etc/logrotate.d/#{fetch(:application)}"
  end
end

namespace :nginx_unicorn do
  desc "Setup nginx and unicorn"
  task :setup do
  end

  task :defaults do
    def set_default(name, value)
      set(name, value) if fetch(name).nil?
    end

    set_default(:templates_path, "config/deploy/templates")
    set_default(:sudo, "sudo")

    set_default(:nginx_server_name, "#{fetch(:application)}.local")
    set_default(:nginx_use_ssl, false)
    set_default(:nginx_pid, "/run/nginx.pid")
    set_default(:nginx_ssl_certificate, "#{fetch(:nginx_server_name)}.crt")
    set_default(:nginx_ssl_certificate_key, "#{fetch(:nginx_server_name)}.key")
    set_default(:nginx_upload_local_certificate, true)
    set_default(:nginx_ssl_certificate_local_path, proc { ask(:nginx_ssl_certificate_local_path, "Local path to ssl certificate: ") })
    set_default(:nginx_ssl_certificate_key_local_path, proc { ask(:nginx_ssl_certificate_key_local_path, "Local path to ssl certificate key: ") })

    set_default(:unicorn_pid, shared_path.join("pids/unicorn.pid"))
    set_default(:unicorn_config, "/etc/unicorn.rb")
    set_default(:unicorn_log, shared_path.join("log/unicorn.log"))
    set_default(:unicorn_user, fetch(:user))
    set_default(:unicorn_workers, 2)

    set_default(:nginx_config_path, "/etc/nginx/sites-available")
  end

  before :setup, 'nginx_unicorn:defaults'
  before :setup, 'nginx:setup'
  before :setup, 'unicorn:setup'
end

namespace :deploy do
  after :finishing, "nginx:reload"
  after :finishing, "logrotate"
  after :restart, "unicorn:restart"
end
