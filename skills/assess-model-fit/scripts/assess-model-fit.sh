#!/bin/bash
# assess-model-fit.sh — dual-mode script for model capability assessment
# Procedural mode: ./assess-model-fit.sh (no args)
# Executable mode: ./assess-model-fit.sh --task "task description"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_procedural_mode() {
    cat << 'EOF'
# assess-model-fit: Procedural Mode

## Quick Assessment Checklist

Does your task have any of these characteristics?

- [ ] Deep multi-step reasoning (>5 logical steps, complex dependencies)
- [ ] Code review rigor (subtle bugs, security, performance, architecture)
- [ ] Large context window (many files, long documents, substantial history)
- [ ] Complex decomposition (breaking down ambiguous problem into sub-tasks)
- [ ] Uncertain scope (vague requirements needing clarification via reasoning)
- [ ] Novel problem (no standard solution; creative/exploratory thinking needed)

**If you checked ANY box above:** Current model may be insufficient.
Run `/select-model` to determine the right model for this task.

**If you checked NO boxes:** Current model is likely adequate.
Run `/select-model` anyway if you're uncertain about task complexity.

## Model Decision Tree

| Task Type | Current Model | Status | Recommendation |
|-----------|---------------|--------|-----------------|
| Simple query | Haiku | ✓ Adequate | Keep Haiku |
| Straightforward code gen | Haiku | ✓ Adequate | Keep Haiku |
| Multi-step task | Sonnet | ✓ Adequate | Keep Sonnet |
| Code review (medium) | Sonnet | ✓ Adequate | Keep Sonnet |
| Complex architecture | Opus | ✓ Adequate | Keep Opus |
| Subtle bug hunt | Opus | ✓ Adequate | Keep Opus |
| Simple query | Sonnet | ⚠ Overkill | Consider Haiku for cost |
| Multi-step task | Haiku | ✗ Insufficient | Escalate to Sonnet |
| Code review (detailed) | Haiku | ✗ Insufficient | Escalate to Sonnet |
| Complex architecture | Sonnet | ✗ Insufficient | Escalate to Opus |

## Next Steps

1. Review the checklist above against your task
2. Look up your task type in the decision tree
3. If no match, run `/select-model --task "your task description"` for personalized advice
4. If escalation needed, the recommended model will be provided
EOF
}

score_task_complexity() {
    local task_desc="$1"
    local score=0

    if [[ "$task_desc" =~ [Cc]omplex|[Aa]rchitecture|[Rr]efactor|[Dd]esign|[Dd]ecompos ]]; then
        score=$(( score + 3 ))
    fi

    if [[ "$task_desc" =~ [Ss]ecurity|[Vv]ulnerability|[Ss]ubtle|[Ee]dge.case ]]; then
        score=$(( score + 3 ))
    fi

    if [[ "$task_desc" =~ [Rr]eview|[Cc]ode.review|[Qq]uality|[Pp]erformance ]]; then
        score=$(( score + 2 ))
    fi

    if [[ "$task_desc" =~ [Mm]ulti-step|[Mm]ulti-file|[Cc]oordinate|[Ll]arge.scope ]]; then
        score=$(( score + 2 ))
    fi

    if [[ "$task_desc" =~ [Dd]ocument|[Ww]rite.doc|[Cc]omment|[Rr]eadme ]]; then
        score=$(( score + 2 ))
    fi

    if [[ "$task_desc" =~ [Ss]imple|[Ss]traightforward|[Bb]asic|[Tt]rivial ]]; then
        score=$(( score - 2 ))
    fi

    if [[ "$task_desc" =~ [Qq]uery|[Qq]uestion|[Aa]nswer ]]; then
        score=$(( score - 1 ))
    fi

    # Clamp to [0, 10]
    if [[ $score -lt 0 ]]; then score=0; fi
    if [[ $score -gt 10 ]]; then score=10; fi

    echo "$score"
}

get_current_model() {
    if [[ -f ~/.claude/settings.json ]]; then
        grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' ~/.claude/settings.json 2>/dev/null | \
            head -1 | cut -d'"' -f4 || echo "${CLAUDE_MODEL:-unknown}"
    else
        # Fall back to env variable if set
        echo "${CLAUDE_MODEL:-unknown}"
    fi
}

recommend_model() {
    local score="$1"

    if [[ "$score" -le 1 ]]; then
        echo "fable"
    elif [[ "$score" -le 2 ]]; then
        echo "haiku"
    elif [[ "$score" -le 5 ]]; then
        echo "sonnet"
    else
        echo "opus"
    fi
}

