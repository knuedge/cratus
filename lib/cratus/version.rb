# The Cratus module
module Cratus
  def self.version
    major = 0 # Breaking, incompatible releases
    minor = 2 # Compatible, but new features
    patch = 5 # Fixes to existing features
    [major, minor, patch].map(&:to_s).join('.')
  end
end
