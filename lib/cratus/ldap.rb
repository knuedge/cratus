module Cratus
  module LDAP
    def self.connection(options = {})
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
  end
end
