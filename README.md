# Cratus

[![Gem Version](https://badge.fury.io/rb/cratus.svg)](https://rubygems.org/gems/cratus)

## What is Cratus?

Cratus is a simple library, primarily used by [KnuEdge](https://www.knuedge.com) to query, report on, and manage Active Directory users and groups via LDAP. The intention is to simplify this interaction and modularize it for use across several of our tools. We've open-sourced it because we think it might be useful to others, and to give back to the community from whence all of its capabilities are derived.

## Why Cratus?

Why not just use `Net::LDAP`? Well, in fact, this library does use `Net::LDAP`, but does so making some assumptions based on how we (and arguably most people) use LDAP with Active Directory. By building linkages between users and groups, baking in recursion (supporting so-called nested groups), and making just the right things configurable, Cratus provides a simple interface for common LDAP admin tasks. That said, it isn't meant to be general-purpose LDAP libary, so it hides a lot and is opinionated. If you're using Active Directory and not doing strange things with it, this library might be helpful.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cratus'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cratus

## Usage

Make sure your application has required the gem:

```ruby
require 'cratus'
```

Cratus supports configuration settings, controlled via the following keys with the following default values:

      {
        group_dn_attribute: :cn,
        group_member_attribute: :member,
        group_description_attribute: :description,
        group_objectclass: :group,
        group_basedn: 'ou=groups,dc=example,dc=com',
        group_memberof_attribute: :memberOf,
        user_dn_attribute: :samaccountname,
        user_objectclass: :user,
        user_basedn: 'ou=users,dc=example,dc=com',
        user_account_control_attribute: :userAccountControl,
        user_department_attribute: :department,
        user_lockout_attribute: :lockouttime,
        user_mail_attribute: :mail,
        user_displayname_attribute: :displayName,
        user_memberof_attribute: :memberOf,
        host: 'ldap.example.com',
        port: 389,
        basedn: 'dc=example,dc=com',
        username: 'username',
        password: 'p@assedWard!',
        include_distribution_groups: true
      }

These keys can be set in the following ways:

* A YAML Config file at `~/.cratus.yml` in the form of:

```yaml
---
:basedn: ou=internal,dc=mycompany,dc=com
:host: ad1.mycompany.com
:username: cn=ldapUser,ou=serviceAccounts,ou=users,ou=internal,dc=mycompany,dc=com
:password: 'mySuperSecretP@ssw0rd'
:user_basedn: ou=users,ou=internal,dc=mycompany,dc=com
:group_basedn: ou=groups,ou=internal,dc=mycompany,dc=com
```

* Environment variables (all uppercase with `CRATUS_` prepended) in the form of:

```shell
export CRATUS_BASEDN="ou=internal,dc=mycompany,dc=com"
export CRATUS_HOST="ad1.mycompany.com"
...
```

* In code, by calling setter methods on the `Config` singleton:

```ruby
Cratus.config.basedn = 'ou=internal,dc=mycompany,dc=com'
Cratus.config.host   = 'ad1.mycompany.com'
```

With Cratus configured, you'll need to connect to LDAP:

```ruby
Cratus::LDAP.connect
```

After connecting, using Cratus involves using the model classes `User` and `Group`.

### Groups

The `Group` class supports the following finder methods:

* `Cratus::Group.all` returns an `Array<Cratus::Group>` of all groups scoped at or below the `group_basedn`.
* `Cratus::Group.new('name')` creates a new instance populated with details from LDAP (or raises `Cratus::Exceptions::FailedLDAPSearch` if the group can't be found).

Instances of `Group` have the following read-only attributes and methods:

* `#members` provides an `Array<Cratus::User>` of all users that are a member of the group. It does this recursively, so it supports nested groups.
* `#member_groups` provides an `Array<Cratus::Group>` of all groups that are a member of the group. It does this recursively, so it supports nested groups.
* `#member_of` provides an `Array<Cratus::Group>` of all groups that this group is a member of. It does this recursively, so it supports nested groups.
* `#dn` returns the distinguished name (dn) of the LDAP object
* `#description` returns the configurable LDAP "description" attribute as stored in LDAP if it exists. Otherwise it returns `nil`.

Instances of `Group` have the following methods that can change the underlying LDAP object:

* `#add_user(user)` allows adding individual LDAP users to a group. This method takes as input an instance of `Cratus::User`. It is idempotent and will add users as direct members of the group unless the user is already a member (directly or indirectly).
* `#remove_user(user)` allows removing individual LDAP users from a group. This method takes as input an instance of `Cratus::User`. It is idempotent and will remove users that are direct members of the group.

The `Group` class also implements [Comparable](https://ruby-doc.org/core-2.3.0/Comparable.html), so it supports common comparison methods, most notably `==`.

### Users

The `User` class supports the following finder methods:

* `Cratus::User.all` returns an `Array` of all users scoped at or below the `user_basedn`.
* `Cratus::User.new('name')` creates a new instance populated with details from LDAP (or raises `Cratus::Exceptions::FailedLDAPSearch` if the group can't be found).

Instances of `User` have the following read-only attributes and methods:

* `#department` returns the LDAP "department" attribute as stored in LDAP if it exists. Otherwise it returns `nil`.
* `#disabled?` returns `true` of `false` to indicate whether the User is fully disabled in LDAP.
* `#email` returns the configurable LDAP "mail" attribute as stored in LDAP if it exists. Otherwise it returns `nil`.
* `#enabled?` returns `true` of `false` to indicate whether the User is fully enabled in LDAP.
* `#fullname` returns the configurable LDAP "displayName" attribute as stored in LDAP if it exists. Otherwise it returns `nil`.
* `#lockouttime` returns the configurable LDAP "lockouttime" attribute as stored in LDAP if it exists. Otherwise it returns `0`.
* `#lockoutduration` queries the Active Directory basedn for the `lockoutDuration` attribute for use in calculations with `#lockouttime`.
* `#locked?` returns `true` or `false` based on `#lockouttime` and `#lockoutduration`.
* `#member_of` provides an `Array<Cratus::Group>` of all groups that this user is a member of. It does this recursively, so it supports nested groups.
* `#dn` returns the distinguished name (dn) of the LDAP object

Instances of `User` have the following methods that can change the underlying LDAP object:

* `#add_to_group(group)` allows adding an LDAP user to a group. This method takes as input an instance of `Cratus::Group`. It is idempotent and will add users as direct members of the group unless the user is already a member (directly or indirectly).
* `#remove_from_group(group)` allows removing an LDAP user from a group. This method takes as input an instance of `Cratus::Group`. It is idempotent and will remove the user if it is a direct members of the group.
* `#disable` changes the User Account Control (usually `userAccountControl`) attribute to `514`, signifying that logins are not allowed.
* `#enable` changes the User Account Control (usually `userAccountControl`) attribute to `512`, signifying that logins are allowed.
* `#unlock` changes the `lockouttime` atrribute to `0`, signifying that the account is not locked out.

The `User` class also implements [Comparable](https://ruby-doc.org/core-2.3.0/Comparable.html), so it supports common comparison methods, most notably `==`.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.

## Licensing

This project and all code contained within it are released under the [MIT License](https://opensource.org/licenses/MIT). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> All contributions to this project will be released under the [MIT License](https://opensource.org/licenses/MIT). By submitting a pull request, you are agreeing to comply with this license and for any contributions to be released under it.
