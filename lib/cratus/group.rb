module Cratus
  class Group
    attr_reader :name, :search_base

    def initialize(name)
      @name = name
      @search_base = self.class.ldap_search_base
      @raw_ldap_data = Cratus::LDAP.search(
        "(#{self.class.ldap_dn_attribute}=#{@name})",
        basedn: @search_base,
        attrs: self.class.ldap_return_attributes
      ).last
    end

    # LDAP users that are a member of this group
    def members
      @raw_ldap_data[Cratus.config.group_member_attribute]
    end

    # LDAP description attribute
    def description
      @raw_ldap_data[Cratus.config.group_description_attribute].last
    end

    # All the LDAP Groups
    def self.all
      filter = "(#{ldap_dn_attribute}=*)"
      Cratus::LDAP.search(filter, basedn: ldap_search_base, attrs: ldap_dn_attribute).map do |entry|
        self.new(entry[ldap_dn_attribute].last)
      end
    end

    def self.ldap_dn_attribute
      Cratus.config.group_dn_attribute.to_s
    end

    def self.ldap_object_class
      Cratus.config.group_objectclass.to_s
    end

    def self.ldap_return_attributes
      [
        Cratus.config.group_member_attribute.to_s,
        Cratus.config.group_description_attribute.to_s
      ]
    end

    def self.ldap_search_base
      Cratus.config.group_basedn.to_s
    end
  end
end
