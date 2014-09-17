require 'date'

module Doorkeeper
  module Couchbase
    module Timestamps

      def self.included(base)
        base.class_eval do
          attribute :revoked_at

          # Round time up to the nearest second
          attribute :created_at, :default => lambda { Time.now.to_i + 1 }

          def revoked_at
            revoked = self.attributes[:revoked_at]
            unless revoked.nil?
              Time.at(revoked)
            end
          end

          def revoked_at=(time)
            if time
              number = time.is_a?(Numeric) ? time.to_i : time.to_time.to_i
              write_attribute(:revoked_at, number)
            end
          end

          def created_at
            Time.at(self.attributes[:created_at])
          end

          # Couchbase is missing update_attribute
          def update_attribute(att, value)
            self.send(:"#{att}=", value)
            self.save(validate: false)
          end
        end
      end

    end
  end
end
