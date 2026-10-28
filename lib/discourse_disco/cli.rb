# frozen_string_literal: true

require_relative "cli/presentable_error"

module DiscourseDisco
  module CLI
    # Raised when a command needs Rails but the launcher can't boot it, e.g. a
    # standalone launcher that runs outside of a Discourse install.
    class RailsUnavailableError < StandardError
      include PresentableError
    end

    # Module-level so that code outside the command tree, like generated hints,
    # can show how to call the program. Falls back to the script name when
    # nothing was configured, which is also what Samovar uses.
    def self.program_name
      @program_name || File.basename($PROGRAM_NAME)
    end

    def self.configure(program_name:, boot_rails: nil)
      @program_name = program_name
      @boot_rails = boot_rails
      @rails_booted = false
    end

    def self.rails_available?
      !@boot_rails.nil?
    end

    # Commands that need Rails only in some modes call this instead of declaring
    # `requires_rails!`, so their other modes and `--help` stay fast.
    def self.boot_rails!(command_line = nil)
      return if @rails_booted

      if !rails_available?
        subject = command_line ? "`#{command_line}`" : "This command"
        raise RailsUnavailableError, "#{subject} needs a Discourse install."
      end

      @boot_rails.call
      @rails_booted = true
    end
  end
end
