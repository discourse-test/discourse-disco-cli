# frozen_string_literal: true

require "colored2"

module DiscourseDisco
  module CLI
    class ExceptionHandler
      def self.handle_and_exit(&block)
        block.call
      rescue PresentableError => e
        e.present
        exit(1)
      rescue => e
        puts "An error occurred: #{e.message}".red
        puts e.backtrace.join("\n")
        exit(1)
      end
    end
  end
end
