module CBin
  VERSION = "0.1.16"
end

module Pod
  def self.match_version?(*version)
    Gem::Dependency.new("", *version).match?('', Pod::VERSION) 
  end
end