# frozen_string_literal: true

require "colored2"
require "samovar"

module DiscourseDisco
  module CLI
    # Builds the Samovar command tree from the registry, selects the command for
    # the given argv, lazily boots Rails when the selected command requires it,
    # and dispatches.
    module Bootstrap
      # `program_name` is how users call the launcher; it's shown in usage and
      # hints. `boot_rails` is a callable that boots the Rails app, or `nil`
      # when the launcher runs without one.
      def self.run(argv, program_name:, boot_rails: nil, description: nil)
        CLI.configure(program_name:, boot_rails:)

        top =
          build_top_command_class(description).new(normalize_option_args(argv), name: program_name)

        leaf = deepest_command(top)
        if leaf.class.respond_to?(:requires_rails?) && leaf.class.requires_rails?
          CLI.boot_rails!(command_line(leaf))
        end

        top.call
      rescue Samovar::Error => e
        # The top-level command has no `--help` option, so a help request
        # surfaces as an unparsable token.
        help_request = e.is_a?(Samovar::InvalidInputError) && %w[--help -h].include?(e.token)

        if !help_request
          # e.g. `Could not parse token "validat"` — without it, an
          # unrecognized command or argument prints bare usage with no
          # explanation of what was wrong.
          puts e.message.red
          puts
        end

        e.command.print_usage
        exit(help_request ? 0 : 1)
      end

      # Samovar expects `--opt value`; the previous Thor-based CLI also accepted
      # `--opt=value`. Split the `=` form into two tokens so existing muscle
      # memory keeps working. Only long options are touched; `--`, short flags,
      # and bare positional values pass through unchanged.
      def self.normalize_option_args(argv)
        argv.flat_map do |arg|
          if arg.start_with?("--") && (index = arg.index("=")) && index > 2
            [arg[0...index], arg[(index + 1)..]]
          else
            arg
          end
        end
      end

      # Walks the nested `command` chain to the deepest selected sub-command.
      def self.deepest_command(command)
        node = command
        node = node.command while node.respond_to?(:command) && node.command
        node
      end

      def self.command_line(command)
        names = []
        node = command
        while node
          names.unshift(node.name)
          node = node.parent
        end
        names.join(" ")
      end

      def self.build_top_command_class(description)
        commands = Registry.command_classes

        Class.new(Command) do
          self.description = description
          nested :command, commands

          def call
            if @command
              @command.call
            else
              print_usage
            end
          end
        end
      end
    end
  end
end
