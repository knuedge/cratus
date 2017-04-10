require 'byebug'
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter '/spec/' }

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'cratus'
