# frozen_string_literal: true

RSpec.describe DiscourseDisco::CLI::Bootstrap do
  describe ".normalize_option_args" do
    subject(:normalized) { described_class.normalize_option_args(argv) }

    context "with the `--opt=value` form" do
      let(:argv) { %w[schema generate --db=intermediate_db] }

      it "splits it into two tokens" do
        expect(normalized).to eq(%w[schema generate --db intermediate_db])
      end
    end

    context "with the `--opt value` form" do
      let(:argv) { %w[schema generate --db intermediate_db] }

      it "leaves it unchanged" do
        expect(normalized).to eq(%w[schema generate --db intermediate_db])
      end
    end

    it "splits only on the first `=`" do
      expect(described_class.normalize_option_args(["--filter=a=b"])).to eq(%w[--filter a=b])
    end

    it "preserves comma-separated values" do
      expect(described_class.normalize_option_args(["--only=users,topics"])).to eq(
        %w[--only users,topics],
      )
    end

    it "does not touch short flags, the `--` separator, or bare values" do
      argv = %w[-s=x -- key=value]
      expect(described_class.normalize_option_args(argv)).to eq(argv)
    end

    it "leaves a bare `--=value` untouched" do
      expect(described_class.normalize_option_args(["--=value"])).to eq(["--=value"])
    end
  end

  describe ".run" do
    let(:calls) { [] }
    let(:boot_rails) { -> { calls << :boot_rails } }

    let(:hello_command) do
      log = calls
      Class.new(DiscourseDisco::CLI::Command) do
        self.description = "Say hello"
        one :who, "Whom to greet"

        define_method(:call) { log << [:hello, who, DiscourseDisco::CLI.program_name] }
      end
    end

    let(:rails_command) do
      log = calls
      Class.new(DiscourseDisco::CLI::Command) do
        requires_rails!
        self.description = "Needs Rails"

        define_method(:call) { log << :rails_command }
      end
    end

    let(:group_command) do
      subcommand = Class.new(rails_command)
      Class.new(DiscourseDisco::CLI::Command) do
        self.description = "A group"
        nested :command, { "sub" => subcommand }

        def call
          @command&.call
        end
      end
    end

    before do
      DiscourseDisco::CLI::Registry.reset!
      DiscourseDisco::CLI::Registry.register(name: "hello", command_class: hello_command)
      DiscourseDisco::CLI::Registry.register(name: "needs-rails", command_class: rails_command)
      DiscourseDisco::CLI::Registry.register(name: "group", command_class: group_command)
    end

    after { DiscourseDisco::CLI::Registry.reset! }

    def run(argv, **options)
      described_class.run(argv, program_name: "bin/disco", **options)
    end

    it "runs the selected command" do
      run(%w[hello world], boot_rails:)
      expect(calls).to eq([[:hello, "world", "bin/disco"]])
    end

    it "shows the program name and the description in the usage" do
      expect { run(%w[--help], description: "Discourse tools") }.to output(
        a_string_including("bin/disco", "Discourse tools", "hello", "needs-rails"),
      ).to_stdout.and raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
    end

    it "prints the parse error and the usage for unknown commands" do
      expect { run(%w[unknown]) }.to output(
        a_string_including('Could not parse token "unknown"', "bin/disco"),
      ).to_stdout.and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    end

    it "doesn't boot Rails for commands that don't require it" do
      run(%w[hello world], boot_rails:)
      expect(calls).not_to include(:boot_rails)
    end

    it "boots Rails before running a command that requires it" do
      run(%w[needs-rails], boot_rails:)
      expect(calls).to eq(%i[boot_rails rails_command])
    end

    it "boots Rails for a nested command that inherits `requires_rails!`" do
      run(%w[group sub], boot_rails:)
      expect(calls).to eq(%i[boot_rails rails_command])
    end

    it "raises a presentable error when a command requires Rails and none is configured" do
      expect { run(%w[group sub]) }.to raise_error(
        DiscourseDisco::CLI::RailsUnavailableError,
        "`bin/disco group sub` needs a Discourse install.",
      )
      expect(calls).to be_empty
    end
  end
end
