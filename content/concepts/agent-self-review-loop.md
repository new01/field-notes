---
title: Agent Self-Review Loop
description: After generating an output, the agent checks its own work against a checklist before passing it forward — catching quality failures before they reach the human review queue
tags: [concepts, quality, architecture, openclaw]
---

After generating an output, the agent checks its own work against a defined checklist before passing it forward. Self-review catches quality failures — hallucinated content, AI-pattern-heavy text, format violations — before they reach the human review queue.

## The pattern

```
Generate → Score → [If score < threshold: pass] → [If score ≥ threshold: clean + retry once] → Deliver
```

The key constraint: **one retry maximum.** Self-review loops that can retry indefinitely produce worse outcomes than a single clean pass — the model starts optimizing for the reviewer rather than the actual goal.

## When to use it

Self-review works best for:
- **Text quality gates** — detecting AI patterns in generated copy before it goes to review
- **Format validation** — checking that structured output (JSON, markdown, code) parses correctly before saving
- **Completeness checks** — verifying that all required fields in a generated artifact are present

Self-review is less useful for:
- **Factual accuracy** — the model can't reliably catch its own hallucinations (it's reviewing with the same knowledge it generated with)
- **Subjective quality** — the model's judgment of "good writing" doesn't reliably match the actual target audience

## Implementation

The scorer is separate from the generator. A generator that also scores its own output on the same criteria it was generating for will be biased toward high scores.

Use an independent scoring function:

```js
async function generateAndReview(prompt, format) {
  const THRESHOLD = 35;

  let text = await generate(prompt);
  let score = score_text(text);

  if (score >= THRESHOLD) {
    text = mechanical_clean(text);   // deterministic, no API call
    score = score_text(text);

    if (score >= THRESHOLD) {
      text = await generate(prompt + '\n\nPrevious attempt scored ' + score + '. Be more specific and concrete.');
      score = score_text(text);
    }
  }

  return { text, score, flagged: score >= THRESHOLD };
}
```

The mechanical clean step (pure regex, no API call) is cheap and often sufficient. The second generation attempt is expensive and rarely needed — if the mechanical clean didn't help, the issue is usually in the prompt.

## Flagging vs rejecting

Don't silently drop output that fails the self-review. Flag it in the delivery artifact with the specific score and reason, and let the human decide whether to use it.

Automatic rejection is appropriate only when the output is structurally broken (unparseable JSON, truncated mid-sentence) — not when it's merely below a quality threshold.

## Related

- [[Input Validation in Skills]] — the pre-flight counterpart to self-review (checks inputs before running)
- [[Tweet Format Taxonomy]] — the format taxonomy that tweet self-review checks against
- [[Graph Orchestration Patterns]] — the sequential pipeline context this loop operates in
