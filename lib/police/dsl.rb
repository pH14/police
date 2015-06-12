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
          if action_hash.keys.any? { |action| not [:read, :write].include? action }
            raise PoliceError, "cannot create Police policy for action #{action}"
          end

          policy = Policy.new protected_fields, action_hash

          @police_policies ||= []
          @police_policies << policy
        end
      end

      def enforce_read_restrictions(user)
        check_dataflow(:read, user)
      end

      def label_for_action(action)
        case action
        when :read
          Police::DataFlow::ReadRestriction.new self
        else
          raise PoliceError, "no known label for action #{action}"
        end
      end

      def attach_policy(policy)
        policy.protected_fields.each do |field|
          if policy.protected_actions.include? :read
            attach_label field, label_for_action(:read)
          end
        end
      end

      def enforce_policy(policy, action, user=nil)
        return true if not policy.protects_action? action
        results = []

        if user.nil?
          policy.protected_fields.each do |field|
            field_with_labels = self

            if field.kind_of? Enumerable
              field.each do |subfield|
                field_with_labels = field_with_labels.send(subfield)
              end
            else
              field_with_labels = send(field)
            end

            field_with_labels.labels.each do |label|
              user = label.payload if label.is_a? Police::DataFlow::UserSupplied
              break
            end

            break if user
          end
        end

        results << policy.action_hash[action].call(self, user)
        results.all? { |r| r == true }
      end

      def start_dataflow
        if self.class.police_policies
          self.class.police_policies.each do |policy|
            attach_policy policy
          end
        end
      end

      def check_dataflow(action, user=nil)
        self.class.police_policies.each do |policy|
          if not enforce_policy policy, action, user
            raise PoliceError, "object fails policy #{policy} for action #{action}, user #{user}"
          end
        end
      end

      def check_dataflow_save
        check_dataflow(:write)
      end

      def check_dataflow_update
        check_dataflow(:write)
      end

      # Attaches a label to a field that will propagate if needed
      # Attaching a label also attaches a security context that will
      # provide the necessary data flow
      def attach_label(field, label)
        if field.kind_of? Enumerable
          to_label_object = self

          field.each do |subfield|
            if to_label_object
              to_label_object = to_label_object.send(subfield)
            else
              return
            end
          end

          to_label_object.label_with label
        else
          send(field).label_with label
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Police::Model::DSL
puts "Included Police into ActiveRecord"