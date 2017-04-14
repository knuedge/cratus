require 'spec_helper'

describe Cratus::Group do
  subject do
    Cratus::Group
  end

  let(:search_filter) { /^\(cn=\w+\)$/ }

  let(:memberof_search_filter) { '(cn=test1)' }

  let(:search_filter2) { '(cn=test2)' }

  let(:find_all_filter) { '(cn=*)' }

  let(:fake_user) do
    instance_double(
      'Cratus::User',
      dn: 'uid=fakeuser,ou=users,dc=example,dc=com'
    )
  end

  let(:search_options) do
    {
      basedn: 'ou=groups,dc=example,dc=com',
      attrs: [
        Cratus.config.group_dn_attribute.to_s,
        Cratus.config.group_member_attribute.to_s,
        Cratus.config.group_description_attribute.to_s,
        Cratus.config.group_memberof_attribute.to_s
      ]
    }
  end

  let(:search_options_for_child_groups) do
    {
      basedn: 'cn=test1,ou=groups,dc=example,dc=com',
      scope: 'object',
      attrs: [
        Cratus.config.group_dn_attribute.to_s,
        Cratus.config.group_member_attribute.to_s,
        Cratus.config.group_description_attribute.to_s,
        Cratus.config.group_memberof_attribute.to_s
      ]
    }
  end

  let(:find_all_options) do
    {
      basedn: 'ou=groups,dc=example,dc=com',
      attrs: Cratus.config.group_dn_attribute.to_s
    }
  end

  let(:search_result) do
    [
      {
        dn: ['cn=test1,ou=groups,dc=example,dc=com'],
        cn: ['test1'],
        description: ['A Test Group'],
        member: [],
        memberOf: ['CN=test2,ou=groups,dc=example,dc=com']
      }
    ]
  end

  let(:search_result2) do
    [
      {
        dn: ['cn=test2,ou=groups,dc=example,dc=com'],
        cn: ['test2'],
        description: ['A Second Test Group'],
        member: ['cn=test1,ou=groups,dc=example,dc=com'],
        memberOf: []
      }
    ]
  end

  let(:search_result_with_member) do
    [
      {
        dn: ['cn=test2,ou=groups,dc=example,dc=com'],
        cn: ['test2'],
        description: ['Another Test Group'],
        member: ['uid=fakeuser,ou=users,dc=example,dc=com'],
        memberOf: []
      }
    ]
  end

  let(:find_all_results) do
    [
      {
        dn: ['cn=test1,ou=groups,dc=example,dc=com'],
        cn: ['test1'],
        description: ['A Test Group'],
        member: [],
        memberOf: ['cn=test2,ou=groups,dc=example,dc=com']
      },
      {
        dn: ['cn=test2,ou=groups,dc=example,dc=com'],
        cn: ['test2'],
        description: ['Another Test Group'],
        member: ['cn=test1,ou=groups,dc=example,dc=com'],
        memberOf: []
      }
    ]
  end

  context 'for a valid group' do
    it 'finds a valid group' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result)

      expect { subject.new('test1') }.not_to raise_error
    end

    it 'provides a group with expected attributes' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result)

      group = subject.new('test1')
      expect(group.dn).to eq('cn=test1,ou=groups,dc=example,dc=com')
      expect(group.description).to eq('A Test Group')
      expect(group.members).to eq([])
    end

    it 'provides a list of parent groups' do
      allow(Cratus::LDAP)
        .to receive(:search).with(memberof_search_filter, search_options)
        .and_return(search_result)
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter2, search_options)
        .and_return(search_result2)

      child = subject.new('test1')
      expect(child.member_of).to eq([subject.new('test2')])
    end

    it 'provides a list of child groups' do
      allow(Cratus::LDAP)
        .to receive(:search).with('(objectClass=group)', search_options_for_child_groups)
        .and_return(search_result)
      allow(Cratus::LDAP)
        .to receive(:search).with(memberof_search_filter, search_options)
        .and_return(search_result)
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter2, search_options)
        .and_return(search_result2)
      allow(Cratus::LDAP)
        .to receive(:search).with('(objectClass=user)', anything)
        .and_return([])

      parent = subject.new('test2')
      expect(parent.member_groups).to eq([subject.new('test1')])
    end

    it 'allows adding a user' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result)
      allow(Cratus::LDAP)
        .to receive(:replace_attribute)
        .with(
          'cn=test1,ou=groups,dc=example,dc=com',
          Cratus.config.group_member_attribute,
          [fake_user.dn]
        )
        .and_return(true)

      group = subject.new('test1')
      # Adding should return true
      expect(group.add_user(fake_user)).to eq(true)
      # Raw LDAP cache should contain the new user's dn
      #   Cheaper way of determining if it worked, rather than mocking actual users
      expect(group.instance_variable_get(:'@raw_ldap_data')[:member])
        .to eq(['uid=fakeuser,ou=users,dc=example,dc=com'])
    end

    it 'allows removing a member' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result_with_member)
      allow(Cratus::LDAP)
        .to receive(:replace_attribute)
        .with(
          'cn=test2,ou=groups,dc=example,dc=com',
          Cratus.config.group_member_attribute,
          []
        )
        .and_return(true)

      group = subject.new('test2')
      # Removing should return true
      expect(group.remove_user(fake_user)).to eq(true)
      # Raw LDAP cache for members should be empty
      expect(group.instance_variable_get(:'@raw_ldap_data')[:member]).to eq([])
    end
  end

  context 'for an invalid group' do
    it 'finding raises an exception' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_raise(Cratus::Exceptions::FailedLDAPSearch)

      expect { subject.new('foobaz') }.to raise_error(Cratus::Exceptions::FailedLDAPSearch)
    end
  end

  it 'finds all groups' do
    allow(Cratus::LDAP)
      .to receive(:search).with(find_all_filter, find_all_options)
      .and_return(find_all_results)
    allow(Cratus::LDAP)
      .to receive(:search).with(search_filter, search_options)
      .and_return(search_result)

    expect { subject.all }.not_to raise_error
    list = subject.all
    expect(list.size).to eq(find_all_results.size)
    expect(list.first).to eq(subject.new('test1'))
    expect(list.first.description).to eq('A Test Group')
  end
end
