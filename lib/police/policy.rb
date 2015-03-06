module Police
  module Model
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

      def protected_actions
        action_hash.keys
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
end
