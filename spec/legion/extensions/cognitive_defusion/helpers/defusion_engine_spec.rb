# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDefusion::Helpers::DefusionEngine do
  let(:engine) { described_class.new }

  def register(content: 'I must be perfect', thought_type: :belief, belief_strength: 0.8)
    engine.register_thought(content: content, thought_type: thought_type, belief_strength: belief_strength)
  end

  describe '#register_thought' do
    it 'creates a thought and returns its id' do
      result = register
      expect(result[:thought_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:thought]).to be_a(Hash)
    end

    it 'stores the thought in the engine' do
      result = register
      expect(engine.thoughts).to have_key(result[:thought_id])
    end

    it 'returns error for invalid thought_type' do
      result = engine.register_thought(content: 'x', thought_type: :invalid_type, belief_strength: 0.5)
      expect(result[:error]).to eq(:invalid_thought_type)
      expect(result[:valid]).to eq(Legion::Extensions::CognitiveDefusion::Helpers::Constants::THOUGHT_TYPES)
    end

    it 'accepts all valid thought types' do
      Legion::Extensions::CognitiveDefusion::Helpers::Constants::THOUGHT_TYPES.each do |type|
        result = engine.register_thought(content: "thought #{type}", thought_type: type, belief_strength: 0.5)
        expect(result[:thought_id]).not_to be_nil
      end
    end
  end

  describe '#apply_defusion' do
    let(:thought_id) { register[:thought_id] }

    it 'reduces fusion and returns result' do
      result = engine.apply_defusion(thought_id: thought_id, technique: :acceptance)
      expect(result[:success]).to be true
      expect(result[:after]).to be < result[:before]
    end

    it 'records the defusion in history' do
      engine.apply_defusion(thought_id: thought_id, technique: :labeling)
      expect(engine.defusion_history.size).to eq(1)
      expect(engine.defusion_history.first[:technique]).to eq(:labeling)
    end

    it 'returns error for unknown thought_id' do
      result = engine.apply_defusion(thought_id: 'nonexistent', technique: :labeling)
      expect(result[:error]).to eq(:thought_not_found)
    end

    it 'returns error for invalid technique' do
      result = engine.apply_defusion(thought_id: thought_id, technique: :voodoo)
      expect(result[:error]).to eq(:invalid_technique)
    end

    it 'includes fusion_label in result' do
      result = engine.apply_defusion(thought_id: thought_id, technique: :acceptance)
      expect(result[:fusion_label]).to be_a(Symbol)
    end
  end

  describe '#apply_all_techniques' do
    let(:thought_id) { register[:thought_id] }

    it 'applies all techniques and returns aggregated result' do
      result = engine.apply_all_techniques(thought_id: thought_id)
      expect(result[:total_applied]).to eq(Legion::Extensions::CognitiveDefusion::Helpers::Constants::DEFUSION_TECHNIQUES.size)
      expect(result[:final_fusion]).to be_a(Float)
    end

    it 'significantly reduces fusion' do
      initial = engine.thoughts[thought_id].fusion_level
      engine.apply_all_techniques(thought_id: thought_id)
      expect(engine.thoughts[thought_id].fusion_level).to be < initial
    end

    it 'returns error for unknown thought_id' do
      result = engine.apply_all_techniques(thought_id: 'nonexistent')
      expect(result[:error]).to eq(:thought_not_found)
    end
  end

  describe '#visit_thought' do
    let(:thought_id) { register[:thought_id] }

    it 'increments visit count' do
      result = engine.visit_thought(thought_id: thought_id)
      expect(result[:visit_count]).to eq(1)
    end

    it 'returns ruminating flag' do
      result = engine.visit_thought(thought_id: thought_id)
      expect(result).to have_key(:ruminating)
    end

    it 'returns error for unknown thought_id' do
      result = engine.visit_thought(thought_id: 'nonexistent')
      expect(result[:error]).to eq(:thought_not_found)
    end

    it 'becomes ruminating after RUMINATION_COUNT visits' do
      count = Legion::Extensions::CognitiveDefusion::Helpers::Constants::RUMINATION_COUNT
      count.times { engine.visit_thought(thought_id: thought_id) }
      result = engine.visit_thought(thought_id: thought_id)
      expect(result[:ruminating]).to be true
    end
  end

  describe '#enmeshed_thoughts' do
    it 'returns thoughts above fusion threshold' do
      register
      expect(engine.enmeshed_thoughts.size).to be >= 1
    end

    it 'excludes defused thoughts' do
      result = register
      tid = result[:thought_id]
      20.times { engine.apply_defusion(thought_id: tid, technique: :acceptance) }
      expect(engine.enmeshed_thoughts).not_to include(engine.thoughts[tid])
    end
  end

  describe '#defused_thoughts' do
    it 'returns empty when no thoughts are defused' do
      register
      expect(engine.defused_thoughts).to be_empty
    end

    it 'returns thought after full defusion' do
      result = register
      tid = result[:thought_id]
      20.times { engine.apply_defusion(thought_id: tid, technique: :acceptance) }
      expect(engine.defused_thoughts).to include(engine.thoughts[tid])
    end
  end

  describe '#ruminating_thoughts' do
    it 'returns empty with no visits' do
      register
      expect(engine.ruminating_thoughts).to be_empty
    end

    it 'returns thought after enough visits' do
      result = register
      tid = result[:thought_id]
      count = Legion::Extensions::CognitiveDefusion::Helpers::Constants::RUMINATION_COUNT
      count.times { engine.visit_thought(thought_id: tid) }
      expect(engine.ruminating_thoughts).not_to be_empty
    end
  end

  describe '#most_fused' do
    it 'returns thoughts sorted by fusion descending' do
      r1 = register(content: 'thought 1', thought_type: :belief, belief_strength: 0.8)
      r2 = register(content: 'thought 2', thought_type: :judgment, belief_strength: 0.5)
      # Defuse r2 to make r1 more fused
      5.times { engine.apply_defusion(thought_id: r2[:thought_id], technique: :acceptance) }

      top = engine.most_fused(limit: 2)
      expect(top.first.id).to eq(r1[:thought_id])
    end

    it 'respects the limit parameter' do
      5.times { |i| register(content: "thought #{i}", thought_type: :belief, belief_strength: 0.5) }
      expect(engine.most_fused(limit: 2).size).to eq(2)
    end
  end

  describe '#recommend_technique' do
    it 'returns a recommended technique for the thought type' do
      result = register
      rec = engine.recommend_technique(thought_id: result[:thought_id])
      expect(rec[:technique]).to be_a(Symbol)
      expect(Legion::Extensions::CognitiveDefusion::Helpers::Constants::DEFUSION_TECHNIQUES).to include(rec[:technique])
    end

    it 'recommends acceptance for belief type' do
      result = register(thought_type: :belief)
      rec = engine.recommend_technique(thought_id: result[:thought_id])
      expect(rec[:technique]).to eq(:acceptance)
    end

    it 'returns error for unknown thought_id' do
      result = engine.recommend_technique(thought_id: 'nonexistent')
      expect(result[:error]).to eq(:thought_not_found)
    end

    it 'includes projected_fusion' do
      result = register
      rec = engine.recommend_technique(thought_id: result[:thought_id])
      expect(rec[:projected_fusion]).to be < rec[:current_fusion]
    end
  end

  describe '#average_fusion' do
    it 'returns 0.0 with no thoughts' do
      expect(engine.average_fusion).to eq(0.0)
    end

    it 'returns DEFAULT_FUSION when all thoughts are fresh' do
      2.times { register }
      expect(engine.average_fusion).to be_within(0.001).of(Legion::Extensions::CognitiveDefusion::Helpers::Constants::DEFAULT_FUSION)
    end

    it 'decreases as thoughts are defused' do
      result = register
      before_avg = engine.average_fusion
      10.times { engine.apply_defusion(thought_id: result[:thought_id], technique: :acceptance) }
      expect(engine.average_fusion).to be < before_avg
    end
  end

  describe '#defusion_effectiveness' do
    it 'returns 0.0 with no history' do
      expect(engine.defusion_effectiveness).to eq(0.0)
    end

    it 'returns positive value after defusion attempts' do
      result = register
      engine.apply_defusion(thought_id: result[:thought_id], technique: :acceptance)
      expect(engine.defusion_effectiveness).to be > 0.0
    end
  end

  describe '#defusion_report' do
    it 'includes all expected keys' do
      register
      report = engine.defusion_report
      %i[total_thoughts enmeshed_count defused_count ruminating_count average_fusion
         defusion_attempts defusion_effectiveness most_fused].each do |key|
        expect(report).to have_key(key)
      end
    end
  end

  describe '#to_h' do
    it 'includes thoughts, defusion_history, and report' do
      register
      h = engine.to_h
      expect(h).to have_key(:thoughts)
      expect(h).to have_key(:defusion_history)
      expect(h).to have_key(:report)
    end
  end
end
