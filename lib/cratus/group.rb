module Cratus
  # An LDAP Group representation
  class Group
    include Comparable
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
      all_members[:users]
    end

    def member_groups
      all_members[:groups]
    end

    # Recursively determine group memberships of a group
    def member_of
      memrof_attr = Cratus.config.group_memberof_attribute

      # TODO: make this work with more things...
      unless @raw_ldap_data
        STDERR.puts "WARNING: Group '#{@name}' appears to be invalid or beyond the search scope!"
        return []
      end

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
        all_the_groups.concat(group.member_of) # recursion!
      end
      all_the_groups.uniq(&:name)
    end

    # Returns the LDAP dn for a Group
    def dn
      @raw_ldap_data[:dn].last
    end

    # LDAP description attribute
    def description
      @raw_ldap_data[Cratus.config.group_description_attribute].last
    end

    # Add a User to the group
    def add_user(user)
      raise 'InvalidUser' unless user.respond_to?(:dn)
      direct_members = @raw_ldap_data[Cratus.config.group_member_attribute]
      return true if direct_members.include?(user.dn)

      direct_members << user.dn
      Cratus::LDAP.replace_attribute(
        dn,
        Cratus.config.group_member_attribute,
        direct_members.uniq
      )
    end

    # Remove a User from the group
    def remove_user(user)
      raise 'InvalidUser' unless user.respond_to?(:dn)
      direct_members = @raw_ldap_data[Cratus.config.group_member_attribute]
      return true unless direct_members.include?(user.dn)

      direct_members.delete(user.dn)
      Cratus::LDAP.replace_attribute(
        dn,
        Cratus.config.group_member_attribute,
        direct_members.uniq
      )
    end

    # All the LDAP Groups
    def self.all
      filter = "(#{ldap_dn_attribute}=*)"
      Cratus::LDAP.search(filter, basedn: ldap_search_base, attrs: ldap_dn_attribute).map do |entry|
        new(entry[ldap_dn_attribute.to_sym].last)
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
        Cratus.config.group_dn_attribute.to_s,
        Cratus.config.group_member_attribute.to_s,
        Cratus.config.group_description_attribute.to_s,
        Cratus.config.group_memberof_attribute.to_s
      ]
    end

    def self.ldap_search_base
      Cratus.config.group_basedn.to_s
    end

    # Compare based on the group's name
    # TODO: possibly change to dn
    def <=>(other)
      @name <=> other.name
    end

    private

    # provides a Hash of member users and groups
    #   rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def all_members
      # filters used to determine if each group member is a User or Group
      group_filter = "(objectClass=#{Cratus.config.group_objectclass})"
      user_filter  = "(objectClass=#{Cratus.config.user_objectclass})"

      # The raw LDAP data (a list of DNs)
      raw_members = @raw_ldap_data[Cratus.config.group_member_attribute]

      # Somewhere to store users and groups as we gather them
      results = { users: [], groups: [] }

      # Iterate over the members and provide a user or group
      raw_members.each do |member|
        user_result = Cratus::LDAP.search(
          user_filter,
          basedn: member,
          scope: 'object',
          attrs: User.ldap_return_attributes
        )

        if !user_result.nil? && !user_result.empty?
          results[:users] << User.new(user_result.last[User.ldap_dn_attribute.to_sym].last)
        else
          group_result = Cratus::LDAP.search(
            group_filter,
            basedn: member,
            scope: 'object',
            attrs: self.class.ldap_return_attributes
          )
          unless group_result.nil? || group_result.empty?
            nested_group = Group.new(group_result.last[self.class.ldap_dn_attribute.to_sym].last)
            results[:groups] << nested_group
            results[:groups].concat(nested_group.member_groups)
            results[:users].concat(nested_group.members)
          end
        end
      end

      # deliver the results
      results[:groups].uniq!(&:name)
      results[:users].uniq!(&:username)
      results
    end
  end
end
