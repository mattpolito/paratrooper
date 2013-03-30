require 'spec_helper'
require 'paratrooper/callback'

describe Paratrooper::Callback do
  let(:callback) { described_class.new }
  describe '#run' do
    it 'calls the correct method based on the step' do
      callback.should_receive(:before_run_migrations)
      callback.run(:run_migrations)
    end
  end
end
