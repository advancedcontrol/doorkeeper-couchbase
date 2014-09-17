
module Doorkeeper
  module Orm
    module Couchbase
      def self.initialize_models!
        require 'doorkeeper/orm/couchbase/concerns/timestamps'
        
        require 'doorkeeper/orm/couchbase/application'
        require 'doorkeeper/orm/couchbase/access_grant'
        require 'doorkeeper/orm/couchbase/access_token'
      end
    end
  end
end
