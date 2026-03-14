# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDefusion::Runners::CognitiveDefusion do
  let(:engine) { Legion::Extensions::CognitiveDefusion::Helpers::DefusionEngine.new }
  let(:client) { Legion::Extensions::CognitiveDefusion::Client.new(engine: engine) }

  def reg(content: 'I will fail', thought_type: :belief, belief_strength: 0.8)
    client.register_thought(content: content, thought_type: thought_type, belief_strength: belief_strength, engine: engine)
  end

  describe '#register_thought' do
    it 'returns success true for valid input' do
      result = reg
      expect(result[:success]).to be true
    end

    it 'returns the thought_id' do
      result = reg
      expect(result[:thought_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns success false for invalid thought_type' do
      result = client.register_thought(content: 'x', thought_type: :bad, belief_strength: 0.5, engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_thought_type)
    end

    it 'accepts an injected engine' do
      other_engine = Legion::Extensions::CognitiveDefusion::Helpers::DefusionEngine.new
      result = client.register_thought(content: 'test', thought_type: :judgment, belief_strength: 0.5, engine: other_engine)
      expect(result[:success]).to be true
      expect(other_engine.thoughts.size).to eq(1)
    end
  end

  describe '#apply_defusion' do
    let(:thought_id) { reg[:thought_id] }

    it 'returns success and fusion reduction' do
      result = client.apply_defusion(thought_id: thought_id, technique: :acceptance, engine: engine)
      expect(result[:success]).to be true
      expect(result[:reduction]).to be > 0.0
    end

    it 'returns success false for invalid thought_id' do
      result = client.apply_defusion(thought_id: 'nope', technique: :labeling, engine: engine)
      expect(result[:success]).to be false
    end

    it 'returns success false for invalid technique' do
      result = client.apply_defusion(thought_id: thought_id, technique: :made_up, engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#apply_all_techniques' do
    let(:thought_id) { reg[:thought_id] }

    it 'applies all techniques and returns success' do
      result = client.apply_all_techniques(thought_id: thought_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:total_applied]).to eq(Legion::Extensions::CognitiveDefusion::Helpers::Constants::DEFUSION_TECHNIQUES.size)
    end

    it 'returns success false for unknown thought' do
      result = client.apply_all_techniques(thought_id: 'missing', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#visit_thought' do
    let(:thought_id) { reg[:thought_id] }

    it 'returns success with visit_count' do
      result = client.visit_thought(thought_id: thought_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:visit_count]).to eq(1)
    end

    it 'returns success false for unknown thought' do
      result = client.visit_thought(thought_id: 'missing', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#fuse_thought' do
    let(:thought_id) { reg[:thought_id] }

    it 'increases fusion and returns enmeshed flag' do
      result = client.fuse_thought(thought_id: thought_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:after]).to be > result[:before]
    end

    it 'returns success false for unknown thought' do
      result = client.fuse_thought(thought_id: 'missing', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#enmeshed_thoughts' do
    it 'returns count and thoughts array' do
      reg
      result = client.enmeshed_thoughts(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
      expect(result[:thoughts]).to be_an(Array)
    end
  end

  describe '#defused_thoughts' do
    it 'returns empty when no thoughts are defused' do
      reg
      result = client.defused_thoughts(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'returns thought after being defused' do
      tid = reg[:thought_id]
      20.times { client.apply_defusion(thought_id: tid, technique: :acceptance, engine: engine) }
      result = client.defused_thoughts(engine: engine)
      expect(result[:count]).to be >= 1
    end
  end

  describe '#ruminating_thoughts' do
    it 'returns empty with no visits' do
      reg
      result = client.ruminating_thoughts(engine: engine)
      expect(result[:count]).to eq(0)
    end

    it 'returns thought after enough visits' do
      tid = reg[:thought_id]
      Legion::Extensions::CognitiveDefusion::Helpers::Constants::RUMINATION_COUNT.times do
        client.visit_thought(thought_id: tid, engine: engine)
      end
      result = client.ruminating_thoughts(engine: engine)
      expect(result[:count]).to be >= 1
    end
  end

  describe '#most_fused' do
    it 'returns success with thoughts array' do
      reg
      result = client.most_fused(limit: 3, engine: engine)
      expect(result[:success]).to be true
      expect(result[:thoughts]).to be_an(Array)
    end
  end

  describe '#recommend_technique' do
    let(:thought_id) { reg[:thought_id] }

    it 'returns success with technique recommendation' do
      result = client.recommend_technique(thought_id: thought_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:technique]).to be_a(Symbol)
    end

    it 'returns success false for unknown thought' do
      result = client.recommend_technique(thought_id: 'missing', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#defusion_report' do
    it 'returns success with full report' do
      reg
      result = client.defusion_report(engine: engine)
      expect(result[:success]).to be true
      expect(result[:total_thoughts]).to be >= 1
    end
  end

  describe '#defusion_state' do
    it 'returns full engine state' do
      reg
      result = client.defusion_state(engine: engine)
      expect(result[:success]).to be true
      expect(result).to have_key(:thoughts)
    end
  end
end
