module Police
  module DataFlow
    class Label
      attr_accessor :payload

      def initialize(payload)
      	@payload = payload
      end

      def propagate(host, other)
        other.label_with self
      end

      # Whether or not to propagate to the other object
      def accepts?(other)
        true
      end
    end
  end
end