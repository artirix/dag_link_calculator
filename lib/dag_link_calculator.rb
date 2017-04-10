require 'dag_link_calculator/version'
require 'dag_link_calculator/direct_link'
require 'dag_link_calculator/node_link'
require 'dag_link_calculator/node_route'
require 'dag_link_calculator/calculator'

module DagLinkCalculator
  def self.from_direct_links_structs(direct_links_structs)
    Calculator.new(direct_links_structs)
  end

  def self.from_direct_links_hashes(direct_links_hashes)
    direct_links_structs = direct_links_hashes.map { |h| DirectLink.from_hash(h) }
    from_direct_links_structs(direct_links_structs)
  end
end
