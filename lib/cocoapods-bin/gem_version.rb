module CocoapodsBin
  VERSION = "0.0.1"

  def self.match_version?(version)
  	Gem::Dependency.new("", version).match?('', Pod::VERSION) 
  end
end
