# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDefusion::Client do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a client with a default engine' do
      expect(client).to respond_to(:register_thought)
    end

    it 'accepts an injected engine' do
      engine = Legion::Extensions::CognitiveDefusion::Helpers::DefusionEngine.new
      c      = described_class.new(engine: engine)
      expect(c).to respond_to(:register_thought)
    end
  end

  describe 'runner method delegation' do
    it 'responds to all runner methods' do
      %i[
        register_thought apply_defusion apply_all_techniques visit_thought
        fuse_thought enmeshed_thoughts defused_thoughts ruminating_thoughts
        most_fused recommend_technique defusion_report defusion_state
      ].each do |method|
        expect(client).to respond_to(method)
      end
    end
  end

  describe 'full workflow integration' do
    it 'registers, defuses, and reports on a thought cycle' do
      # Register a fused thought
      reg = client.register_thought(content: 'I am not good enough', thought_type: :self_concept, belief_strength: 0.9)
      expect(reg[:success]).to be true
      tid = reg[:thought_id]

      # Recommend a technique
      rec = client.recommend_technique(thought_id: tid)
      expect(rec[:technique]).to eq(:distancing)

      # Apply defusion
      defused = client.apply_defusion(thought_id: tid, technique: rec[:technique])
      expect(defused[:success]).to be true
      expect(defused[:after]).to be < defused[:before]

      # Check report
      report = client.defusion_report
      expect(report[:total_thoughts]).to eq(1)
      expect(report[:defusion_attempts]).to eq(1)
      expect(report[:defusion_effectiveness]).to be > 0.0
    end

    it 'tracks enmeshed and defused thoughts over multiple operations' do
      # Register two thoughts
      t1 = client.register_thought(content: 'thought 1', thought_type: :belief, belief_strength: 0.8)
      t2 = client.register_thought(content: 'thought 2', thought_type: :judgment, belief_strength: 0.6)

      # Fully defuse t1
      20.times { client.apply_defusion(thought_id: t1[:thought_id], technique: :acceptance) }

      # t2 remains enmeshed
      enmeshed = client.enmeshed_thoughts
      defused  = client.defused_thoughts

      expect(enmeshed[:count]).to eq(1)
      expect(defused[:count]).to eq(1)
      expect(enmeshed[:thoughts].first[:id]).to eq(t2[:thought_id])
    end

    it 'detects rumination after repeated visits' do
      reg = client.register_thought(content: 'am I enough?', thought_type: :evaluation, belief_strength: 0.6)
      tid = reg[:thought_id]

      Legion::Extensions::CognitiveDefusion::Helpers::Constants::RUMINATION_COUNT.times { client.visit_thought(thought_id: tid) }

      rum = client.ruminating_thoughts
      expect(rum[:count]).to eq(1)
    end
  end
end
