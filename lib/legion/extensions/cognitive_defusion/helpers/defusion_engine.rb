# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDefusion
      module Helpers
        class DefusionEngine
          include Constants

          attr_reader :thoughts, :defusion_history

          def initialize
            @thoughts         = {}
            @defusion_history = []
          end

          def register_thought(content:, thought_type:, belief_strength: 0.5)
            return { error: :invalid_thought_type, valid: THOUGHT_TYPES } unless THOUGHT_TYPES.include?(thought_type)

            if @thoughts.size >= MAX_THOUGHTS
              oldest = @thoughts.values.min_by(&:created_at)
              @thoughts.delete(oldest.id) if oldest
            end

            thought = Thought.new(content: content, thought_type: thought_type, belief_strength: belief_strength)
            @thoughts[thought.id] = thought
            { thought_id: thought.id, thought: thought.to_h }
          end

          def apply_defusion(thought_id:, technique:)
            thought = @thoughts[thought_id]
            return { error: :thought_not_found } unless thought
            return { error: :invalid_technique, valid: DEFUSION_TECHNIQUES } unless DEFUSION_TECHNIQUES.include?(technique)

            before_fusion = thought.fusion_level
            result = thought.defuse!(technique: technique)

            @defusion_history << {
              thought_id:    thought_id,
              technique:     technique,
              before_fusion: before_fusion,
              after_fusion:  thought.fusion_level,
              at:            Time.now.utc
            }

            {
              success:      true,
              thought_id:   thought_id,
              technique:    technique,
              before:       result[:before],
              after:        result[:after],
              reduction:    result[:reduction],
              fusion_label: thought.fusion_label,
              defused:      thought.defused?
            }
          end

          def apply_all_techniques(thought_id:)
            thought = @thoughts[thought_id]
            return { error: :thought_not_found } unless thought

            results = DEFUSION_TECHNIQUES.map do |technique|
              apply_defusion(thought_id: thought_id, technique: technique)
            end

            {
              thought_id:    thought_id,
              techniques:    results,
              final_fusion:  thought.fusion_level,
              fusion_label:  thought.fusion_label,
              defused:       thought.defused?,
              total_applied: results.size
            }
          end

          def visit_thought(thought_id:)
            thought = @thoughts[thought_id]
            return { error: :thought_not_found } unless thought

            result = thought.visit!
            {
              thought_id:  thought_id,
              visit_count: result[:visit_count],
              fusion:      thought.fusion_level,
              ruminating:  thought.ruminating?
            }
          end

          def enmeshed_thoughts
            @thoughts.values.select(&:enmeshed?)
          end

          def defused_thoughts
            @thoughts.values.select(&:defused?)
          end

          def ruminating_thoughts
            @thoughts.values.select(&:ruminating?)
          end

          def most_fused(limit: 5)
            @thoughts.values
                     .sort_by { |t| -t.fusion_level }
                     .first(limit)
          end

          def recommend_technique(thought_id:)
            thought = @thoughts[thought_id]
            return { error: :thought_not_found } unless thought

            technique = RECOMMENDED_TECHNIQUES.fetch(thought.thought_type, :acceptance)
            potency   = TECHNIQUE_POTENCY[technique]

            {
              thought_id:        thought_id,
              thought_type:      thought.thought_type,
              technique:         technique,
              potency:           potency,
              current_fusion:    thought.fusion_level,
              projected_fusion:  (thought.fusion_level - potency).clamp(0.0, 1.0).round(10)
            }
          end

          def average_fusion
            return 0.0 if @thoughts.empty?

            total = @thoughts.values.sum(&:fusion_level)
            (total / @thoughts.size).round(10)
          end

          def defusion_effectiveness
            return 0.0 if @defusion_history.empty?

            total_reduction = @defusion_history.sum { |h| h[:before_fusion] - h[:after_fusion] }
            (total_reduction / @defusion_history.size).round(10)
          end

          def defusion_report
            all = @thoughts.values
            {
              total_thoughts:       all.size,
              enmeshed_count:       all.count(&:enmeshed?),
              defused_count:        all.count(&:defused?),
              ruminating_count:     all.count(&:ruminating?),
              average_fusion:       average_fusion,
              defusion_attempts:    @defusion_history.size,
              defusion_effectiveness: defusion_effectiveness,
              most_fused:           most_fused(limit: 3).map(&:to_h)
            }
          end

          def to_h
            {
              thoughts:         @thoughts.transform_values(&:to_h),
              defusion_history: @defusion_history,
              report:           defusion_report
            }
          end
        end
      end
    end
  end
end
