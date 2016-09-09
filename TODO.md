# TODO

## High level overview

* Use 'net/ldap'
* Define group permissions
  * Manual for now
  * Probably YAML or JSON
* Pull group list
* Determine group memberships
* Map groups to permissions
* Outputs
  * User => Groups mapping (YAML)
  * User => Permissions mapping (YAML)

## Work

### Use 'net/ldap'

##### Requirement

Use `net/ldap` to build a library for interacting with LDAP

##### Task

Build basic library for working with LDAP that can:

* run searches
* understand users and groups
* work within a scope setting
* return only required attributes
* be customized for different LDAP schemas
* support SSL/TLS, arbitrary host and port
* support recursive group memberships

### Define group permissions

##### Requirement

This tool needs input that tells it what members of a group can do. We need to define how that input should be structured and develop a process for providing it.

##### Task

Produce an example YAML file to start testing.

### Pull group list

##### Requirement

Groups need to be discovered and parsed into something usable by the application

##### Task

Produce a Group class that is created by querying LDAP and retrieving the required attributes. This class should provide a `#members` instance method that lists its users. This method can optionally provide a recursive list of members, perhaps via a method parameter or option.

### Determine group memberships

##### Requirement

We need to know who is a member of a group, along with some basic info about these members.

##### Task

Produce a User class that is created by querying LDAP and retrieving the require attributes. This class should provide a `#member_of` instance method that lists direct group memberships. This method can optionally provide a recursive list of groups, perhaps via a method parameter or option.

The Group class should include a means of listing member groups, ideally via a `#member_groups` method that behaves similarly to `#members`, and may be relied on by the `#members` method for recursive group memberships.

### Map groups to permissions

##### Requirement

Group membership comes with some permissions, provided as input. We need this tool to internalize this and provide it as part of the output.

##### Task

The app should have an internal data structure that is used to map groups to their permissions as they are discovered. Ideally, this structure would be available as a singleton throughout the application.

### Provide outputs

##### Requirement

This tool should provide:

* A document that shows User to Group members
* A document that shows User permissions based on Group memberships

This output should be in YAML and be sorted such that it is easy to `diff` by an external tool.

##### Task

Use the ruby `yaml` standard library to produce the required documents.
