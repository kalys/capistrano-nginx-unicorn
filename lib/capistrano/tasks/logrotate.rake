namespace :logrotate do
  desc "Setup logs rotation for nginx and unicorn"
  task :setup do
    on roles(:web, :app) do
      logrotate_config = "#{fetch(:application)}_#{fetch(:stage)}"
      next if file_exists? "/etc/logrotate.d/#{logrotate_config}"

      template("logrotate.erb", "/tmp/#{logrotate_config}_logrotate")
      sudo :mv, "/tmp/#{logrotate_config}_logrotate /etc/logrotate.d/#{logrotate_config}"
      sudo :chown, "root:root", "/etc/logrotate.d/#{logrotate_config}"
    end
  end
end

namespace :deploy do
  after :started, "logrotate:setup"
end
