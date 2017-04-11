require 'spec_helper'

describe Cratus::User do
  subject do
    Cratus::User
  end

  let(:search_filter) { /^\(samaccountname=\w+\)$/ }

  let(:find_all_filter) { '(objectClass=user)' }

  let(:fake_group) do
    instance_double(
      'Cratus::Group',
      dn: 'CN=fakegroup,ou=groups,dc=example,dc=com',
      name: 'fakegroup',
      add_user: true,
      remove_user: true,
      member_of: []
    )
  end

  let(:fake_distro) do
    instance_double(
      'Cratus::Group',
      dn: 'CN=fakedistro,ou=groups,dc=example,dc=com',
      name: 'fakedistro',
      add_user: true,
      remove_user: true,
      member_of: []
    )
  end

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

  let(:lockoutduration_search_options) do
    {
      basedn: 'dc=example,dc=com',
      attrs: 'lockoutDuration',
      scope: 'object'
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

  let(:search_result_with_groups) do
    [
      {
        dn: ['samaccountname=foobar,ou=users,dc=example,dc=com'],
        mail: ['foobar@example.com'],
        displayName: ['Foo Bar'],
        department: ['IT'],
        samaccountname: ['foobar'],
        memberOf: [
          'CN=fakegroup,ou=groups,dc=example,dc=com',
          'CN=fakedistro,OU=Distribution Groups,ou=groups,dc=example,dc=com'
        ],
        useraccountcontrol: ['512']
      }
    ]
  end

  let(:lockoutduration_search_result) do
    # Assumes a 15 minute lockout duration
    [
      {
        dn: ['dc=example,dc=com'],
        lockoutduration: [(-1 * 15 * 60 * 10_000_000).to_s]
      }
    ]
  end

  let(:locked_search_result) do
    [
      {
        dn: ['samaccountname=foobar,ou=users,dc=example,dc=com'],
        mail: ['foobar@example.com'],
        displayName: ['Foo Bar'],
        department: ['IT'],
        samaccountname: ['foobar'],
        lockouttime: [
          (((Time.now.to_i - 300) * 10_000_000) + 116_444_736_000_000_000).to_s
        ],
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

  context 'with a valid user' do
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

    it 'adds a user to a group' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result)

      user = subject.new('foobar')
      expect(user.add_to_group(fake_group)).to eq(true)
    end

    it 'removes a user to a group' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result)

      user = subject.new('foobar')
      expect(user.remove_from_group(fake_group)).to eq(true)
    end

    it 'determines if a user is locked' do
      allow(Cratus::LDAP)
        .to receive(:search).with('(objectClass=domain)', lockoutduration_search_options)
        .and_return(lockoutduration_search_result)
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(locked_search_result)

      user = subject.new('foobar')
      expect(user.locked?).to eq(true)
    end

    it 'ignores distribution group memberships when told to' do
      old = Cratus.config.include_distribution_groups
      Cratus.config.include_distribution_groups = false

      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result_with_groups)
      allow(Cratus::Group).to receive(:new).with('fakegroup')
        .and_return(fake_group)
      allow(Cratus::Group).to receive(:new).with('fakedistro')
        .and_return(fake_distro)

      expect(subject.new('foobar').groups.size).to eq(1)
      expect(subject.new('foobar').groups.first.name).to eq('fakegroup')

      # put things back how we found them
      Cratus.config.include_distribution_groups = old
    end

    it 'corrects for a missing lockouttime attribute' do
      allow(Cratus::LDAP)
        .to receive(:search).with(search_filter, search_options)
        .and_return(search_result_with_groups)

      user = subject.new('foobar')
      expect(user.locked?).to eq(false)
    end

    context 'with an invalid group' do
      it 'adding to a group raises an exception' do
        allow(Cratus::LDAP)
          .to receive(:search).with(search_filter, search_options)
          .and_return(search_result)

        user = subject.new('foobar')
        expect { user.add_to_group('a') }.to raise_error('InvalidGroup')
      end

      it 'removing from a group raises an exception' do
        allow(Cratus::LDAP)
          .to receive(:search).with(search_filter, search_options)
          .and_return(search_result)

        user = subject.new('foobar')
        expect { user.remove_from_group('a') }.to raise_error('InvalidGroup')
      end
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
