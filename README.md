# lex-cognitive-defusion

Cognitive defusion (ACT) for LegionIO. Enables the agent to step back from thoughts and observe them as mental events rather than literal truths.

## What It Does

Fusion is when a thought takes on the weight of absolute truth — the agent acts as if the belief, assumption, or judgment is reality rather than a cognitive event. Defusion creates distance between the agent and its thoughts, reducing the behavioral influence of entrenched beliefs. Six techniques are available, each with different potency: acceptance (strongest), distancing, contextualization, reframing, labeling, and metaphor.

Thoughts that are visited repeatedly without defusion accumulate as rumination; the extension detects this state and recommends type-appropriate techniques.

## Usage

```ruby
client = Legion::Extensions::CognitiveDefusion::Client.new

thought = client.register_thought(
  content: 'I must always provide a complete answer or I have failed',
  thought_type: :rule,
  belief_strength: 0.8
)

# Recommended technique for :rule type is :contextualization
rec = client.recommend_technique(thought_id: thought[:thought_id])
client.apply_defusion(thought_id: thought[:thought_id], technique: rec[:technique])

# Or apply all techniques in sequence
client.apply_all_techniques(thought_id: thought[:thought_id])

client.defusion_report
# => { total_thoughts: 1, enmeshed_count: 0, average_fusion: 0.31 }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
