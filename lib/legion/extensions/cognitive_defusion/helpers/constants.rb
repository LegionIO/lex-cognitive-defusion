# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDefusion
      module Helpers
        module Constants
          MAX_THOUGHTS       = 300
          DEFAULT_FUSION     = 0.7
          FUSION_DELTA_FUSE  = 0.05
          FUSION_DELTA_VISIT = 0.02

          DEFUSION_TECHNIQUES = %i[labeling distancing contextualization acceptance reframing metaphor].freeze

          TECHNIQUE_POTENCY = {
            labeling:          0.08,
            distancing:        0.12,
            contextualization: 0.10,
            acceptance:        0.15,
            reframing:         0.10,
            metaphor:          0.06
          }.freeze

          FUSION_LABELS = {
            (0.8..)      => :enmeshed,
            (0.6...0.8)  => :fused,
            (0.4...0.6)  => :partially_fused,
            (0.2...0.4)  => :defused,
            (..0.2)      => :fully_defused
          }.freeze

          BELIEF_LABELS = {
            (0.8..)      => :entrenched,
            (0.6...0.8)  => :strong,
            (0.4...0.6)  => :moderate,
            (0.2...0.4)  => :weak,
            (..0.2)      => :negligible
          }.freeze

          FUSION_THRESHOLD  = 0.7
          DEFUSED_THRESHOLD = 0.3
          RUMINATION_COUNT  = 3

          THOUGHT_TYPES = %i[belief assumption evaluation prediction judgment self_concept rule].freeze

          # Technique recommendations by thought type
          RECOMMENDED_TECHNIQUES = {
            belief:       :acceptance,
            assumption:   :contextualization,
            evaluation:   :distancing,
            prediction:   :reframing,
            judgment:     :labeling,
            self_concept: :distancing,
            rule:         :contextualization
          }.freeze
        end
      end
    end
  end
end
