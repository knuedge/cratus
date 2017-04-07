require 'spec_helper'

describe Cratus::User do
  subject do
    Cratus::User
  end

  let(:search_filter) { /^\(samaccountname=\w+\)$/ }

  let(:find_all_filter) { '(objectClass=user)' }

  let(:search_options) do
    {
      basedn: 'ou=users,dc=example,dc=com',
      attrs: [
        Cratus.config.user_dn_attribute.to_s,
        Cratus.config.user_department_attribute.to_s,
        Cratus.config.user_mail_attribute.to_s,
        Cratus.config.user_displayname_attribute.to_s,
        Cratus.config.user_memberof_attribute.to_s,
        Cratus.config.user_lockout_attribute.to_s,
        Cratus.config.user_account_control_attribute.to_s
      ]
    }
  end

  let(:find_all_options) do
    {
      basedn: 'ou=users,dc=example,dc=com',
      attrs: Cratus.config.user_dn_attribute.to_s
    }
  end

  let(:search_result) do
    [
      {
        dn: ['samaccountname=foobar,ou=users,dc=example,dc=com'],
        mail: ['foobar@example.com'],
        displayName: ['Foo Bar'],
        department: ['IT'],
        samaccountname: ['foobar'],
        lockouttime: ['0'],
        memberOf: [],
        useraccountcontrol: ['512']
      }
    ]
  end

  let(:find_all_results) do
    [
      {
        dn: ['samaccountname=foobar,ou=users,dc=example,dc=com'],
        mail: ['foobar@example.com'],
        displayName: ['Foo Bar'],
        department: ['IT'],
        samaccountname: ['foobar'],
        lockouttime: ['0'],
        memberOf: [],
        useraccountcontrol: ['512']
      },
      {
        dn: ['samaccountname=binbaz,ou=users,dc=example,dc=com'],
        mail: ['binbaz@example.com'],
        displayName: ['Bin Baz'],
        department: ['IT'],
        samaccountname: ['binbaz'],
        lockouttime: ['0'],
        memberOf: [],
        useraccountcontrol: ['512']
      }
    ]
  end

  context 'for a valid user' do
    it 'finds a valid user' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result)

      expect { subject.new('foobar') }.not_to raise_error
    end

    it 'provides a user with expected attributes' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result)

      user = subject.new('foobar')
      expect(user.department).to eq('IT')
      expect(user.dn).to eq('samaccountname=foobar,ou=users,dc=example,dc=com')
      expect(user.email).to eq('foobar@example.com')
      expect(user.fullname).to eq('Foo Bar')
      expect(user.locked?).to be false
      expect(user.groups).to eq([])
    end
  end

  context 'for an invalid user' do
    it 'finding raises an exception' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_raise(Cratus::Exceptions::FailedLDAPSearch)

      expect { subject.new('foobaz') }.to raise_error(Cratus::Exceptions::FailedLDAPSearch)
    end
  end

  it 'finds all users' do
    allow(Cratus::LDAP)
      .to receive(:search).with(find_all_filter, find_all_options)
      .and_return(find_all_results)
    allow(Cratus::LDAP)
      .to receive(:search).with(search_filter, search_options)
      .and_return(search_result)

    expect { subject.all }.not_to raise_error
    list = subject.all
    expect(list.size).to eq(find_all_results.size)
    expect(list.first.email).to eq('foobar@example.com')
  end
end
