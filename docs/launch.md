# Launch Plan

Centaur Layer should launch as a public preview of an open source developer tool, not as a finished governance platform.

## Positioning

Core message:

> AI coding assistants make developers faster, but they can quietly weaken review discipline. Centaur Layer keeps human judgment active with contracts, risk gates, comprehension checks, and coaching.

Short description:

> A Codex plugin that helps developers use AI coding assistants without surrendering architectural judgment, review discipline, or debugging skill.

## Launch Checklist

- GitHub repository is public.
- `README.md` opens with the problem, value proposition, demo output, install steps, and public-preview status.
- `docs/assets/social-preview.png` is uploaded as the GitHub social preview image in repository settings.
- Repository topics are set: `ai-coding`, `developer-tools`, `code-review`, `codex`, `guardrails`, `open-source`.
- `bash scripts/validate-plugin.sh` passes.
- A small throwaway-repo demo has been run for docs, dependency, and health scenarios.

## Suggested Sequence

1. Publish the GitHub repository.
2. Post the problem statement on X and LinkedIn.
3. Share a technical launch post with the demo output.
4. Submit to Hacker News as a Show HN.
5. Share carefully in relevant communities as a discussion, not a link drop.
6. Follow up with what feedback changed in the project.

## Copy

### X / Twitter

```text
AI coding agents made me faster, but I noticed a worse failure mode:

I was reviewing less deeply.

So I built Centaur Layer: an open source Codex plugin that adds contracts, risk gates, comprehension checks, and coaching around AI-generated code.

It is a public preview, and I would love feedback from developers using AI heavily.

https://github.com/demwick/centaur-layer
```

### LinkedIn

```text
AI coding assistants do not only introduce code risk. They also introduce review risk.

The failure mode I care about is cognitive offloading: accepting generated code without tracing the assumptions, edge cases, and ownership boundaries.

I built Centaur Layer as a small open source experiment around that problem.

It is a Codex plugin that adds:
- human/AI responsibility contracts
- deterministic diff risk signals
- comprehension checks before accepting changes
- Socratic debugging support
- structural AI-readiness audits

The goal is not to slow developers down. The goal is to keep human judgment active while AI accelerates implementation.

Public preview:
https://github.com/demwick/centaur-layer
```

### Hacker News

Title:

```text
Show HN: Centaur Layer – keep human judgment active while coding with AI
```

Post:

```text
Hi HN,

I built Centaur Layer, a small open source Codex plugin for developers using AI coding assistants.

The problem it targets is not just bad generated code. It is cognitive offloading: when AI makes implementation fast enough that the human stops reviewing deeply.

Centaur Layer adds a lightweight layer around AI-assisted work:
- contracts for what the human owns vs. what AI may do
- deterministic diff risk signals
- short comprehension checks before accepting generated changes
- Socratic debugging/coaching
- structural health checks for policy, tests, guardrails, and git state

It is a local MVP/public preview. The scripts are intentionally deterministic; the LLM layer is used for coaching and context-aware questioning.

I am especially interested in feedback from people using AI agents heavily in real codebases.
```

### Reddit / Community Discussion

```text
For people using AI coding assistants heavily: how do you keep yourself from reviewing less deeply?

I have been experimenting with a small open source Codex plugin called Centaur Layer. It adds contracts, risk gates, deterministic diff signals, and comprehension checks around AI-generated code.

The goal is not governance theater. It is to keep the human reasoning loop alive while still getting the speed benefits of AI.

Curious how others handle this failure mode.
```

## Follow-Up Post

```text
Launch feedback so far on Centaur Layer:

1. Developers like deterministic risk signals more than generic AI review comments.
2. The hard part is keeping checks short enough that people do not bypass them.
3. The next feature should likely be JSON output for better agent integrations.

Repo:
https://github.com/demwick/centaur-layer
```
