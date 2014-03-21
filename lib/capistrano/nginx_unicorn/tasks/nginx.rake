namespace :nginx do
  desc "Setup nginx configuration for this application"
  task :setup do
    on roles(:web) do
      template("nginx_conf.erb", "/tmp/#{fetch(:application)}.conf")
      if fetch(:nginx_config_path) == "/etc/nginx/sites-available"
        execute "#{fetch(:sudo)} mv /tmp/#{fetch(:application)}.conf /etc/nginx/sites-available/#{fetch(:application)}.conf"
        execute "#{fetch(:sudo)} ln -fs /etc/nginx/sites-available/#{fetch(:application)}.conf /etc/nginx/sites-enabled/#{fetch(:application)}.conf"
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

  before :setup, 'nginx_unicorn:defaults'
  before :reload, 'nginx_unicorn:defaults'
end
