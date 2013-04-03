require 'spec_helper'
require 'paratrooper/notifier'

describe Paratrooper::Notifier do
  let(:notifier) { described_class.new }
  
  describe '#callbacks' do
    Paratrooper::Callbacks::METHODS.each do |method|
      it { should respond_to(method.to_sym) }
      it "should return true from the before_#{method} callback" do
        expect(notifier.send("before_#{method}", double(:default_payload => nil))).to be_true
      end
    end
    
    it 'should send the default payload into the notifier method' do
      payload = {'test' => 'value'}
      deployer = double(:default_payload => payload)
      notifier.should_receive(:setup).with(payload)
      notifier.before_setup(deployer)
    end
  end
end
