# Product Brief: Centaur Layer

## Problem

AI coding assistants make developers faster, but they also make it easier to stop reading deeply, stop designing deliberately, and accept generated code without understanding it.

Centaur Layer targets that failure mode: cognitive offloading without supervision.

## Target Users

- individual developers who want to stay sharp while using AI
- senior engineers reviewing AI-heavy codebases
- CTOs and engineering managers who need evidence that teams verify AI output

## MVP Promise

Before AI-generated work is accepted, Centaur Layer helps answer:

- Did the human define the boundaries?
- Did the AI stay inside them?
- Did someone understand the risk?
- Was the change verified?

## Non-Goals For MVP

- IDE UI
- deliberate bug injection into real code
- enterprise dashboard
- remote telemetry
- replacing existing coding agents

## Later

- opt-in training drills with synthetic flawed diffs
- team metrics dashboard
- IDE extension integration
- policy pack marketplace

## Training Drill Safety

Training drills use synthetic snippets only. They must not edit real project files, produce patches, or masquerade as production suggestions.
