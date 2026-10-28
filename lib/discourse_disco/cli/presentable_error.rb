# frozen_string_literal: true

require "colored2"

module DiscourseDisco
  module CLI
    # Errors including this module are shown to the user as a clean, red message
    # (no backtrace) by the ExceptionHandler.
    module PresentableError
      # Override to print more than the message, e.g. suggestions for a typo.
      def present
        puts message.red
      end
    end
  end
end
