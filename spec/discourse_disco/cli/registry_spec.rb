# frozen_string_literal: true

RSpec.describe DiscourseDisco::CLI::Registry do
  let(:command_class) { Class.new(DiscourseDisco::CLI::Command) }

  before { described_class.reset! }

  after { described_class.reset! }

  describe ".register" do
    it "stores the entry under the name as a string" do
      described_class.register(name: :hello, command_class:, description: "Say hello")

      expect(described_class.entries["hello"]).to have_attributes(
        name: "hello",
        command_class:,
        description: "Say hello",
      )
    end

    it "raises when the name is already registered" do
      described_class.register(name: "hello", command_class:)

      expect { described_class.register(name: "hello", command_class:) }.to raise_error(
        RuntimeError,
        "A command named 'hello' is already registered",
      )
    end
  end

  describe ".with_defaults" do
    it "flags the commands registered in the block" do
      described_class.with_defaults(requires_rails: true) do
        described_class.register(name: "inside", command_class:)
      end
      described_class.register(name: "outside", command_class:)

      expect(described_class.entries["inside"].requires_rails).to eq(true)
      expect(described_class.entries["outside"].requires_rails).to eq(false)
    end

    it "sets a loader for the commands registered in the block" do
      loader = -> {}
      described_class.with_defaults(loader:) do
        described_class.register(name: "inside", command_class:)
      end
      described_class.register(name: "outside", command_class:)

      expect(described_class.entries["inside"]).to have_attributes(loader:, deferred?: true)
      expect(described_class.entries["outside"]).to have_attributes(loader: nil, deferred?: false)
    end

    it "keeps the outer defaults in a nested block" do
      loader = -> {}
      described_class.with_defaults(loader:) do
        described_class.with_defaults(requires_rails: true) do
          described_class.register(name: "hello", command_class:)
        end
      end

      expect(described_class.entries["hello"]).to have_attributes(loader:, requires_rails: true)
    end

    it "lets an explicit argument win" do
      described_class.with_defaults(requires_rails: true) do
        described_class.register(name: "hello", command_class:, requires_rails: false)
      end

      expect(described_class.entries["hello"].requires_rails).to eq(false)
    end

    it "restores the previous default when the block raises" do
      expect {
        described_class.with_defaults(requires_rails: true) { raise "broken registration" }
      }.to raise_error(RuntimeError, "broken registration")

      described_class.register(name: "hello", command_class:)
      expect(described_class.entries["hello"].requires_rails).to eq(false)
    end
  end

  describe ".resolve" do
    it "returns a registered class" do
      described_class.register(name: "hello", command_class:)
      expect(described_class.resolve("hello")).to eq(command_class)
    end

    it "resolves classes registered by name only when asked for" do
      described_class.register(name: "hello", command_class: "DiscoSpecRegistryCommand")
      stub_const("DiscoSpecRegistryCommand", command_class)

      expect(described_class.resolve("hello")).to eq(command_class)
    end

    it "resolves namespaced class names given as symbols" do
      stub_const("DiscoSpec::RegistryCommand", command_class)
      described_class.register(name: "hello", command_class: :"DiscoSpec::RegistryCommand")

      expect(described_class.resolve("hello")).to eq(command_class)
    end
  end
end
