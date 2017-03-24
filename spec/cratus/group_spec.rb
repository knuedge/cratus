require 'spec_helper'

describe Cratus::Group do
  subject do
    Cratus::Group
  end

  let(:search_filter) { /^\(cn=\w+\)$/ }

  let(:find_all_filter) { '(cn=*)' }

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
        memberOf: ['cn=test2,ou=groups,dc=example,dc=com']
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
