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

      private

      def label_for_action(action)
        case action
        when :read
          puts "Setting a read label. its payload is #{self}"
          Police::DataFlow::ReadRestriction.new self
        when :write
          Police::DataFlow::WriteRestriction.new
        else
          raise PoliceError, "no known label for action #{action}"
        end
      end

      def attach_policy(policy)
        # puts "Attaching policy #{policy}. Protected actions are #{policy.protected_actions}"
        policy.protected_fields.each do |field|
          policy.protected_actions.each do |action|
            # puts "Placing read label on #{field}"
            attach_label field, label_for_action(action)
          end
        end
      end

      def enforce_policy(policy, action, user=nil)
        results = []

        puts "Going to try to enforce a policy! Woohoo! #{self.class.police_policies}"

        return true if not policy.protects_action? action

        puts "Enforcing policy #{policy}, action #{action}. Given user #{user}"

        policy.protected_fields.each do |field|

          if user.nil?
            send(field).labels.each do |label|
              user = label.payload if label.is_a? Police::DataFlow::UserSupplied
              puts "Grabbed UserSupplied label from #{user}. Will use this label for policies"
            end
          end

          # puts "The block will be #{policy.action_hash[action]}"
          results << policy.action_hash[action].call(self, user)
        end

        puts "Results are #{results}"

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
        puts "Check data flow save"
        check_dataflow(:write)
      end

      def check_dataflow_update
        puts "Check data flow update"
        check_dataflow(:write)
      end

      # Attaches a label to a field that will propagate if needed
      # Attaching a label also attaches a security context that will
      # provide the necessary data flow
      def attach_label(field, label)
        puts "Trying to attach a label to #{field}. I am a #{self.class}"
        send(field).label_with label
      end
    end
  end
end

ActiveRecord::Base.send :include, Police::Model::DSL
