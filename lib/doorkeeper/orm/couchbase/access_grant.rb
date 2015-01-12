
module Doorkeeper
  class AccessGrant < ::Couchbase::Model
    design_document :dk_ag

    include ::Doorkeeper::Couchbase::Timestamps

    attribute   :resource_owner_id,
                :token,
                :expires_in,
                :redirect_uri,
                :scopes

    view :by_application_id



    include OAuth::Helpers
    include Models::Expirable
    include Models::Revocable
    include Models::Accessible
    include Models::Scopes

    belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :access_grants

    if ::Rails.version.to_i < 4 || defined?(::ProtectedAttributes)
      attr_accessible :resource_owner_id, :application_id, :expires_in, :redirect_uri, :scopes
    end

    validates :resource_owner_id, :application_id, :token, :expires_in, :redirect_uri, presence: true


  	def self.by_token(token)
      find_by_id(token)
    end

    # Called from Application.rb -> clean_up
    def self.where_application_id(id)
      by_application_id({:key => id, :stale => false})
    end

    private

    before_create :generate_tokens
    def generate_tokens
      self.token = UniqueToken.generate
      self.id = self.token
    end

    # Auto remove the entry once expired
    after_create :set_ttl
    def set_ttl
      ::Doorkeeper::AccessGrant.bucket.touch self.id, :ttl => self.expires_in
    end
  end
end
