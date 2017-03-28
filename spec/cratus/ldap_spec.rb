require 'spec_helper'

describe Cratus::LDAP do
  subject do
    Cratus::LDAP
  end

  let(:netldap_search) do
    {
      base: 'ou=users,dc=example,dc=com',
      filter: '(uid=foo*)',
      scope: 2,
      attributes: %w(uid displayname department samaccountname lockouttime)
    }
  end

  let(:cratus_search) do
    {
      attrs: %i(uid displayname department samaccountname lockouttime),
      basedn: 'ou=users,dc=example,dc=com'
    }
  end

  let(:search_result) do
    [
      {
        dn: ['uid=foobar,ou=users,dc=example,dc=com'],
        uid: ['foobar'],
        displayname: ['Foo Bar'],
        department: ['IT'],
        samaccountname: ['foobar'],
        lockouttime: ['0']
      }
    ]
  end

  let(:ldap_instance) do
    ldap = instance_double('Net::LDAP', bind: true)
    allow(ldap).to receive(:search).and_return(nil)
    allow(ldap).to receive(:search).with(netldap_search).and_return(search_result)
    ldap
  end

  it 'is not connected by default' do
    expect(subject.connected?).to be_nil
  end

  it 'establishes a connection' do
    allow(Net::LDAP).to receive(:new).and_return(ldap_instance)
    expect(subject.connect).to eq(true)
    expect(subject.connected?).to eq(true)
    # Put things back how we found them...
    subject.instance_variable_set(:'@ldap_connection', nil)
  end

  it 'allows searching' do
    allow(Net::LDAP).to receive(:new).and_return(ldap_instance)
    expect(subject.connect).to eq(true)
    expect(subject.search('(uid=foo*)', cratus_search)).to eq(search_result)
    # Put things back how we found them...
    subject.instance_variable_set(:'@ldap_connection', nil)
  end

  it 'raises an exception on a bad search' do
    allow(Net::LDAP).to receive(:new).and_return(ldap_instance)
    expect(subject.connect).to eq(true)
    expect do
      subject.search('(uid=baz*)', cratus_search)
    end.to raise_error(Cratus::Exceptions::FailedLDAPSearch)
    # Put things back how we found them...
    subject.instance_variable_set(:'@ldap_connection', nil)
  end
end
