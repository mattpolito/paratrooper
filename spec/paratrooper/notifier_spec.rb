require 'spec_helper'
require 'paratrooper/notifier'

describe Paratrooper::Notifier do
  let(:notifier) { described_class.new }
  describe '#notify' do
    it 'sends correct method options' do
      notifier.should_receive(:update_repo_tag).with(test: 'blah')
      notifier.notify(:update_repo_tag, test: 'blah')
    end
  end
end
