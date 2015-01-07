
module Doorkeeper
  module Couchbase
    class ViewsGenerator < ::Rails::Generators::Base
      desc "Ensures the design documents for map reduce in couchbase exist"

      def install
        path = File.expand_path('../../../../doorkeeper/orm/couchbase', __FILE__)
        
        puts "installing design documents at #{path}"
        require "#{path}.rb"
        ::Doorkeeper::Orm::Couchbase.initialize_models!
        
        ::Couchbase::Model::Configuration.design_documents_paths = [path]
        ::Doorkeeper::AccessToken.ensure_design_document!
        ::Doorkeeper::AccessGrant.ensure_design_document!
        ::Doorkeeper::Application.ensure_design_document!
      end
    end
  end
end
