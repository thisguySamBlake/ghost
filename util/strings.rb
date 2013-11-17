require_relative 'warnings'

module CaseInsensitiveStrings
  silence_warnings do
    refine String do
      def <=>(other_string)
        self.casecmp other_string
      end

      def eql?(other_string)
        (self <=> other_string) == 0
      end
      alias_method :==, :eql?

      alias_method :string_hash, :hash
      def hash
        self.downcase.string_hash
      end

      alias_method :string_start_with?, :start_with?
      def start_with?(prefix)
        self.downcase.string_start_with? prefix.downcase
      end
    end
  end
end
