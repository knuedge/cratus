module Cratus
  class Group
    attr_reader :name, :search_base

    def initialize(name, search_base)
      @name = name
      @search_base = search_base
      @raw_ldap_data = Cratus::LDAP.search(
        "(cn=#{@name})",
        basedn: @search_base,
        attrs: ['member', 'description']
      ).last
    end

    # LDAP users that are a member of this group
    def members
      @raw_ldap_data[:member]
    end

    # LDAP description attribute
    def description
      @raw_ldap_data[:description].last
    end

    # All the LDAP Groups
    def self.all(search_base)
      Cratus::LDAP.search('(cn=*)', basedn: search_base, attrs: 'cn').map do |entry|
        self.new(entry[:cn].last, search_base)
      end
    end
  end
end
