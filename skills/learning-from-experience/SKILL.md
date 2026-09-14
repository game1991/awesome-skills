---
name: learning-from-experience
description: Use when user repeats similar requests or says "learn from this" / "save this pattern". Routes experience to SKILL.md, script/MCP proposals, or MEMORY.md rule upgrades. Does NOT duplicate Auto Memory — focuses on turning experience into reusable artifacts.
---

# Learning from Experience

**Core principle:** Auto Memory remembers. LFE upgrades — from experience to reusable artifact.

**NOT a replacement for Auto Memory.** Claude Code already auto-extracts feedback and preferences. LFE adds what Auto Memory cannot: **artifact generation** (SKILL.md, scripts, MCP proposals) and **explicit pattern promotion** (rule → skill upgrade).

**REQUIRED:** Understand superpowers:writing-skills before generating SKILL.md. This skill decides WHAT; writing-skills decides HOW.

## When to Use

**DO trigger when:**
- User repeats a request that matches a cataloged pattern
- User says "learn from this", "save this pattern", "make a skill for this"
- A MEMORY.md rule has been reinforced 3+ times → propose SKILL.md upgrade

**DO NOT trigger for:**
- Single-session corrections (Auto Memory handles this)
- Simple preference recording (Auto Memory handles this)
- Session-end summarization (AutoDream handles this)

## Quick Reference — Artifact Routing

| Condition | Artifact | Action |
|-----------|----------|--------|
| 3+ MEMORY.md rules on same topic | SKILL.md | Delegate to writing-skills |
| General methodology (>=3 steps) | SKILL.md | Delegate to writing-skills |
| Repeated automatable operation | Script/MCP proposal | Provide spec, user decides |
| Simple rule needing explicit user control | MEMORY.md rule | Edit with `[LFE-Pxxx]` tag |

> Note: Most simple rules should be left to Auto Memory. Only write MEMORY.md rules manually when you need explicit `[LFE-Pxxx]` tags for future migration tracking.

## Core Pattern

### Step 1: Detect Pattern Match

1. Read `~/.claude/skills/learning-from-experience/references/pattern-catalog.md`
2. Match user request keywords against catalog entries
3. **Hit found** → AskUserQuestion: "Detected [Pxxx] pattern. Reuse / New / Improve?"
4. **No hit** → Only proceed if user explicitly triggers ("learn from this")

**Always check catalog first.** No shortcuts.

### Step 2: Route to Artifact

Based on Quick Reference table:
- **SKILL.md** → Output delegation package (Step 3)
- **Script/MCP** → Provide specification, AskUserQuestion to confirm
- **MEMORY.md rule** → Edit with `[LFE-Pxxx]` tag, update catalog (rare — prefer Auto Memory)

### Step 3: Delegate to writing-skills

For SKILL.md artifacts, output this delegation package then invoke `superpowers:writing-skills`:

```markdown
## Delegation to writing-skills
- **Pattern name**: [skill-name-with-hyphens]
- **Trigger**: [Use when... description]
- **Core process**: [step summary]
- **Known test scenarios**: [pressure scenarios from experience]
- **Key constraints**: [boundary conditions from experience]
```

### Step 4: Update Catalog

Append or update pattern in `pattern-catalog.md`:
- New pattern: assign next Pxxx ID, status "observing" (frequency 1) or "confirmed" (frequency >=3)
- Existing pattern: increment frequency, update last-triggered date, change status if threshold met
- When 3+ rules under same topic → mark for SKILL.md upgrade proposal

## What LFE Does NOT Do (Left to Built-in)

| Built-in handles | LFE does not |
|-----------------|-------------|
| Auto-extract feedback from corrections | Auto Memory |
| Auto-consolidate memories across sessions | AutoDream |
| Record simple user preferences | Auto Memory |
| Semantic search of past conversations | episodic-memory plugin |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing simple rules to MEMORY.md | Leave to Auto Memory — LFE only writes tagged rules for migration tracking |
| Creating SKILL.md directly | Delegate to writing-skills for TDD quality |
| Triggering on every session end | AutoDream handles consolidation — LFE only triggers on explicit pattern match |
| Skipping catalog check | Always scan catalog first — prevents duplicates |
| No user confirmation before creating | Always AskUserQuestion before any artifact |
