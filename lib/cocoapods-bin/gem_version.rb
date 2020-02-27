# frozen_string_literal: true

module CBin
  VERSION = '0.1.29'
end

module Pod
  def self.match_version?(*version)
    Gem::Dependency.new('', *version).match?('', Pod::VERSION)
  end
end
