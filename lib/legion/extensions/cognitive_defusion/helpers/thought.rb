# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveDefusion
      module Helpers
        class Thought
          include Constants

          attr_reader :id, :content, :thought_type, :belief_strength,
                      :fusion_level, :defusion_count, :visit_count, :created_at

          def initialize(content:, thought_type:, belief_strength:)
            @id              = SecureRandom.uuid
            @content         = content
            @thought_type    = thought_type
            @belief_strength = belief_strength.clamp(0.0, 1.0)
            @fusion_level    = DEFAULT_FUSION
            @defusion_count  = 0
            @visit_count     = 0
            @created_at      = Time.now.utc
          end

          def defuse!(technique:)
            potency = TECHNIQUE_POTENCY.fetch(technique, 0.0)
            before  = @fusion_level
            @fusion_level = (@fusion_level - potency).clamp(0.0, 1.0).round(10)
            @defusion_count += 1
            { before: before, after: @fusion_level, technique: technique, reduction: (before - @fusion_level).round(10) }
          end

          def fuse!
            before = @fusion_level
            @fusion_level = (@fusion_level + FUSION_DELTA_FUSE).clamp(0.0, 1.0).round(10)
            { before: before, after: @fusion_level }
          end

          def visit!
            @visit_count += 1
            before = @fusion_level
            @fusion_level = (@fusion_level + FUSION_DELTA_VISIT).clamp(0.0, 1.0).round(10)
            { visit_count: @visit_count, fusion_before: before, fusion_after: @fusion_level }
          end

          def enmeshed?
            @fusion_level >= FUSION_THRESHOLD
          end

          def defused?
            @fusion_level <= DEFUSED_THRESHOLD
          end

          def ruminating?
            @visit_count >= RUMINATION_COUNT
          end

          def fusion_label
            FUSION_LABELS.find { |range, _| range.cover?(@fusion_level) }&.last || :unknown
          end

          def belief_label
            BELIEF_LABELS.find { |range, _| range.cover?(@belief_strength) }&.last || :unknown
          end

          def to_h
            {
              id:              @id,
              content:         @content,
              thought_type:    @thought_type,
              belief_strength: @belief_strength,
              fusion_level:    @fusion_level,
              defusion_count:  @defusion_count,
              visit_count:     @visit_count,
              fusion_label:    fusion_label,
              belief_label:    belief_label,
              enmeshed:        enmeshed?,
              defused:         defused?,
              ruminating:      ruminating?,
              created_at:      @created_at
            }
          end
        end
      end
    end
  end
end
