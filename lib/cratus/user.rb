module Cratus
  class User
    attr_reader :username, :search_base

    def initialize(username, search_base)
      @username = username
      @search_base = search_base
      @raw_ldap_data = Cratus::LDAP.search(
        "(#{self.class.ldap_dn_attribute}=#{@username})",
        basedn: @search_base,
        attrs: self.class.ldap_return_attributes
      ).last
    end

    def department
      @raw_ldap_data[:department].last
    end

    def email
      @raw_ldap_data[:mail].last
    end

    def fullname
      @raw_ldap_data[:displayname].last
    end

    # All the LDAP Users
    def self.all(search_base)
      raw_results = Cratus::LDAP.search(
        "(objectClass=#{ldap_object_class})",
        basedn: search_base,
        attrs: ldap_dn_attribute
      )
      raw_results.map do |entry|
        self.new(entry[ldap_dn_attribute.to_sym].last, search_base)
      end
    end

    def self.ldap_dn_attribute
      # TODO: Make this configurable
      'samaccountname'
    end

    def self.ldap_object_class
      'user'
    end

    def self.ldap_return_attributes
      ['department', 'mail', 'displayName']
    end
  end
end
