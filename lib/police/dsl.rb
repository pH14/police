module Police
  class PoliceError < StandardError
  end

  module Model
    module DSL
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Naming
        extend ActiveModel::Callbacks
        extend ActiveModel::Translation

        after_initialize :start_dataflow, if: Proc.new { self.class.police_policies }
        before_save :check_dataflow_save, if: Proc.new { self.class.police_policies }
        before_update :check_dataflow_update, if: Proc.new { self.class.police_policies }
      end

      module ClassMethods
        attr_accessor :police_policies

        def police(*protected_fields, action_hash)
          if action_hash.keys.any? { |action| not [:save, :create, :validation].include? action }
            raise PoliceError, "cannot create Police policy for action #{action}"
          end

          policy = Policy.new protected_fields, action_hash

          @police_policies ||= []
          @police_policies << policy
        end
      end

      private

      def start_dataflow
        if self.class.police_policies
          self.class.police_policies.each do |policy|
            policy.protected_fields.each do |field|
              attach_label field, Police::DataFlow::Label.new("user A")
            end
          end
        end
      end

      def check_dataflow(*actions)
        self.class.police_policies.each do |policy|
          policy.enforce_policy self, *actions
        end
      end

      def check_dataflow_save
        check_dataflow(:save)
      end

      def check_dataflow_update
        check_dataflow(:update)
      end

      # Attaches a label to a field that will propagate if needed
      # Attaching a label also attaches a security context that will
      # provide the necessary data flow
      def attach_label(field, label)
        send(field).label_with label
      end
    end
  end
end

ActiveRecord::Base.send :include, Police::Model::DSL
