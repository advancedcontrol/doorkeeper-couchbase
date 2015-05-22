
module Doorkeeper
  class AccessToken < ::Couchbase::Model
    design_document :dk_at

    include ::Doorkeeper::Couchbase::Timestamps
    
    attribute :resource_owner_id,
              :token,
              :expires_in,
              :scopes,
              :refresh_token

    # Couchbase views for lookup
    view  :by_resource_owner_id,
          :by_application_id,
          :by_application_id_and_resource_owner_id



    include OAuth::Helpers
    include Models::Expirable
    include Models::Revocable
    include Models::Accessible
    include Models::Scopes

    belongs_to :application,
                class_name: 'Doorkeeper::Application',
                inverse_of: :access_tokens

    attr_writer :use_refresh_token

    if ::Rails.version.to_i < 4 || defined?(::ProtectedAttributes)
      attr_accessible :application_id, :resource_owner_id, :expires_in,
                      :scopes, :use_refresh_token
    end



    def self.by_token(token)
      find_by_id(token)
    end

    def self.by_refresh_token(refresh_token)
      id = AccessToken.bucket.get("refresh-#{refresh_token}", {quiet: true})
      if id
        find_by_id(id)
      end
    end

    def self.revoke_all_for(application_id, resource_owner)
      by_application_id_and_resource_owner_id({:key => [application_id, resource_owner], :stale => false}).each do |at|
        at.revoke
      end
    end


    def scopes=(value)
      write_attribute :scopes, value if value.present?
    end

    def self.last
      by_application_id_and_resource_owner_id({:stale => false, :descending => true}).first
    end

    def self.delete_all_for(application_id, resource_owner)
      by_application_id_and_resource_owner_id({:key => [application_id, resource_owner], :stale => false}).each do |at|
        at.delete
      end
    end
    private_class_method :delete_all_for

    def self.last_authorized_token_for(application_id, resource_owner_id)
      res = by_application_id_and_resource_owner_id({
        :key => [application_id, resource_owner_id],
        :stale => false}).first
    end
    private_class_method :last_authorized_token_for



    # Called from Application.rb -> authorized_for
    def self.where_owner_id(id)
      Application.find(*by_resource_owner_id({:key => id}))
    end

    # Called from Application.rb -> clean_up
    def self.where_application_id(id)
      by_application_id({:key => id, :stale => false})
    end



    def self.matching_token_for(application, resource_owner_or_id, scopes)
      resource_owner_id = if resource_owner_or_id.respond_to?(:to_key)
                            resource_owner_or_id.id
                          else
                            resource_owner_or_id
                          end
      token = last_authorized_token_for(application.try(:id), resource_owner_id)
      token if token && Doorkeeper::OAuth::Helpers::ScopeChecker.match?(token.scopes, scopes)
    end

    def self.find_or_create_for(application, resource_owner_id, scopes, expires_in, use_refresh_token)
      if Doorkeeper.configuration.reuse_access_token
        access_token = matching_token_for(application, resource_owner_id, scopes)
        if access_token && !access_token.expired?
          return access_token
        end
      end
      create!(
        application_id:    application.try(:id),
        resource_owner_id: resource_owner_id,
        scopes:            scopes.to_s,
        expires_in:        expires_in,
        use_refresh_token: use_refresh_token
      )
    end

    def token_type
      'bearer'
    end

    def use_refresh_token?
      !!@use_refresh_token
    end

    def as_json(_options = {})
      {
        resource_owner_id: resource_owner_id,
        scopes: scopes,
        expires_in_seconds: expires_in_seconds,
        application: { uid: application.try(:uid) }
      }
    end

    # It indicates whether the tokens have the same credential
    def same_credential?(access_token)
      application_id == access_token.application_id &&
        resource_owner_id == access_token.resource_owner_id
    end

    def acceptable?(scopes)
      accessible? && includes_scope?(*scopes)
    end


    private



    def generate_refresh_token
      write_attribute :refresh_token, UniqueToken.generate
    end

    def generate_token
      self.token = UniqueToken.generate
    end



    before_create :generate_tokens
    def generate_tokens
      generate_token
      generate_refresh_token if use_refresh_token?
      self.id = self.token
    end

    after_create :set_refresh_token, if: :use_refresh_token?
    def set_refresh_token
      # TODO:: add config for refresh token time
      expire = (Time.now + 3.months).to_i  # Over 30 days couchbase requires a different format
      ::Doorkeeper::AccessToken.bucket.touch self.id, :ttl => expire
      ::Doorkeeper::AccessToken.bucket.set("refresh-#{self.refresh_token}", self.id, :ttl => expire)
    end

    before_delete :remove_refresh_token, if: :use_refresh_token?
    def remove_refresh_token
      ::Doorkeeper::AccessToken.bucket.delete("refresh-#{self.refresh_token}")
    end

    after_create :set_ttl, unless: :use_refresh_token?
    def set_ttl
      ::Doorkeeper::AccessToken.bucket.touch self.id, :ttl => self.expires_in
    end
  end
end
