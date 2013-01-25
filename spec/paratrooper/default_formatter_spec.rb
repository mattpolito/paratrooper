require 'spec_helper'
require 'paratrooper/default_formatter'

describe Paratrooper::DefaultFormatter do
  let(:formatter) { described_class.new(output_stub) }
  let(:output_stub) { StringIO.new }

  describe "#display(message)" do
    it "outputs _message_ to screen" do
      expected_output = <<-EXPECTED_OUTPUT.gsub(/^ {8}/, '')

        #{'=' * 80}
        >> MESSAGE
        #{'=' * 80}

      EXPECTED_OUTPUT

      formatter.display('MESSAGE')
      output_stub.seek(0)

      expect(output_stub.read).to eq(expected_output)
    end
  end
end
