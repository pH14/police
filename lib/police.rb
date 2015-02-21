require 'police/kernel_labeling'
require 'police/policy_context'
require 'police/label'

module Police
  module Model
    extend ActiveSupport::Concern

    included do
    end

    module LocalInstanceMethods
      attr_accessor :police_policies

      def police(*protected_fields, action_hash)
        policy = Policy.new protected_fields, action_hash

        @police_policies ||= []
        @police_policies << policy
      end

      private

      # Attaches a label to a field that will propagate if needed
      # Attaching a label also attaches a security context that will
      # provide the necessary data flow
      def attach_label(field, label)
        self.send("#{field}").label_with label
      end
    end

    module ClassMethods
      include Police::Model::LocalInstanceMethods
    end
  end
end

module Police
  class Policy
    attr_reader :protected_fields # Array of fields' symbol names
    attr_reader :action_hash      # { :action => lambda method check }

    def initialize(protected_fields, action_hash)
      @protected_fields = protected_fields
      @action_hash = action_hash
    end

    def protects_field?(field)
      protected_fields.include? field
    end

    def protects_action?(action)
      action_hash.has_key? action
    end

    def protected_fields
      protected_fields.sort
    end

    def protected_actions
      action_hash.keys.sort
    end

    def policy_for(field, action)
      if protects_field? field and protects_action? action
        action_hash[action]
      else
        puts "Cannot find policy for #{field}, #{action}"
        nil
      end
    end
  end
end

ActiveRecord::Base.send :include, Police::Model
