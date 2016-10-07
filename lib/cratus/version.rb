module Cratus
  def self.version
    major = 0 # Breaking, incompatible releases
    minor = 2 # Compatible, but new features
    patch = 1 # Fixes to existing features
    [major, minor, patch].map(&:to_s).join('.')
  end
end
