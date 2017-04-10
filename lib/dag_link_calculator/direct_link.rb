module DagLinkCalculator
  DirectLink = Struct.new(:ancestor_id, :descendant_id) do
    def self.from_hash(hash)
      new(parse_ancestor(hash), parse_descendant(hash))
    end

    def self.parse_ancestor(hash)
      hash[:ancestor_id] || hash[:parent_id] || hash[:ancestor] || hash[:parent]
    end

    def self.parse_descendant(hash)
      hash[:descendant_id] || hash[:child_id] || hash[:descendant] || hash[:child]
    end

    def direct?
      true
    end

    def count
      1
    end

    def parent_id
      descendant_id
    end

    def parent_id=(v)
      self.descendant_id = v
    end

    def to_link
      NodeLink(ancestor_id, descendant_id, direct?, count)
    end

    def <=>(other)
      [descendant_id, ancestor_id] <=> [other.descendant_id, other.ancestor_id]
    end
  end
end
