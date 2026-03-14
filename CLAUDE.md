# lex-cognitive-defusion

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Cognitive defusion (ACT — Acceptance and Commitment Therapy) for brain-modeled agentic AI. Enables the agent to step back from thoughts and observe them as mental events rather than literal truths. Reduces the behavioral influence of fused (entrenched) thoughts through six defusion techniques.

## Gem Info

- **Gem name**: `lex-cognitive-defusion`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveDefusion`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_defusion/
  cognitive_defusion.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    defusion_engine.rb
    thought.rb
  runners/
    cognitive_defusion.rb
```

## Key Constants

From `helpers/constants.rb`:

- `THOUGHT_TYPES` — `%i[belief assumption evaluation prediction judgment self_concept rule]`
- `DEFUSION_TECHNIQUES` — `%i[labeling distancing contextualization acceptance reframing metaphor]`
- `TECHNIQUE_POTENCY` — per-technique fusion reduction: `acceptance: 0.15`, `distancing: 0.12`, `contextualization: 0.10`, `reframing: 0.10`, `labeling: 0.08`, `metaphor: 0.06`
- `RECOMMENDED_TECHNIQUES` — per thought type: `belief: :acceptance`, `assumption: :contextualization`, `evaluation: :distancing`, `prediction: :reframing`, `judgment: :labeling`, `self_concept: :distancing`, `rule: :contextualization`
- `MAX_THOUGHTS` = `300`
- `DEFAULT_FUSION` = `0.7`, `FUSION_DELTA_FUSE` = `0.05`, `FUSION_DELTA_VISIT` = `0.02`
- `FUSION_THRESHOLD` = `0.7`, `DEFUSED_THRESHOLD` = `0.3`, `RUMINATION_COUNT` = `3`
- `FUSION_LABELS` — `0.8+` = `:enmeshed`, `0.6` = `:fused`, `0.4` = `:partially_fused`, `0.2` = `:defused`, below = `:fully_defused`
- `BELIEF_LABELS` — `0.8+` = `:entrenched` through below `0.2` = `:negligible`

## Runners

All methods in `Runners::CognitiveDefusion`:

- `register_thought(content:, thought_type:, belief_strength: 0.5)` — registers a thought at default fusion level
- `apply_defusion(thought_id:, technique:)` — applies one defusion technique; reduces fusion by technique potency
- `apply_all_techniques(thought_id:)` — applies all six techniques in sequence; returns final fusion level
- `visit_thought(thought_id:)` — marks a visit; fusion increases by `FUSION_DELTA_VISIT`; detects rumination (visit_count >= `RUMINATION_COUNT`)
- `fuse_thought(thought_id:)` — increases fusion by `FUSION_DELTA_FUSE`; marks as enmeshed if >= threshold
- `enmeshed_thoughts` — thoughts with fusion >= `FUSION_THRESHOLD`
- `defused_thoughts` — thoughts with fusion <= `DEFUSED_THRESHOLD`
- `ruminating_thoughts` — thoughts visited >= `RUMINATION_COUNT` times
- `most_fused(limit: 5)` — top thoughts by fusion level
- `recommend_technique(thought_id:)` — returns the recommended technique for the thought's type
- `defusion_report` — full report: totals, enmeshed count, average fusion
- `defusion_state` — raw engine state

## Helpers

- `DefusionEngine` — manages thoughts. `apply_defusion` looks up technique potency and reduces fusion. `apply_all_techniques` runs all techniques sequentially. `enmeshed_thoughts` / `defused_thoughts` filter by thresholds.
- `Thought` — has `content`, `thought_type`, `fusion_level`, `belief_strength`, `visit_count`. `apply_technique!(technique)` reduces fusion. `fuse!` increases fusion. `enmeshed?`, `defused?`, `ruminating?` predicates.

## Integration Points

- `lex-cognitive-dissonance-resolution` handles conflicting beliefs; defusion is a prerequisite — enmeshed thoughts cannot be easily changed through rational dissonance resolution. Defuse first, then resolve.
- `lex-tick` can check `ruminating_thoughts` in the introspection phase and trigger `apply_defusion` as a response to detected rumination patterns.
- `lex-cognitive-coherence` proposition acceptance can be blocked by enmeshed thoughts in the same domain — defusion unlocks coherence processing.

## Development Notes

- `apply_defusion` reduces fusion by `TECHNIQUE_POTENCY[technique]` — potency is fixed per technique and independent of thought type (except recommendation is type-aware).
- Fusion increases on `visit_thought` (passive exposure reinforces entanglement) and `fuse_thought` (explicit reinforcement). The only decrease path is through explicit defusion techniques.
- `RECOMMENDED_TECHNIQUES` maps thought types to their most effective technique — callers can use `recommend_technique` for automated defusion triage.
- `apply_all_techniques` does not short-circuit at defused threshold — all 6 techniques always run in sequence.
