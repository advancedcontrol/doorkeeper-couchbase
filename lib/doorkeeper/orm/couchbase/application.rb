require 'addressable/uri'
require 'digest'


module Doorkeeper
  class Application < ::Couchbase::Model
    design_document :dk_app

    attribute :name,
              :uid,
              :secret,
              :redirect_uri
    attribute :scopes, default: ''

    attribute :created_at, :default => lambda { Time.now.to_i }

    view  :show_all,
          :by_user_id


    include OAuth::Helpers
    alias_method :uid, :id


    validates :name, :secret, :uid, presence: true
    validates :redirect_uri, redirect_uri: true

    if ::Rails.version.to_i < 4 || defined?(::ProtectedAttributes)
      attr_accessible :name, :redirect_uri
    end


    def self.by_uid_and_secret(uid, secret)
      app = find_by_id(uid)
      if app
        return app.secret == secret ? app : nil
      end
      nil
    end

    def self.by_uid(uid)
      find_by_id(uid)
    end


    def scopes=(value)
      write_attribute :scopes, value if value.present?
    end

    def self.authorized_for(resource_owner)
      AccessToken.where_owner_id(resource_owner.id)
    end

    

    ## TODO:: Where are these used
    def self.by_user(id)
      by_user_id({:key => [id], :stale => false})
    end
    
    def self.all
      show_all({:key => nil, :include_docs => true, :stale => false})
    end


    private


    before_create :set_id
    def set_id
      origin = Addressable::URI.parse(self.redirect_uri).origin
      self.uid ||= Digest::MD5.hexdigest(origin.downcase)
      self.secret ||= UniqueToken.generate
    end

    # This is equivalent to has_many dependent: :destroy
    before_delete :clean_up
    def clean_up
      AccessToken.where_application_id(self.id).each do |at|
        at.delete!
      end
      AccessGrant.where_application_id(self.id).each do |at|
        at.delete!
      end
    end
  end
end
