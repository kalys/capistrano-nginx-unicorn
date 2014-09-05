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
set :nginx_client_body_buffer_size, "10K"
set :nginx_client_header_buffer_size, "1K"
set :nginx_client_max_body_size, "4G"
set :nginx_large_client_header_buffers, "2 1K"
set :nginx_client_body_timeout, "12"
set :nginx_client_header_timeout, "12"
set :nginx_keepalive_timeout, "10"
set :nginx_send_timeout, "10"
set :nginx_gzip, "on"
set :nginx_gzip_comp_level, "2"
set :nginx_gzip_min_length, "1000"
set :nginx_gzip_proxied, "expired no-cache no-store private auth"
set :nginx_gzip_types, "text/plain application/x-javascript text/xml text/css application/xml"

set :unicorn_service_name, -> { "unicorn_#{fetch(:application)}_#{fetch(:stage)}" }
set :unicorn_pid, -> { shared_path.join("pids/unicorn.pid") }
set :unicorn_config, -> { shared_path.join("config/unicorn.rb") }
set :unicorn_log, -> { shared_path.join("log/unicorn.log") }
set :unicorn_user, -> { fetch(:user) }
set :unicorn_workers, 2
set :sudo, "sudo"
