# frozen_string_literal: true

module DiscourseDisco
  module CLI
    # Central registry of top-level commands. Launchers, gems and plugins
    # register their commands here at startup. The Samovar command tree is
    # built from this registry just before argv is parsed.
    module Registry
      # `requires_rails` means the command class itself can only be loaded
      # after Rails booted, e.g. because it comes from a gem that Rails
      # activates. `loader` is a callable that makes the class loadable some
      # other way, e.g. by activating the gems it comes from. Either way the
      # class is loaded only when its command is called.
      Entry =
        Struct.new(
          :name,
          :command_class,
          :description,
          :requires_rails,
          :loader,
          keyword_init: true,
        ) do
          def deferred?
            requires_rails || !loader.nil?
          end
        end

      def self.entries
        @entries ||= {}
      end

      def self.register(name:, command_class:, description: nil, requires_rails: nil, loader: nil)
        name = name.to_s
        raise "A command named '#{name}' is already registered" if entries.key?(name)

        defaults = @defaults || {}
        requires_rails = defaults[:requires_rails] if requires_rails.nil?
        entries[name] = Entry.new(
          name:,
          command_class:,
          description:,
          requires_rails: requires_rails || false,
          loader: loader || defaults[:loader],
        )
      end

      # Applies `requires_rails` and `loader` to the commands registered in the
      # block. A launcher wraps the registration files of code that it loads in
      # a special way, so the same files work for a launcher that loads that
      # code directly.
      def self.with_defaults(requires_rails: nil, loader: nil)
        previous = @defaults
        @defaults = (previous || {}).merge({ requires_rails:, loader: }.compact)
        yield
      ensure
        @defaults = previous
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
