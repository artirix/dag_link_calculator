require 'spec_helper'

describe DagLinkCalculator do
  it 'has a version number' do
    expect(DagLinkCalculator::VERSION).not_to be nil
  end

  context 'with valid direct links' do
    # we want to build from a node structure like this:
    #
    #  A --- B --- C --- D --- H
    #     |           |
    #     -- F --- E --
    #
    #
    # we receive the direct links info that describe that DAG like this:
    #
    # [
    #   { ancestor_id: 'A', descendant_id: 'B' },
    #   { ancestor_id: 'A', descendant_id: 'F' },
    #   { ancestor_id: 'B', descendant_id: 'C' },
    #   { ancestor_id: 'C', descendant_id: 'D' },
    #   { ancestor_id: 'F', descendant_id: 'E' },
    #   { ancestor_id: 'E', descendant_id: 'D' },
    #   { ancestor_id: 'D', descendant_id: 'H' },
    # ]
    #
    # we'll produce an intermediate structure (routes) like this:
    #
    #   #<struct DagLinkCalculator::NodeRoute nodes=['H', 'D']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'C']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'C', 'B']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'C', 'B', 'A']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'E']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'E', 'F']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'E', 'F', 'A']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['D', 'C']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['D', 'C', 'B']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['D', 'C', 'B', 'A']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['D', 'E']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['D', 'E', 'F']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['D', 'E', 'F', 'A']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['C', 'B']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['C', 'B', 'A']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['B', 'A']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['E', 'F']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['E', 'F', 'A']>
    #   #<struct DagLinkCalculator::NodeRoute nodes=['F', 'A']>
    #
    # and then return a list of link structures like this:
    #  { ancestor_id: 'A', descendant_id: 'B', direct: true, count: 1 }
    #  { ancestor_id: 'A', descendant_id: 'C', direct: false, count: 1 }
    #  { ancestor_id: 'A', descendant_id: 'D', direct: false, count: 2 }
    #  { ancestor_id: 'A', descendant_id: 'E', direct: false, count: 1 }
    #  { ancestor_id: 'A', descendant_id: 'F', direct: true, count: 1 }
    #  { ancestor_id: 'A', descendant_id: 'H', direct: false, count: 2 }
    #  { ancestor_id: 'B', descendant_id: 'C', direct: true, count: 1 }
    #  { ancestor_id: 'B', descendant_id: 'D', direct: false, count: 1 }
    #  { ancestor_id: 'B', descendant_id: 'H', direct: false, count: 1 }
    #  { ancestor_id: 'C', descendant_id: 'D', direct: true, count: 1 }
    #  { ancestor_id: 'C', descendant_id: 'H', direct: false, count: 1 }
    #  { ancestor_id: 'D', descendant_id: 'H', direct: true, count: 1 }
    #  { ancestor_id: 'F', descendant_id: 'E', direct: true, count: 1 }
    #  { ancestor_id: 'F', descendant_id: 'D', direct: false, count: 1 }
    #  { ancestor_id: 'F', descendant_id: 'H', direct: false, count: 1 }
    #  { ancestor_id: 'E', descendant_id: 'D', direct: true, count: 1 }
    #  { ancestor_id: 'E', descendant_id: 'H', direct: false, count: 1 }
    #

    let(:direct_links_hashes) do
      [
        { ancestor_id: 'A', descendant_id: 'B' },
        { ancestor: 'A', descendant_id: 'F' },
        { ancestor_id: 'B', descendant: 'C' },
        { parent_id: 'C', descendant_id: 'D' },
        { ancestor_id: 'F', child_id: 'E' },
        { parent_id: 'E', child_id: 'D' },
        { parent: 'D', child: 'H' },
      ]
    end

    let(:all_routes_structs) do
      [
        DagLinkCalculator::NodeRoute.new(['B', 'A']),
        DagLinkCalculator::NodeRoute.new(['C', 'B']),
        DagLinkCalculator::NodeRoute.new(['C', 'B', 'A']),
        DagLinkCalculator::NodeRoute.new(['D', 'C']),
        DagLinkCalculator::NodeRoute.new(['D', 'C', 'B']),
        DagLinkCalculator::NodeRoute.new(['D', 'C', 'B', 'A']),
        DagLinkCalculator::NodeRoute.new(['D', 'E']),
        DagLinkCalculator::NodeRoute.new(['D', 'E', 'F']),
        DagLinkCalculator::NodeRoute.new(['D', 'E', 'F', 'A']),
        DagLinkCalculator::NodeRoute.new(['E', 'F']),
        DagLinkCalculator::NodeRoute.new(['E', 'F', 'A']),
        DagLinkCalculator::NodeRoute.new(['F', 'A']),
        DagLinkCalculator::NodeRoute.new(['H', 'D']),
        DagLinkCalculator::NodeRoute.new(['H', 'D', 'C']),
        DagLinkCalculator::NodeRoute.new(['H', 'D', 'C', 'B']),
        DagLinkCalculator::NodeRoute.new(['H', 'D', 'C', 'B', 'A']),
        DagLinkCalculator::NodeRoute.new(['H', 'D', 'E']),
        DagLinkCalculator::NodeRoute.new(['H', 'D', 'E', 'F']),
        DagLinkCalculator::NodeRoute.new(['H', 'D', 'E', 'F', 'A']),
      ]
    end

    let(:all_links_structs) do
      [
        DagLinkCalculator::NodeLink.new('A', 'B', true, 1),
        DagLinkCalculator::NodeLink.new('A', 'C', false, 1),
        DagLinkCalculator::NodeLink.new('A', 'D', false, 2),
        DagLinkCalculator::NodeLink.new('A', 'E', false, 1),
        DagLinkCalculator::NodeLink.new('A', 'F', true, 1),
        DagLinkCalculator::NodeLink.new('A', 'H', false, 2),
        DagLinkCalculator::NodeLink.new('B', 'C', true, 1),
        DagLinkCalculator::NodeLink.new('B', 'D', false, 1),
        DagLinkCalculator::NodeLink.new('B', 'H', false, 1),
        DagLinkCalculator::NodeLink.new('C', 'D', true, 1),
        DagLinkCalculator::NodeLink.new('C', 'H', false, 1),
        DagLinkCalculator::NodeLink.new('D', 'H', true, 1),
        DagLinkCalculator::NodeLink.new('E', 'D', true, 1),
        DagLinkCalculator::NodeLink.new('E', 'H', false, 1),
        DagLinkCalculator::NodeLink.new('F', 'D', false, 1),
        DagLinkCalculator::NodeLink.new('F', 'E', true, 1),
        DagLinkCalculator::NodeLink.new('F', 'H', false, 1),
      ]
    end

    let(:all_links_hashes) do
      [
        { ancestor_id: 'A', descendant_id: 'B', direct: true, count: 1 },
        { ancestor_id: 'A', descendant_id: 'C', direct: false, count: 1 },
        { ancestor_id: 'A', descendant_id: 'D', direct: false, count: 2 },
        { ancestor_id: 'A', descendant_id: 'E', direct: false, count: 1 },
        { ancestor_id: 'A', descendant_id: 'F', direct: true, count: 1 },
        { ancestor_id: 'A', descendant_id: 'H', direct: false, count: 2 },
        { ancestor_id: 'B', descendant_id: 'C', direct: true, count: 1 },
        { ancestor_id: 'B', descendant_id: 'D', direct: false, count: 1 },
        { ancestor_id: 'B', descendant_id: 'H', direct: false, count: 1 },
        { ancestor_id: 'C', descendant_id: 'D', direct: true, count: 1 },
        { ancestor_id: 'C', descendant_id: 'H', direct: false, count: 1 },
        { ancestor_id: 'D', descendant_id: 'H', direct: true, count: 1 },
        { ancestor_id: 'E', descendant_id: 'D', direct: true, count: 1 },
        { ancestor_id: 'E', descendant_id: 'H', direct: false, count: 1 },
        { ancestor_id: 'F', descendant_id: 'D', direct: false, count: 1 },
        { ancestor_id: 'F', descendant_id: 'E', direct: true, count: 1 },
        { ancestor_id: 'F', descendant_id: 'H', direct: false, count: 1 },
      ]
    end

    subject { described_class.from_direct_links_hashes(direct_links_hashes) }

    describe '#all_routes_structs' do
      it 'returns list of structs describing all routes from a descendant node to each ancestor (sorted by id of each node in the route, starting from the descendant)' do
        expect(subject.all_routes_structs).to eq all_routes_structs.sort
      end
    end

    describe '#all_links_structs' do
      it 'returns list of structs with each descendant-ancestor pair describing if it is a direct or indirect link, including a count with how many routes have this pair (sorted by id of ancestor_id, then id of descendant_id)' do
        expect(subject.all_links_structs).to eq all_links_structs
      end
    end

    describe '#all_links_hashes' do
      it 'returns the same as #all_links_structs but expressed as hashes { ancestor_id: 1, descendant_id: 2, direct: true, count 1 }' do
        expect(subject.all_links_hashes).to eq all_links_hashes
      end
    end
  end
end
