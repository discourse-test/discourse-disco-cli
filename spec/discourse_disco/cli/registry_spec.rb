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

  describe ".command_classes" do
    it "orders the commands by name" do
      described_class.register(name: "zebra", command_class:)
      described_class.register(name: "apple", command_class:)

      expect(described_class.command_classes.keys).to eq(%w[apple zebra])
    end

    it "resolves classes registered by name only when asked for" do
      described_class.register(name: "hello", command_class: "DiscoSpecRegistryCommand")
      stub_const("DiscoSpecRegistryCommand", command_class)

      expect(described_class.command_classes).to eq("hello" => command_class)
    end

    it "resolves namespaced class names given as symbols" do
      stub_const("DiscoSpec::RegistryCommand", command_class)
      described_class.register(name: "hello", command_class: :"DiscoSpec::RegistryCommand")

      expect(described_class.command_classes).to eq("hello" => command_class)
    end
  end
end
