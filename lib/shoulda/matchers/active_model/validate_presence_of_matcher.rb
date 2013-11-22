module Shoulda # :nodoc:
  module Matchers
    module ActiveModel # :nodoc:

      # Ensures that the model is not valid if the given attribute is not
      # present.
      #
      # Options:
      # * <tt>with_message</tt> - value the test expects to find in
      #   <tt>errors.on(:attribute)</tt>. <tt>Regexp</tt> or <tt>String</tt>.
      #   Defaults to the translation for <tt>:blank</tt>.
      #
      # Examples:
      #   it { should validate_presence_of(:name) }
      #   it { should validate_presence_of(:name).
      #                 with_message(/is not optional/) }
      #
      def validate_presence_of(attr)
        ValidatePresenceOfMatcher.new(attr)
      end

      class ValidatePresenceOfMatcher < ValidationMatcher # :nodoc:
        class CouldNotSetPasswordError < Shoulda::Matchers::Error
          def self.create(model)
            super(model: model)
          end

          attr_accessor :model

          def message
            <<EOT.strip
The validation failed because your #{model_name} model declares `has_secure_password`, and
`validate_presence_of` was called on a #{record_name} which has `password` already set to a value.
Please use an empty #{record_name} instead.
EOT
          end

          private

          def model_name
            model.name
          end

          def record_name
            model_name.humanize.downcase
          end
        end

        def with_message(message)
          @expected_message = message if message
          self
        end

        def matches?(subject)
          super(subject)
          @expected_message ||= :blank
          disallows_value_of(blank_value, @expected_message)
        rescue Shoulda::Matchers::ActiveModel::AllowValueMatcher::CouldNotSetAttributeError => error
          if @attribute == :password
            raise CouldNotSetPasswordError.create(subject.class)
          else
            raise error
          end
        end

        def description
          "require #{@attribute} to be set"
        end

        private

        def blank_value
          if collection?
            []
          else
            nil
          end
        end

        def collection?
          if reflection
            [:has_many, :has_and_belongs_to_many].include?(reflection.macro)
          else
            false
          end
        end

        def reflection
          @subject.class.respond_to?(:reflect_on_association) &&
            @subject.class.reflect_on_association(@attribute)
        end
      end
    end
  end
end
