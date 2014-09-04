set :templates_path, "config/deploy/templates"
set :nginx_server_name, -> { "localhost #{fetch(:application)}.local" }
set :nginx_config_name, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
set :nginx_use_ssl, false
set :nginx_pid, "/run/nginx.pid"
set :nginx_ssl_certificate, -> { "#{fetch(:nginx_server_name)}.crt" }
set :nginx_ssl_certificate_key, -> { "#{fetch(:nginx_server_name)}.key" }
set :nginx_upload_local_certificate, true
set :nginx_ssl_certificate_local_path, -> { ask(:nginx_ssl_certificate_local_path, "Local path to ssl certificate: ") }
set :nginx_ssl_certificate_key_local_path, -> { ask(:nginx_ssl_certificate_key_local_path, "Local path to ssl certificate key: ") }
set :nginx_config_path, "/etc/nginx/sites-available"

set :unicorn_service_name, -> { "unicorn_#{fetch(:application)}_#{fetch(:stage)}" }
set :unicorn_pid, -> { shared_path.join("pids/unicorn.pid") }
set :unicorn_config, -> { shared_path.join("config/unicorn.rb") }
set :unicorn_log, -> { shared_path.join("log/unicorn.log") }
set :unicorn_user, -> { fetch(:user) }
set :unicorn_workers, 2
set :sudo, "sudo"
