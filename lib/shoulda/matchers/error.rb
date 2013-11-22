module Shoulda
  module Matchers
    class Error < StandardError
      def self.create(attributes)
        allocate.tap do |error|
          attributes.each do |name, value|
            error.send("#{name}=", value)
          end
          error.send(:initialize)
        end
      end

      def initialize(*args)
        super
        @message = message
      end
    end
  end
end
