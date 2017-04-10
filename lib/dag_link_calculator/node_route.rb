module DagLinkCalculator
  NodeRoute = Struct.new(:nodes) do
    def size
      nodes.size
    end

    def direct?
      size == 2
    end

    def descendant_id
      nodes.first
    end

    def ancestor_id
      nodes.last
    end

    def <=>(other)
      nodes <=> other.nodes
    end
  end
end
