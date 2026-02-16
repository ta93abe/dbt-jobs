# Session Context

## User Prompts

### Prompt 1

Base directory for this skill: /Users/ta93abe/.claude/skills/pr

# pr

Pull Requestの作成・レビュー対応を行うスキル。

## サブコマンド

### /pr create (デフォルト)

PRを作成する。

**動作:**
1. `git status` で現在のブランチと変更を確認
2. `git log main..HEAD` でコミット履歴を確認
3. `git diff main...HEAD` で全体の変更を確認
4. 変更内容を分析してPRの説明文を生成
5. `gh pr create` でPRを作成

**PR形式:**
```...

### Prompt 2

git checkout main && git pull

### Prompt 3

マージされたときにリリースノートを作りたい。

### Prompt 4

Base directory for this skill: /Users/ta93abe/.claude/plugins/cache/claude-plugins-official/superpowers/4.3.0/skills/brainstorming

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT invoke any implem...

### Prompt 5

Base directory for this skill: /Users/ta93abe/.claude/plugins/cache/claude-plugins-official/superpowers/4.3.0/skills/writing-plans

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits....

### Prompt 6

Base directory for this skill: /Users/ta93abe/.claude/plugins/cache/claude-plugins-official/superpowers/4.3.0/skills/subagent-driven-development

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration

## When to Use

```dot
digraph when_to_use {
    "Have implement...

