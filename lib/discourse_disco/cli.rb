# frozen_string_literal: true

module DiscourseDisco
  module CLI
    # Lives here, not in `command.rb`, so it resolves without loading the command stack.
    BIN = "migrations/bin/disco"
  end
end
