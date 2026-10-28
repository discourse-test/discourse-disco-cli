# frozen_string_literal: true

RSpec.describe DiscourseDisco::CLI::ExceptionHandler do
  let(:presentable_error_class) do
    Class.new(StandardError) { include DiscourseDisco::CLI::PresentableError }
  end

  let(:error_with_suggestions_class) do
    Class.new(StandardError) do
      include DiscourseDisco::CLI::PresentableError

      def present
        puts "Unknown table 'usres'"
        puts "Did you mean: users"
      end
    end
  end

  def exit_status(&)
    described_class.handle_and_exit(&)
    nil
  rescue SystemExit => e
    e.status
  end

  it "returns the block's result when nothing is raised" do
    expect(described_class.handle_and_exit { 42 }).to eq(42)
  end

  it "prints a presentable error's message without a backtrace and exits with 1" do
    status = nil
    error = presentable_error_class.new("Something is wrong")

    expect { status = exit_status { raise error } }.to output(
      "Something is wrong".red + "\n",
    ).to_stdout
    expect(status).to eq(1)
  end

  it "lets a presentable error print its own presentation" do
    status = nil
    error = error_with_suggestions_class.new("Unknown table")

    expect { status = exit_status { raise error } }.to output(
      "Unknown table 'usres'\nDid you mean: users\n",
    ).to_stdout
    expect(status).to eq(1)
  end

  it "prints other errors with their backtrace and exits with 1" do
    status = nil

    expect { status = exit_status { raise ArgumentError, "boom" } }.to output(
      a_string_including("An error occurred: boom", __FILE__),
    ).to_stdout
    expect(status).to eq(1)
  end

  it "presents the error raised for a command that needs Rails" do
    DiscourseDisco::CLI.configure(program_name: "disco")

    expect { exit_status { DiscourseDisco::CLI.boot_rails!("disco backup") } }.to output(
      "`disco backup` needs a Discourse install.".red + "\n",
    ).to_stdout
  end
end
