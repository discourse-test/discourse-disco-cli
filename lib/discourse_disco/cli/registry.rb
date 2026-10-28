# frozen_string_literal: true

module DiscourseDisco
  module CLI
    # Central registry of top-level commands. Launchers, gems and plugins
    # register their commands here at startup. The Samovar command tree is
    # built from this registry just before argv is parsed.
    module Registry
      # `requires_rails` means the command class itself can only be loaded
      # after Rails booted, e.g. because it comes from a gem that Rails
      # activates. Such a class is loaded only when its command is called.
      Entry = Struct.new(:name, :command_class, :description, :requires_rails, keyword_init: true)

      def self.entries
        @entries ||= {}
      end

      def self.register(name:, command_class:, description: nil, requires_rails: nil)
        name = name.to_s
        raise "A command named '#{name}' is already registered" if entries.key?(name)

        requires_rails = @requires_rails_default if requires_rails.nil?
        entries[name] = Entry.new(
          name:,
          command_class:,
          description:,
          requires_rails: requires_rails || false,
        )
      end

      # Applies `requires_rails` to the commands registered in the block. A
      # launcher wraps the registration files of code that only loads with
      # Rails, so the same files work for a launcher that loads that code
      # without Rails.
      def self.with_defaults(requires_rails:)
        previous = @requires_rails_default
        @requires_rails_default = requires_rails
        yield
      ensure
        @requires_rails_default = previous
      end

      def self.reset!
        @entries = {}
      end

      # Classes may be registered by name, so registering doesn't load them
      # (or Rails) early.
      def self.resolve(name)
        klass = entries.fetch(name).command_class
        klass = Object.const_get(klass.to_s) if klass.is_a?(String) || klass.is_a?(Symbol)
        klass
      end
    end
  end
end
