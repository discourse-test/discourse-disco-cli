# frozen_string_literal: true

RSpec.describe DiscourseDisco::CLI do
  describe ".program_name" do
    it "returns the configured program name" do
      described_class.configure(program_name: "bin/disco")
      expect(described_class.program_name).to eq("bin/disco")
    end

    it "falls back to the script name" do
      described_class.configure(program_name: nil)
      expect(described_class.program_name).to eq(File.basename($PROGRAM_NAME))
    end
  end

  describe ".boot_rails!" do
    it "calls the configured callable only once" do
      boot_rails = instance_double(Proc, call: nil)
      described_class.configure(program_name: "disco", boot_rails:)

      2.times { described_class.boot_rails! }

      expect(boot_rails).to have_received(:call).once
    end

    it "boots again after the next configuration" do
      boot_rails = instance_double(Proc, call: nil)
      described_class.configure(program_name: "disco", boot_rails:)
      described_class.boot_rails!
      described_class.configure(program_name: "disco", boot_rails:)
      described_class.boot_rails!

      expect(boot_rails).to have_received(:call).twice
    end

    it "raises a presentable error when no callable is configured" do
      described_class.configure(program_name: "disco")

      expect { described_class.boot_rails! }.to raise_error(
        described_class::RailsUnavailableError,
        "This command needs a Discourse install.",
      )
      expect(described_class::RailsUnavailableError.ancestors).to include(
        described_class::PresentableError,
      )
    end

    it "names the command line in the error when given" do
      described_class.configure(program_name: "disco")

      expect { described_class.boot_rails!("disco backup") }.to raise_error(
        described_class::RailsUnavailableError,
        "`disco backup` needs a Discourse install.",
      )
    end
  end

  describe ".rails_available?" do
    it "is true only when a callable is configured" do
      described_class.configure(program_name: "disco", boot_rails: -> {})
      expect(described_class.rails_available?).to be(true)

      described_class.configure(program_name: "disco")
      expect(described_class.rails_available?).to be(false)
    end
  end
end
