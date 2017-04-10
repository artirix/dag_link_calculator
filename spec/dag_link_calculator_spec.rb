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

  context DagLinkCalculator::DirectLink do
    describe '.from_hash' do
      let(:ancestor_id) { 1 }
      let(:ancestor) { 2 }
      let(:parent_id) { 3 }
      let(:parent) { 4 }

      let(:descendant_id) { 'a' }
      let(:child_id) { 'b' }
      let(:descendant) { 'c' }
      let(:child) { 'd' }

      let(:hash) do
        {
          ancestor_id: ancestor_id,
          ancestor: ancestor,
          parent_id: parent_id,
          parent: parent,

          descendant_id: descendant_id,
          child_id: child_id,
          descendant: descendant,
          child: child,

          other: :stuff
        }
      end

      context 'parsing ancestor' do
        it 'parses :ancestor_id as ancestor' do
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.ancestor_id).to eq ancestor_id
        end

        it 'parses :ancestor as ancestor, if :ancestor_id not found' do
          hash.delete :ancestor_id
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.ancestor_id).to eq ancestor
        end

        it 'parses :parent_id as ancestor, if :ancestor_id and :ancestor not found' do
          hash.delete :ancestor_id
          hash.delete :ancestor
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.ancestor_id).to eq parent_id
        end

        it 'parses :parent as ancestor, if :ancestor_id and :ancestor and :parent_id not found' do
          hash.delete :ancestor_id
          hash.delete :ancestor
          hash.delete :parent_id
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.ancestor_id).to eq parent
        end
      end

      context 'parsing descendant' do
        it 'parses :descendant_id as descendant' do
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.descendant_id).to eq descendant_id
        end

        it 'parses :descendant as descendant, if :descendant_id not found' do
          hash.delete :descendant_id
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.descendant_id).to eq descendant
        end

        it 'parses :child_id as descendant, if :descendant_id and :descendant not found' do
          hash.delete :descendant_id
          hash.delete :descendant
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.descendant_id).to eq child_id
        end

        it 'parses :child as descendant, if :descendant_id and :descendant and :child_id not found' do
          hash.delete :descendant_id
          hash.delete :descendant
          hash.delete :child_id
          res = DagLinkCalculator::DirectLink.from_hash(hash)
          expect(res.descendant_id).to eq child
        end
      end
    end

    context 'instance' do
      let(:ancestor) { 1 }
      let(:descendant) { 2 }
      let(:hash) do
        { ancestor: ancestor, descendant: descendant }
      end

      subject { DagLinkCalculator::DirectLink.from_hash hash }

      describe '#direct?' do
        it { expect(subject.direct?).to be_truthy }
      end

      describe '#direct' do
        it { expect(subject.direct?).to be_truthy }
      end

      describe '#count' do
        it { expect(subject.count).to eq 1 }
      end

      describe '#to_link' do
        let(:expected_link) { DagLinkCalculator::NodeLink.new(ancestor, descendant, true, 1) }

        it 'creates a link with direct = true and count = 1' do
          link = subject.to_link
          expect(link.to_hash).to eq expected_link.to_hash
          expect(link.direct?).to eq expected_link.direct?
          expect(link.direct).to eq expected_link.direct
          expect(link.direct).to eq true
          expect(link.count).to eq expected_link.count
          expect(link.count).to eq 1
        end
      end

      describe 'sorting' do
        let(:link1) { DagLinkCalculator::DirectLink.new(1, 20) }
        let(:link2) { DagLinkCalculator::DirectLink.new(2, 20) }
        let(:link3) { DagLinkCalculator::DirectLink.new(3, 10) }
        let(:link4) { DagLinkCalculator::DirectLink.new(3, 20) }

        let(:expected_list) { [link1, link2, link3, link4] }

        it 'sorts by ancestor ASC, then descendant DESC' do
          list = [link4, link2, link3, link1]
          expect(list.sort).to eq expected_list
          5.times do
            expect(list.shuffle.sort).to eq expected_list
          end
        end
      end
    end
  end

end
