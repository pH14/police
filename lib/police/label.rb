module Police
  module DataFlow
    class Label
      attr_accessor :payload # User, or Model

      def initialize(payload=nil)
      	@payload = payload
      end

      def propagate(other)
        other.label_with self if not other.nil? and accepts? other
      end

      # Whether or not to propagate to the other object
      def accepts?(other)
        true
      end
    end

    class ReadRestriction < Label
    end

    class WriteRestriction < Label
    end

    class UserSupplied < Label
    end
  end
end