# The Cratus module
module Cratus
  def self.version
    major = 0 # Breaking, incompatible releases
    minor = 5 # Compatible, but new features
    patch = 3 # Fixes to existing features
    [major, minor, patch].map(&:to_s).join('.')
  end
end
