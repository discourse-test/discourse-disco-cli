# frozen_string_literal: true

require_relative "lib/discourse_disco/cli/version"

Gem::Specification.new do |spec|
  spec.name = "discourse-disco-cli"
  spec.version = DiscourseDisco::CLI::VERSION
  spec.authors = ["Discourse Team"]

  spec.summary = "Command framework for Discourse's disco command line tool"
  spec.description =
    "Provides the building blocks of the disco command line tool: a registry that applications and plugins add their commands to, a bootstrap that parses the command line and boots Rails only for commands that need it, a base class for commands, and an exception handler that prints user-facing errors without a backtrace."
  spec.homepage = "https://github.com/discourse-test/discourse-disco-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/discourse-test"
  spec.metadata["github_repo"] = "ssh://github.com/discourse-test/discourse-disco-cli"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "colored2", ">= 4.0"
  spec.add_dependency "samovar", ">= 2.5"
end
