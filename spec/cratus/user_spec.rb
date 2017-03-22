require 'spec_helper'

describe Cratus::User do
  subject do
    Cratus::User
  end

  let(:search_filter) { '(samaccountname=foobar)' }

  let(:search_options) do
    {
      basedn: 'ou=users,dc=example,dc=com',
      attrs: [
        Cratus.config.user_dn_attribute.to_s,
        Cratus.config.user_department_attribute.to_s,
        Cratus.config.user_mail_attribute.to_s,
        Cratus.config.user_displayname_attribute.to_s,
        Cratus.config.user_memberof_attribute.to_s,
        Cratus.config.user_lockout_attribute.to_s
      ]
    }
  end

  let(:search_result) do
    [
      {
        dn: ['samaccountname=foobar,ou=users,dc=example,dc=com'],
        mail: ['foobar@example.com'],
        displayname: ['Foo Bar'],
        department: ['IT'],
        samaccountname: ['foobar'],
        lockouttime: ['0']
      }
    ]
  end

  it 'finds a valid user' do
    allow(Cratus::LDAP)
      .to receive(:search).with(search_filter, search_options)
      .and_return(search_result)
    expect { subject.new('foobar') }.not_to raise_error
    expect(subject.new('foobar').email).to eq('foobar@example.com')
  end
end
