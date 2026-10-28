# discourse-disco-cli

The command framework behind Discourse's `disco` command line tool. It gives you:

- a registry that applications and plugins add their top-level commands to
- a bootstrap that builds the command tree, parses the command line and boots Rails only when the selected command needs it
- a base class for commands, built on [Samovar](https://github.com/ioquatix/samovar)
- an exception handler that prints user-facing errors without a backtrace

The gem doesn't know where Rails lives or how the program is called. The launcher script tells it.

## Installation

The gem is published to GitHub Packages. Add it to your Gemfile:

```ruby
source "https://rubygems.pkg.github.com/discourse-test" do
  gem "discourse-disco-cli"
end
```

## Usage

### A command

```ruby
class HelloCommand < DiscourseDisco::CLI::Command
  self.description = "Say hello"

  options { option "-h/--help", "Print out help." }
  one :who, "Whom to greet"

  def call
    return print_usage if @options[:help]

    who = require_positional!(@who, "who", hint: "Example: #{DiscourseDisco::CLI.program_name} hello world")
    puts "Hello #{who}"
  end
end
```

Commands that need Rails declare `requires_rails!`. Rails is booted after the command line is parsed and only when such a command was selected, so `--help` and other commands stay fast. A command that needs Rails only in some modes calls `DiscourseDisco::CLI.boot_rails!` itself.

Raise errors that include `DiscourseDisco::CLI::PresentableError` to show the user a clean message. Override `present` on the error to print more than its message.

### A launcher

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "discourse_disco_cli"

DiscourseDisco::CLI::Registry.register(
  name: "hello",
  command_class: "HelloCommand", # a string, so the class loads only when it's needed
  description: "Say hello",
)

DiscourseDisco::CLI::ExceptionHandler.handle_and_exit do
  DiscourseDisco::CLI::Bootstrap.run(
    ARGV,
    program_name: "bin/disco",
    description: "My tools",
    boot_rails: -> { require File.expand_path("../config/environment", __dir__) },
  )
end
```

`boot_rails` is optional. Without it, commands that declare `requires_rails!` fail with a message saying that they need a Discourse install.

### Commands whose classes need preparing

Some command classes can only be loaded after something else happened first, e.g. a plugin's commands, whose gems have to be activated. Register them with a `loader`, a callable that makes the class loadable, or with `requires_rails: true` when only a Rails boot does that. A launcher can also wrap the file that registers them:

```ruby
activate_plugin_gems = -> { PluginGem.activate_gemfiles_in(File.join(root, "plugins")) }

DiscourseDisco::CLI::Registry.with_defaults(loader: activate_plugin_gems) do
  Dir[File.join(root, "plugins/*/disco/register.rb")].sort.each { |path| require path }
end
```

Their classes are loaded only when their command is called, after the loader ran (or Rails booted). `--help` lists them with the description they were registered with, without loading anything. The same registration file works in a launcher that loads those classes directly: it just doesn't wrap it.

## Development

```bash
bin/setup     # install dependencies
bin/rspec     # run the specs
bin/lint      # autocorrect with RuboCop and format with Syntax Tree
bin/console   # an IRB session with the gem loaded
```

`bundle exec rubocop` and `bundle exec stree check Gemfile Rakefile '*.gemspec' '**/*.rb'` check without changing files.

## License

MIT, see [LICENSE.txt](LICENSE.txt).
