module DagLinkCalculator
  NodeLink = Struct.new(:ancestor_id, :descendant_id, :direct, :count) do
    def <=>(other)
      [ancestor_id, descendant_id] <=> [other.ancestor_id, other.descendant_id]
    end

    def to_hash
      {
        ancestor_id: ancestor_id,
        descendant_id: descendant_id,
        direct: direct,
        count: count,
      }
    end
  end
end
