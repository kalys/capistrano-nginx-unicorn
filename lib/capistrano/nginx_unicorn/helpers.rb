require 'erb'

module Capistrano
  module NginxUnicorn
    module Helpers

      def template(template_name, target)
        config_file = "#{fetch(:templates_path)}/#{template_name}"
        # if no customized file, proceed with default
        unless File.exists?(config_file)
          config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/nginx_unicorn/templates/#{template_name}")
        end
        config_stream = StringIO.new(ERB.new(File.read(config_file)).result(binding))
        upload! config_stream, target
      end

    end
  end
end
