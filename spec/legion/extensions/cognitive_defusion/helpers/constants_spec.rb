# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDefusion::Helpers::Constants do
  let(:mod) { described_class }

  describe 'DEFUSION_TECHNIQUES' do
    it 'contains expected techniques' do
      expect(mod::DEFUSION_TECHNIQUES).to include(:labeling, :distancing, :contextualization, :acceptance, :reframing, :metaphor)
    end

    it 'is frozen' do
      expect(mod::DEFUSION_TECHNIQUES).to be_frozen
    end
  end

  describe 'TECHNIQUE_POTENCY' do
    it 'has a potency for every technique' do
      mod::DEFUSION_TECHNIQUES.each do |technique|
        expect(mod::TECHNIQUE_POTENCY).to have_key(technique)
      end
    end

    it 'has acceptance as highest potency' do
      expect(mod::TECHNIQUE_POTENCY[:acceptance]).to eq(0.15)
    end

    it 'has metaphor as lowest potency' do
      expect(mod::TECHNIQUE_POTENCY[:metaphor]).to eq(0.06)
    end
  end

  describe 'FUSION_LABELS' do
    it 'labels 0.9 as enmeshed' do
      label = mod::FUSION_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:enmeshed)
    end

    it 'labels 0.7 as fused' do
      label = mod::FUSION_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:fused)
    end

    it 'labels 0.5 as partially_fused' do
      label = mod::FUSION_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:partially_fused)
    end

    it 'labels 0.1 as fully_defused' do
      label = mod::FUSION_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:fully_defused)
    end
  end

  describe 'BELIEF_LABELS' do
    it 'labels 0.9 as entrenched' do
      label = mod::BELIEF_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:entrenched)
    end

    it 'labels 0.15 as negligible' do
      label = mod::BELIEF_LABELS.find { |range, _| range.cover?(0.15) }&.last
      expect(label).to eq(:negligible)
    end
  end

  describe 'THOUGHT_TYPES' do
    it 'includes all expected types' do
      expect(mod::THOUGHT_TYPES).to include(:belief, :assumption, :evaluation, :prediction, :judgment, :self_concept, :rule)
    end

    it 'is frozen' do
      expect(mod::THOUGHT_TYPES).to be_frozen
    end
  end

  describe 'RECOMMENDED_TECHNIQUES' do
    it 'maps every thought type to a valid technique' do
      mod::THOUGHT_TYPES.each do |type|
        technique = mod::RECOMMENDED_TECHNIQUES[type]
        expect(mod::DEFUSION_TECHNIQUES).to include(technique), "No valid technique for #{type}"
      end
    end
  end
end
