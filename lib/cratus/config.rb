module Cratus
  # A generic way of constructing a mergeable configuration
  #   rubocop:disable Metrics/MethodLength
  class Config < OpenStruct
    # A Hash of the default configuration options
    def defaults
      {
        group_dn_attribute: :cn,
        group_member_attribute: :member,
        group_description_attribute: :description,
        group_objectclass: :group,
        group_basedn: 'ou=groups,dc=example,dc=com',
        group_memberof_attribute: :memberOf,
        user_dn_attribute: :samaccountname,
        user_objectclass: :user,
        user_basedn: 'ou=users,dc=example,dc=com',
        user_account_control_attribute: :userAccountControl,
        user_department_attribute: :department,
        user_lockout_attribute: :lockouttime,
        user_mail_attribute: :mail,
        user_displayname_attribute: :displayName,
        user_memberof_attribute: :memberOf,
        host: 'ldap.example.com', port: 389,
        basedn: 'dc=example,dc=com',
        username: 'username',
        password: 'p@assedWard!',
        include_distribution_groups: true
      }
    end

    # Construct a base config using the following order of precedence:
    #   * environment variables
    #   * YAML file
    #   * defaults
    def load
      # First, apply the defaults
      merge defaults

      # Then apply the config file, if one exists
      begin
        apprc_dir = File.expand_path('~')
        config_file = File.expand_path(File.join(apprc_dir, '.cratus.yml'))
        merge YAML.load_file(config_file) if File.readable?(config_file)
      rescue => e
        puts "WARNING: Unable to read from #{config_file}: #{e.message}"
      end

      # Finally, apply any environment variables specified
      env_conf = {}
      defaults.keys.each do |key|
        cratus_key = "CRATUS_#{key}".upcase
        env_conf[key] = ENV[cratus_key] if ENV.key?(cratus_key)
      end
      merge env_conf unless env_conf.empty?
    end

    def merge(data)
      raise 'Invalid Config Data' unless data.is_a?(Hash)
      data.each do |k, v|
        self[k.to_sym] = v
      end
    end
  end
end

# Make the config available as a singleton
module Cratus
  class << self
    def config
      @config ||= Config.new
    end
  end
end
