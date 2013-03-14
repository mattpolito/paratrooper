require 'paratrooper/notifier'

module Paratrooper
  module Notifiers
    class AirbrakeNotifier
      def setup
        `airbrake deploy`
      end
    end
  end
end
