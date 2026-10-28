# frozen_string_literal: true

module DiscourseDisco
  module CLI
    # Central registry of top-level commands. Launchers, gems and plugins
    # register their commands here at startup. The Samovar command tree is
    # built from this registry just before argv is parsed.
    module Registry
      Entry = Struct.new(:name, :command_class, :description, keyword_init: true)

      def self.entries
        @entries ||= {}
      end

      def self.register(name:, command_class:, description: nil)
        name = name.to_s
        raise "A command named '#{name}' is already registered" if entries.key?(name)
        entries[name] = Entry.new(name:, command_class:, description:)
      end

      def self.reset!
        @entries = {}
      end

      # Resolves the registered command classes into a name => Class hash,
      # ordered by registration name. Classes may be registered by name, so
      # registering doesn't load them (or Rails) early.
      def self.command_classes
        entries
          .sort_by { |name, _| name }
          .each_with_object({}) do |(name, entry), hash|
            klass = entry.command_class
            klass = Object.const_get(klass.to_s) if klass.is_a?(String) || klass.is_a?(Symbol)
            hash[name] = klass
          end
      end
    end
  end
end
