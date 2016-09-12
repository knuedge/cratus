module Cratus
  module LDAP
    def self.connection(options = {})
      validate_connection_options(options)
      @@ldap_connection ||= Net::LDAP.new(
        host: options[:host],
        port: options[:port],
        base: options[:basedn],
        auth: {
          method: :simple,
          username: options[:username],
          password: options[:password]
        }
      )
    end

    def self.validate_connection_options(options)
      raise "Invalid Options" unless options.respond_to?(:key?)

      [:host, :port, :basedn, :username, :password].each do |key|
        raise "Missing Option: #{key}" unless options.key?(key)
      end
    end
  end
end
