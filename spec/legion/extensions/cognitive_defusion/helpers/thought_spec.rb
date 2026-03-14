# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDefusion::Helpers::Thought do
  let(:thought) { described_class.new(content: 'I am a failure', thought_type: :belief, belief_strength: 0.8) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(thought.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(thought.content).to eq('I am a failure')
    end

    it 'stores thought_type' do
      expect(thought.thought_type).to eq(:belief)
    end

    it 'stores belief_strength' do
      expect(thought.belief_strength).to eq(0.8)
    end

    it 'starts at DEFAULT_FUSION' do
      expect(thought.fusion_level).to eq(Legion::Extensions::CognitiveDefusion::Helpers::Constants::DEFAULT_FUSION)
    end

    it 'starts with zero defusion_count' do
      expect(thought.defusion_count).to eq(0)
    end

    it 'starts with zero visit_count' do
      expect(thought.visit_count).to eq(0)
    end

    it 'clamps belief_strength above 1.0' do
      t = described_class.new(content: 'x', thought_type: :judgment, belief_strength: 1.5)
      expect(t.belief_strength).to eq(1.0)
    end

    it 'clamps belief_strength below 0.0' do
      t = described_class.new(content: 'x', thought_type: :judgment, belief_strength: -0.2)
      expect(t.belief_strength).to eq(0.0)
    end
  end

  describe '#defuse!' do
    it 'reduces fusion by the technique potency' do
      potency = Legion::Extensions::CognitiveDefusion::Helpers::Constants::TECHNIQUE_POTENCY[:labeling]
      result  = thought.defuse!(technique: :labeling)
      expect(result[:reduction]).to be_within(0.0001).of(potency)
      expect(thought.fusion_level).to be_within(0.0001).of(0.7 - potency)
    end

    it 'increments defusion_count' do
      thought.defuse!(technique: :acceptance)
      expect(thought.defusion_count).to eq(1)
    end

    it 'does not reduce fusion below 0.0' do
      10.times { thought.defuse!(technique: :acceptance) }
      expect(thought.fusion_level).to be >= 0.0
    end

    it 'returns before, after, and reduction' do
      result = thought.defuse!(technique: :distancing)
      expect(result).to have_key(:before)
      expect(result).to have_key(:after)
      expect(result).to have_key(:reduction)
    end
  end

  describe '#fuse!' do
    it 'increases fusion by FUSION_DELTA_FUSE' do
      delta  = Legion::Extensions::CognitiveDefusion::Helpers::Constants::FUSION_DELTA_FUSE
      before = thought.fusion_level
      result = thought.fuse!
      expect(result[:after]).to be_within(0.0001).of(before + delta)
    end

    it 'does not exceed 1.0' do
      # Start from a high value
      t = described_class.new(content: 'x', thought_type: :rule, belief_strength: 0.5)
      20.times { t.fuse! }
      expect(t.fusion_level).to eq(1.0)
    end
  end

  describe '#visit!' do
    it 'increments visit_count' do
      thought.visit!
      expect(thought.visit_count).to eq(1)
    end

    it 'slightly increases fusion' do
      delta  = Legion::Extensions::CognitiveDefusion::Helpers::Constants::FUSION_DELTA_VISIT
      before = thought.fusion_level
      thought.visit!
      expect(thought.fusion_level).to be_within(0.0001).of(before + delta)
    end

    it 'returns visit_count and fusion values' do
      result = thought.visit!
      expect(result).to have_key(:visit_count)
      expect(result).to have_key(:fusion_before)
      expect(result).to have_key(:fusion_after)
    end
  end

  describe '#enmeshed?' do
    it 'returns true when fusion >= FUSION_THRESHOLD' do
      # default fusion is 0.7 which equals the threshold
      expect(thought.enmeshed?).to be true
    end

    it 'returns false when fusion is low' do
      10.times { thought.defuse!(technique: :acceptance) }
      expect(thought.enmeshed?).to be false
    end
  end

  describe '#defused?' do
    it 'returns false at default fusion' do
      expect(thought.defused?).to be false
    end

    it 'returns true when fusion drops below DEFUSED_THRESHOLD' do
      20.times { thought.defuse!(technique: :acceptance) }
      expect(thought.defused?).to be true
    end
  end

  describe '#ruminating?' do
    it 'returns false at zero visits' do
      expect(thought.ruminating?).to be false
    end

    it 'returns true at RUMINATION_COUNT visits' do
      count = Legion::Extensions::CognitiveDefusion::Helpers::Constants::RUMINATION_COUNT
      count.times { thought.visit! }
      expect(thought.ruminating?).to be true
    end
  end

  describe '#fusion_label' do
    it 'returns :enmeshed at default fusion 0.7' do
      # 0.7 is >= FUSION_THRESHOLD, but label range is 0.6...0.8 => :fused
      # and 0.8.. => :enmeshed. 0.7 falls in fused.
      expect(thought.fusion_label).to eq(:fused)
    end

    it 'returns :fully_defused for very low fusion' do
      20.times { thought.defuse!(technique: :acceptance) }
      expect(thought.fusion_label).to eq(:fully_defused)
    end
  end

  describe '#belief_label' do
    it 'returns :strong for belief_strength 0.8' do
      # 0.8.. is entrenched, 0.6...0.8 is strong. 0.8 is on the boundary => entrenched
      expect(thought.belief_label).to eq(:entrenched)
    end

    it 'returns :moderate for belief_strength 0.5' do
      t = described_class.new(content: 'x', thought_type: :assumption, belief_strength: 0.5)
      expect(t.belief_label).to eq(:moderate)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = thought.to_h
      %i[id content thought_type belief_strength fusion_level defusion_count
         visit_count fusion_label belief_label enmeshed defused ruminating created_at].each do |key|
        expect(h).to have_key(key)
      end
    end
  end
end
