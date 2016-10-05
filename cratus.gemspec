$LOAD_PATH.push File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift('lib') unless $LOAD_PATH.include?('lib')
require 'cratus/version'

Gem::Specification.new do |s|
  s.description = 'The Ruby tool for auditing and reporting on user permissions based on groups'
  s.name        = 'cratus'
  s.version     = Cratus.version
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Cratus queries LDAP for users and their memberships, then reports on it.'
  s.authors     = ['Jonathan Gnagy', 'Daniel Schaaff']
  s.email       = 'jgnagy@knuedge.com'
  s.bindir      = 'bin'
  s.files       = [
    'lib/cratus.rb',
    'lib/cratus/config.rb',
    'lib/cratus/group.rb',
    'lib/cratus/ldap.rb',
    'lib/cratus/user.rb',
    'lib/cratus/version.rb',
    'LICENSE'
  ]

  s.license     = 'MIT'
  s.platform    = Gem::Platform::RUBY

  s.executables << 'cratus'

  s.required_ruby_version = '~> 2.2'
  s.post_install_message  = 'Thanks for installing Cratus!'

  # Dependencies
  s.add_runtime_dependency 'colorize',    '~> 0.7'
  s.add_runtime_dependency 'net-ldap',    '~> 0.10'

  s.add_development_dependency 'rspec',   '~> 3.1'
  s.add_development_dependency 'rubocop', '~> 0.35'
  s.add_development_dependency 'yard',    '~> 0.8'
end
