require 'spec_helper'
require 'paratrooper/callbacks'

class CallbackTester
  include Paratrooper::Callbacks
  
  before_run_migrations :check_migrations
  
  def setup
    run_callbacks :setup
  end
  
  def run_migrations
    run_callbacks :run_migrations
  end
  
  def check_migrations; end
end

class CallbackOne
  def before_setup; end
  def before_teardown; end
end

class CallbackTwo
  def before_setup; end
  def before_push_repo; end
  def after_app_restart; end
end

describe Paratrooper::Callbacks do
  let(:callback_tester) { CallbackTester.new }
  describe '#add_callbacks' do
    it 'adds a callback for each callback in the array' do
      callback_one = double
      callback_two = double
      callbacks = [callback_one, callback_two]
      callback_tester.should_receive(:add_callback).with(callback_one)
      callback_tester.should_receive(:add_callback).with(callback_two)
      callback_tester.add_callbacks(callbacks)
    end
  end
  
  describe '#add_callback' do
    it 'adds before, around, and after callbacks for each method' do
      callback = double
      Paratrooper::Callbacks::METHODS.each do |method|
        callback_tester.should_receive(:add_before_callback).with(method, callback)
        callback_tester.should_receive(:add_around_callback).with(method, callback)
        callback_tester.should_receive(:add_after_callback).with(method, callback)
      end
      callback_tester.add_callback(callback)
    end
  end
  
  describe 'adding callbacks' do
    it 'only adds callbacks that the callback class implements' do
      callback_one = CallbackOne.new
      callback_two = CallbackTwo.new
      CallbackTester.should_receive(:set_callback).with(:setup, :before, callback_one)
      CallbackTester.should_receive(:set_callback).with(:teardown, :before, callback_one)
      CallbackTester.should_receive(:set_callback).with(:setup, :before, callback_two)
      CallbackTester.should_receive(:set_callback).with(:push_repo, :before, callback_two)
      CallbackTester.should_receive(:set_callback).with(:app_restart, :after, callback_two)
      callback_tester.add_callbacks([callback_one, callback_two])
    end
  end
  
  describe 'running callbacks' do
    it 'runs callbacks appropriately' do
      callback_one = CallbackOne.new
      callback_two = CallbackTwo.new
      callback_tester.add_callbacks([callback_one, callback_two])
      callback_one.should_receive(:before_setup)
      callback_two.should_receive(:before_setup)
      callback_tester.setup
    end
  end
  
  describe 'callback helpers' do
    it 'should call callbacks when specified using the callback helper syntax' do
      callback_tester.should_receive(:check_migrations)
      callback_tester.run_migrations
    end
  end
end