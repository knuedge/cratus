module Cratus
  # An LDAP User representation
  class User
    include Comparable
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

    def dn
      @raw_ldap_data[:dn].last
    end

    def email
      @raw_ldap_data[Cratus.config.user_mail_attribute].last
    end

    def fullname
      @raw_ldap_data[Cratus.config.user_displayname_attribute].last
    end

    def lockouttime
      Integer(@raw_ldap_data[Cratus.config.user_lockout_attribute].last.to_s)
    end

    # https://fossies.org/linux/web2ldap/pylib/w2lapp/schema/plugins/activedirectory.py
    # https://msdn.microsoft.com/en-us/library/windows/desktop/ms676843(v=vs.85).aspx
    #
    def locked?
      return false if lockouttime == 0
      epoch = 116_444_736_000_000_000
      current = Time.now.to_i * 10_000_000
      current - (lockouttime - epoch) < lockoutduration
    end

    def lockoutduration
      raw_results = Cratus::LDAP.search(
        '(objectClass=domain)',
        basedn: Cratus.config.basedn,
        attrs: 'lockoutDuration',
        scope: 'object'
      ).last
      Integer(raw_results[:lockoutduration].last) * -1
    end

    def member_of
      memrof_attr = Cratus.config.user_memberof_attribute
      # TODO: move the search filter to a configurable param
      raw_groups = @raw_ldap_data[memrof_attr].reject { |g| g.match(/OU=Distribution Groups/) }
      initial_groups = raw_groups.map do |raw_group|
        Group.new(raw_group.match(/^#{Group.ldap_dn_attribute.to_s.upcase}=([^,]+),/)[1])
      end
      all_the_groups = initial_groups
      initial_groups.each do |group|
        all_the_groups.concat(group.member_of)
      end
      all_the_groups.uniq(&:name)
    end

    alias groups member_of

    def <=>(other)
      @username <=> other.username
    end

    # All the LDAP Users
    def self.all
      raw_results = Cratus::LDAP.search(
        "(objectClass=#{ldap_object_class})",
        basedn: ldap_search_base,
        attrs: ldap_dn_attribute
      )
      raw_results.map do |entry|
        new(entry[ldap_dn_attribute.to_sym].last)
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
        Cratus.config.user_dn_attribute.to_s,
        Cratus.config.user_department_attribute.to_s,
        Cratus.config.user_mail_attribute.to_s,
        Cratus.config.user_displayname_attribute.to_s,
        Cratus.config.user_memberof_attribute.to_s,
        Cratus.config.user_lockout_attribute.to_s
      ]
    end

    def self.ldap_search_base
      Cratus.config.user_basedn.to_s
    end
  end
end
