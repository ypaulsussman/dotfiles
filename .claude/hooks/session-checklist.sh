#!/bin/bash
# Session-start checklist
# Returns additionalContext so Claude has it in context.

read -r INPUT
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')

# Context Claude receives
if [ "$SOURCE" = "compact" ]; then
  CONTEXT="[Session checklist — post-compaction] Context was just compacted. Key decisions or state may have been lost. Consider checking auto-memory or asking the user to re-state goals. Checklist: (1) Are we still aligned on the goal? (2) What was the verification plan? (3) Any decisions to re-confirm?"
else
  CONTEXT="[Session checklist] Before diving in, keep in mind: (1) Should this start in plan mode? (2) What does 'done' look like — what are the success criteria? (3) How will we verify the work (tests, build, linter, visual check)? (4) Is this complex enough to break into steps with checkpoints? (5) If the user seems unsure, suggest /start to walk through these together."
fi

jq -n --arg ctx "$CONTEXT" '{"additionalContext": $ctx}'
