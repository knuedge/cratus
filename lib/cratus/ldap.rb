module Cratus
  module LDAP
    # Define the LDAP connection
    # Note: does not actually connect (bind), just sets up the connection
    def self.connection
      options = {
        host: Cratus.config.host,
        port: Cratus.config.port,
        base: Cratus.config.basedn,
        auth: {
          method: :simple,
          username: Cratus.config.username,
          password: Cratus.config.password
        }
      }
      # TODO: make the validations do something useful
      #validate_connection_options(options)
      @@ldap_connection ||= Net::LDAP.new(options)
    end

    # Actually connect (bind) to LDAP
    def self.connect
      connection
      validate_ldap_connection
      @@ldap_connection.bind
      @@ldap_bound = true
    end

    # Perform an LDAP search
    #
    # Required Options: :basedn
    # Optional Options: :attrs, :scope
    def self.search(filter, options = {})
      validate_ldap_connection
      validate_ldap_bound
      validate_search_options(options)

      attrs = options.key?(:attrs) ? options[:attrs] : []
      scope = options.key?(:scope) ? options[:scope] : 'subtree'

      scope_class = case scope.to_s
                    when 'subtree','recursive','whole_subtree'
                      Net::LDAP::SearchScope_WholeSubtree
                    when 'single','single_level'
                      Net::LDAP::SearchScope_SingleLevel
                    when 'object','base_object'
                      Net::LDAP::SearchScope_BaseObject
                    else
                      fail "Invalid LDAP Scope!"
                    end

      results = @@ldap_connection.search(
        base: options[:basedn],
        filter: filter,
        scope: scope_class,
        attributes: [*attrs].map(&:to_s)
      )
      raise "Search Failed" if results.nil?
      results.compact
    end

    # Validation Methods

    def self.validate_ldap_bound
      raise "LDAP Not Connected" unless defined? @@ldap_bound
    end

    def self.validate_ldap_connection
      raise "No LDAP Connection" unless defined? @@ldap_connection
    end

    def self.validate_search_options(options)
      raise "Invalid Options" unless options.respond_to?(:key?)

      [:basedn].each do |key|
        raise "Missing Option: #{key}" unless options.key?(key)
      end
    end

    def self.validate_connection_options(options)
      raise "Invalid Options" unless options.respond_to?(:key?)

      [:host, :port, :basedn, :username, :password].each do |key|
        raise "Missing Option: #{key}" unless options.key?(key)
      end
    end
  end
end
