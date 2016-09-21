module Cratus
  class User
    attr_reader :username, :search_base

    def initialize(username)
      @username = username
      @search_base = self.class.ldap_search_base
      @raw_ldap_data = Cratus::LDAP.search(
        "(#{self.class.ldap_dn_attribute}=#{@username})",
        basedn: @search_base,
        attrs: self.class.ldap_return_attributes
      ).last
    end

    def department
      @raw_ldap_data[Cratus.config.user_department_attribute].last
    end

    def email
      @raw_ldap_data[Cratus.config.user_mail_attribute].last
    end

    def fullname
      @raw_ldap_data[Cratus.config.user_displayname_attribute].last
    end

    def member_of
      memrof_attr = Cratus.config.user_memberof_attribute
      # TODO: move the search filter to a configurable param
      @raw_ldap_data[memrof_attr].reject {|g| g.match /OU=Distribution Groups/ }.map do |raw_group|
        Group.new(raw_group.match(/^#{Group.ldap_dn_attribute.to_s.upcase}=([^,]+),/)[1])
      end
    end

    # All the LDAP Users
    def self.all
      raw_results = Cratus::LDAP.search(
        "(objectClass=#{ldap_object_class})",
        basedn: ldap_search_base,
        attrs: ldap_dn_attribute
      )
      raw_results.map do |entry|
        self.new(entry[ldap_dn_attribute.to_sym].last, search_base)
      end
    end

    def self.ldap_dn_attribute
      Cratus.config.user_dn_attribute.to_s
    end

    def self.ldap_object_class
      Cratus.config.user_objectclass.to_s
    end

    def self.ldap_return_attributes
      [
        Cratus.config.user_department_attribute.to_s,
        Cratus.config.user_mail_attribute.to_s,
        Cratus.config.user_displayname_attribute.to_s,
        Cratus.config.user_memberof_attribute.to_s
      ]
    end

    def self.ldap_search_base
      Cratus.config.user_basedn.to_s
    end
  end
end