model_tier() {
    local model="$1"
    case "$model" in
        fable|fable5|claude-fable-5) echo 0 ;;
        haiku|claude-haiku*|claude-3-haiku*) echo 1 ;;
        sonnet|claude-sonnet*|claude-3-sonnet*) echo 2 ;;
        opus|claude-opus*|claude-3-opus*) echo 3 ;;
        *) echo -1 ;; # unknown
    esac
}

get_model_display_name() {
    local model_key="$1"
    case "$model_key" in
        fable|fable5|claude-fable-5)
            echo "Fable 5 (claude-fable-5)"
            ;;
        haiku|claude-haiku*|claude-3-haiku*)
            echo "Haiku 4.5 (claude-haiku-4-5-20251001)"
            ;;
        sonnet|claude-sonnet*|claude-3-sonnet*)
            echo "Sonnet 4.6 (claude-sonnet-4-6)"
            ;;
        opus|claude-opus*|claude-3-opus*)
            echo "Opus 4.8 (claude-opus-4-8)"
            ;;
        *)
            echo "Unknown ($model_key)"
            ;;
    esac
}

show_executable_mode() {
    local task_desc="$1"
    local current_model_raw
    current_model_raw=$(get_current_model)
    local complexity
    complexity=$(score_task_complexity "$task_desc")
    local recommended
    recommended=$(recommend_model "$complexity")

    # Get tier from original model string before stripping prefix
    local current_tier
    current_tier=$(model_tier "$current_model_raw")
    local recommended_tier
    recommended_tier=$(model_tier "$recommended")

    echo ""
    echo -e "${BLUE}## Model Fit Assessment${NC}"
    echo ""
    echo "**Current model:** $(get_model_display_name "$current_model_raw")"
    echo "**Task complexity score:** $complexity / 10"
    echo "**Recommended model:** $(get_model_display_name "$recommended") (estimated)"
    echo ""

    if [[ "$complexity" -lt 2 ]] && [[ "$recommended_tier" -le "$current_tier" ]]; then
        echo -e "${GREEN}✓ Current model is adequate for this task.${NC}"
        echo ""
        echo "The task appears straightforward with minimal reasoning complexity."
        echo "Current model should handle it efficiently."
        echo ""
        echo "**To confirm:** Run \`/select-model --task \"$task_desc\"\` for detailed analysis."
        return 0
    elif [[ "$recommended_tier" -le "$current_tier" ]]; then
        echo -e "${GREEN}✓ Current model is adequate for this task.${NC}"
        echo ""
        echo "The recommended model ($(get_model_display_name "$recommended")) is not higher than your current model."
        echo "No escalation needed."
        return 0
    elif [[ "$complexity" -lt 4 ]]; then
        echo -e "${YELLOW}⚠ Current model may be borderline for this task.${NC}"
        echo ""
        echo "The task has moderate complexity. $(get_model_display_name "$recommended") is recommended."
        echo ""
        echo "**Escalating to model selection...**"
        echo ""
        return 1
    else
        echo -e "${RED}✗ Current model is likely insufficient for this task.${NC}"
        echo ""
        echo "The task requires significant reasoning. Escalation to $(get_model_display_name "$recommended") recommended."
        echo ""
        echo "**Escalating to model selection...**"
        echo ""
        return 1
    fi
}

# Main logic
if [[ $# -eq 0 ]]; then
    # Procedural mode: show checklist
    show_procedural_mode
else
    # Executable mode: analyze task
    case "${1:-}" in
        --task)
            if [[ $# -lt 2 ]]; then
                echo "Error: --task requires a description"
                echo "Usage: $0 --task \"your task description\""
                exit 1
            fi
            task_description="$2"

            if show_executable_mode "$task_description"; then
                # No escalation needed
                exit 0
            else
                # Escalation needed — call select-model
                echo -e "${BLUE}Running /select-model for personalized recommendation...${NC}"
                echo ""

                # Source select-model script and invoke it
                select_model_script="${SKILLS_DIR}/select-model/scripts/select-model.sh"
                if [[ -f "$select_model_script" ]]; then
                    bash "$select_model_script" --task "$task_description"
                else
                    echo "Error: select-model script not found at $select_model_script"
                    exit 1
                fi
            fi
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Usage:"
            echo "  $0                          # Procedural mode (show checklist)"
            echo "  $0 --task \"description\"     # Executable mode (analyze task)"
            exit 1
            ;;
    esac
fi
