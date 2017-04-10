module DagLinkCalculator
  class Calculator
    attr_reader :direct_links_structs

    def initialize(direct_links_structs)
      @direct_links_structs = direct_links_structs
    end

    def all_links_hashes
      @all_links_hashes ||= build_all_links_hashes
    end

    def all_links_structs
      @all_links_structs ||= build_all_links_structs
    end

    def all_routes_structs
      @all_routes_structs ||= build_all_routes_structs
    end

    def parents_map
      @parent_map ||= build_parents_map
    end

    def parents_of(descendant_id)
      parents_map[descendant_id] || []
    end

    private

    def build_all_links_hashes
      all_links_structs.map &:to_hash
    end

    def build_all_links_structs
      grouped = all_routes_structs.group_by { |node_route| [node_route.descendant_id, node_route.ancestor_id] }
      grouped.map do |(descendant_id, ancestor_id), list|
        count = list.size
        direct = list.any? &:direct?
        NodeLink.new(ancestor_id, descendant_id, direct, count)
      end.sort
    end

    def build_all_routes_structs
      parents_map.keys.map do |descendant_id|
        routes_for_node descendant_id
      end.flatten.sort
    end

    def build_parents_map
      direct_links_structs
        .group_by(&:descendant_id)
        .map { |k, list| [k, list.map(&:ancestor_id)] }
        .to_h
    end

    def routes_for_node(node_id)
      @routes_map ||= {}
      @routes_map[node_id] ||= build_routes_for_node node_id
    end

    def build_routes_for_node(node_id)
      parents_of(node_id).map do |parent_id|
        from_parent_routes = routes_for_node(parent_id).map { |r| NodeRoute.new([node_id].concat(r.nodes)) }
        [NodeRoute.new([node_id, parent_id])].concat(from_parent_routes)
      end.flatten
    end
  end
end
