require "active_support/concern"

module ActiveEntry
  module ControllerConcern
    extend ActiveSupport::Concern

    class_methods do
      # Methods .authenticate_now! and .authorize_now!
      [:authenticate, :authorize].each do |name|
        define_method "#{name}_now!" do
          before_action do
            args = {}
            instance_variables.collect{ |v| v.to_s.remove("@").to_sym }.each do |name|
              value = instance_variable_get ["@", name].join
              next if value.nil?
              args[name] = value
            end
            send "#{name}!", **args
          end
        end
      end

      def verify_authentication!
        after_action do
          raise AuthenticationNotPerformedError.new(self.class, action_name) unless @__authentication_done
        end
      end

      def verify_authorization!
        after_action do
          raise AuthorizationNotPerformedError.new(self.class, action_name) unless @__authorization_done
        end
      end
    end

    def pass! **args
      authenticate! **args
      authorize! **args
    end
    
    def authenticate! **args
      entry_class::Authentication.pass! action_name, **args
      @__authentication_done = true
    end

    def authorize! **args
      entry_class::Authorization.pass! action_name, **args
      @__authorization_done = true
    end

    private

    def entry_class
      EntryFinder.entry_for self.class.name.remove("Controller")
    end
  end
end
