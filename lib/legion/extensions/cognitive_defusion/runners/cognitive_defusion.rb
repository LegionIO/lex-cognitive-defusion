# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDefusion
      module Runners
        module CognitiveDefusion
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def register_thought(content:, thought_type:, belief_strength: 0.5, engine: nil, **)
            eng    = engine || defusion_engine
            result = eng.register_thought(content: content, thought_type: thought_type, belief_strength: belief_strength)
            return { success: false, **result } if result[:error]

            Legion::Logging.debug "[cognitive_defusion] registered thought type=#{thought_type} " \
                                  "belief=#{belief_strength.round(2)} id=#{result[:thought_id]}"
            { success: true, **result }
          end

          def apply_defusion(thought_id:, technique:, engine: nil, **)
            eng    = engine || defusion_engine
            result = eng.apply_defusion(thought_id: thought_id, technique: technique)
            return { success: false, **result } if result[:error]

            Legion::Logging.debug "[cognitive_defusion] defusion applied technique=#{technique} " \
                                  "reduction=#{result[:reduction]&.round(4)} fusion=#{result[:after]&.round(4)}"
            result
          end

          def apply_all_techniques(thought_id:, engine: nil, **)
            eng    = engine || defusion_engine
            result = eng.apply_all_techniques(thought_id: thought_id)
            return { success: false, **result } if result[:error]

            Legion::Logging.debug "[cognitive_defusion] all techniques applied thought_id=#{thought_id} " \
                                  "final_fusion=#{result[:final_fusion]&.round(4)}"
            { success: true, **result }
          end

          def visit_thought(thought_id:, engine: nil, **)
            eng    = engine || defusion_engine
            result = eng.visit_thought(thought_id: thought_id)
            return { success: false, **result } if result[:error]

            Legion::Logging.debug "[cognitive_defusion] thought visited count=#{result[:visit_count]} " \
                                  "ruminating=#{result[:ruminating]}"
            { success: true, **result }
          end

          def fuse_thought(thought_id:, engine: nil, **)
            eng    = engine || defusion_engine
            thought = eng.thoughts[thought_id]
            return { success: false, error: :thought_not_found } unless thought

            result = thought.fuse!
            Legion::Logging.debug "[cognitive_defusion] thought fused before=#{result[:before].round(4)} " \
                                  "after=#{result[:after].round(4)}"
            { success: true, thought_id: thought_id, before: result[:before], after: result[:after], enmeshed: thought.enmeshed? }
          end

          def enmeshed_thoughts(engine: nil, **)
            eng      = engine || defusion_engine
            thoughts = eng.enmeshed_thoughts.map(&:to_h)
            Legion::Logging.debug "[cognitive_defusion] enmeshed thoughts count=#{thoughts.size}"
            { success: true, count: thoughts.size, thoughts: thoughts }
          end

          def defused_thoughts(engine: nil, **)
            eng      = engine || defusion_engine
            thoughts = eng.defused_thoughts.map(&:to_h)
            Legion::Logging.debug "[cognitive_defusion] defused thoughts count=#{thoughts.size}"
            { success: true, count: thoughts.size, thoughts: thoughts }
          end

          def ruminating_thoughts(engine: nil, **)
            eng      = engine || defusion_engine
            thoughts = eng.ruminating_thoughts.map(&:to_h)
            Legion::Logging.debug "[cognitive_defusion] ruminating thoughts count=#{thoughts.size}"
            { success: true, count: thoughts.size, thoughts: thoughts }
          end

          def most_fused(limit: 5, engine: nil, **)
            eng      = engine || defusion_engine
            thoughts = eng.most_fused(limit: limit).map(&:to_h)
            Legion::Logging.debug "[cognitive_defusion] most fused count=#{thoughts.size}"
            { success: true, count: thoughts.size, thoughts: thoughts }
          end

          def recommend_technique(thought_id:, engine: nil, **)
            eng    = engine || defusion_engine
            result = eng.recommend_technique(thought_id: thought_id)
            return { success: false, **result } if result[:error]

            Legion::Logging.debug "[cognitive_defusion] technique recommended=#{result[:technique]} " \
                                  "for type=#{result[:thought_type]}"
            { success: true, **result }
          end

          def defusion_report(engine: nil, **)
            eng    = engine || defusion_engine
            report = eng.defusion_report
            Legion::Logging.debug "[cognitive_defusion] report: total=#{report[:total_thoughts]} " \
                                  "enmeshed=#{report[:enmeshed_count]} avg_fusion=#{report[:average_fusion].round(4)}"
            { success: true, **report }
          end

          def defusion_state(engine: nil, **)
            eng = engine || defusion_engine
            Legion::Logging.debug '[cognitive_defusion] state queried'
            { success: true, **eng.to_h }
          end

          private

          def defusion_engine
            @defusion_engine ||= Helpers::DefusionEngine.new
          end
        end
      end
    end
  end
end
