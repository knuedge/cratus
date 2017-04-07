module Cratus
  # An LDAP User representation
  class User
    include Comparable
    attr_reader :username, :search_base

    def initialize(username)
      @username = username
      @search_base = self.class.ldap_search_base
      refresh
    end

    # Add a user to a group
    def add_to_group(group)
      raise 'InvalidGroup' unless group.respond_to?(:add_user)
      # just be lazy and hand off to the group to do the work...
      group.add_user(self)
    end

    # Remove a user from a group
    def remove_from_group(group)
      raise 'InvalidGroup' unless group.respond_to?(:remove_user)
      # just be lazy and hand off to the group to do the work...
      group.remove_user(self)
    end

    def department
      @raw_ldap_data[Cratus.config.user_department_attribute].last
    end

    # Disables an enabled user
    def disable
      if enabled?
        Cratus::LDAP.replace_attribute(
          dn,
          Cratus.config.user_account_control_attribute,
          ['514']
        )
        refresh
      else
        true
      end
    end

    def disabled?
      status = @raw_ldap_data[Cratus.config.user_account_control_attribute].last
      status.to_s == '514'
    end

    def dn
      @raw_ldap_data[:dn].last
    end

    def email
      @raw_ldap_data[Cratus.config.user_mail_attribute].last
    end

    # Enables a disabled user
    def enable
      if disabled?
        Cratus::LDAP.replace_attribute(
          dn,
          Cratus.config.user_account_control_attribute,
          ['512']
        )
        refresh
      else
        true
      end
    end

    def enabled?
      status = @raw_ldap_data[Cratus.config.user_account_control_attribute].last
      status.to_s == '512'
    end

    def fullname
      @raw_ldap_data[Cratus.config.user_displayname_attribute].last
    end

    def lockouttime
      Integer(@raw_ldap_data[Cratus.config.user_lockout_attribute].last.to_s)
    rescue => _e
      0 # If we can't determine the value (for instance, if it is empty), just assume 0
    end

    # https://fossies.org/linux/web2ldap/pylib/w2lapp/schema/plugins/activedirectory.py
    # https://msdn.microsoft.com/en-us/library/windows/desktop/ms676843(v=vs.85).aspx
    #
    def locked?
      return false if lockouttime.zero?
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
      if Cratus.config.include_distribution_groups
        raw_groups = @raw_ldap_data[memrof_attr]
      else
        raw_groups = @raw_ldap_data[memrof_attr].reject { |g| g.match(/OU=Distribution Groups/) }
      end
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

    def refresh
      @raw_ldap_data = Cratus::LDAP.search(
        "(#{self.class.ldap_dn_attribute}=#{@username})",
        basedn: @search_base,
        attrs: self.class.ldap_return_attributes
      ).last
    end

    # Unlocks a user
    # @return `true` on success (or if user is already unlocked)
    # @return `false` when the account is disabled (unlocking not permitted)
    def unlock
      if locked? && enabled?
        Cratus::LDAP.replace_attribute(
          dn,
          Cratus.config.user_lockout_attribute,
          ['0']
        )
        refresh
      elsif disabled?
        false
      else
        true
      end
    end

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
        Cratus.config.user_lockout_attribute.to_s,
        Cratus.config.user_account_control_attribute.to_s
      ]
    end

    def self.ldap_search_base
      Cratus.config.user_basedn.to_s
    end
  end
end
