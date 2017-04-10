module DagLinkCalculator
  ANCESTOR_KEYS = [:ancestor_id, :ancestor, :parent_id, :parent].freeze
  DESCENDANT_KEYS = [:descendant_id, :descendant, :child_id, :child].freeze

  DirectLink = Struct.new(:ancestor_id, :descendant_id) do
    def self.from_hash(hash)
      ancestor_id = fetch_from hash, ANCESTOR_KEYS
      descendant_id = fetch_from hash, DESCENDANT_KEYS
      new(ancestor_id, descendant_id)
    end

    def self.fetch_from(hash, keys)
      keys.each do |k|
        return hash[k] if hash[k]
      end

      raise KeyError, "none of these keys found in the given hash: #{keys}"
    end

    def direct
      true
    end

    def direct?
      direct
    end

    def count
      1
    end

    def to_link
      NodeLink.new(ancestor_id, descendant_id, direct?, count)
    end

    def <=>(other)
      [ancestor_id, descendant_id] <=> [other.ancestor_id, other.descendant_id]
    end
  end
end
