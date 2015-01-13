module DoorkeeperCouchbase
    class Engine < ::Rails::Engine

        config.after_initialize do |app|
            path = File.expand_path('../doorkeeper/orm/couchbase', __FILE__)

            # Ensure the models are loaded
            ::Doorkeeper::Orm::Couchbase.initialize_models!

            # Save the old document paths
            temp = ::Couchbase::Model::Configuration.design_documents_paths

            # Ensure couchbase is up to date
            ::Couchbase::Model::Configuration.design_documents_paths = [path]
            ::Doorkeeper::AccessToken.ensure_design_document!
            ::Doorkeeper::AccessGrant.ensure_design_document!
            ::Doorkeeper::Application.ensure_design_document!

            # restore the original value
            ::Couchbase::Model::Configuration.design_documents_paths = temp
        end
    end
end
