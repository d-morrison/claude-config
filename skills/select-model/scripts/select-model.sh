#!/bin/bash
# select-model.sh — dual-mode script for Claude model selection
# Procedural mode: ./select-model.sh (no args)
# Executable mode: ./select-model.sh --task "task description"

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_procedural_mode() {
    cat << 'EOF'
# select-model: Procedural Mode

## Model Tiers

| Model | ID | Speed | Reasoning | Cost | Best For |
|-------|----|----|-----------|------|----------|
| Fable 5 | claude-fable-5 | ⭐⭐⭐⭐⭐ | ⭐ | ⭐ | Trivial, high-volume |
| Haiku 4.5 | claude-haiku-4-5-20251001 | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | Simple queries, code gen |
| Sonnet 4.6 | claude-sonnet-4-6 | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | Multi-step, code review |
| Opus 4.8 | claude-opus-4-8 | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Complex design, security |

## Decision Tree

```
Is this a trivial task (single query, no reasoning)?
  ├─ YES → Fable 5
  └─ NO ↓

Does this fit in narrow scope (single file, <5 steps)?
  ├─ YES → Haiku 4.5
  └─ NO ↓

Does this involve multi-step reasoning or moderate complexity?
  ├─ YES → Sonnet 4.6
  └─ NO ↓

Deep reasoning, sophisticated design, or rigorous code review needed?
  ├─ YES → Opus 4.8
  └─ UNCLEAR → Sonnet 4.6 (safe default)
```

## Task Examples

**Use Fable 5:**
- Translate text
- Format data
- Run simple commands

**Use Haiku 4.5:**
- Answer a question
- Generate simple code
- Fix obvious bugs
- Write documentation

**Use Sonnet 4.6:**
- Refactor multi-file code
- Write comprehensive tests
- Moderate code review
- Problem decomposition

**Use Opus 4.8:**
- Complex architecture design
- Subtle bug analysis
- Security review
- Major refactoring with design decisions

## Next Steps

For personalized recommendation:
```
/select-model --task "your task description"
```

This will analyze your task and optionally suggest a config update.
EOF
}

score_task_complexity() {
    local task_desc="$1"
    local score=0

    # Complexity scoring based on keyword patterns
    if [[ "$task_desc" =~ [Aa]rchitecture|[Dd]esign|[Rr]efactor|[Cc]omplex|[Dd]ecompos ]]; then
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

    if [[ "$task_desc" =~ [Ss]imple|[Ss]traightforward|[Bb]asic|[Tt]rivial ]]; then
        score=$(( score - 2 ))
    fi

    if [[ "$task_desc" =~ [Qq]uery|[Qq]uestion|[Aa]nswer ]]; then
        score=$(( score - 1 ))
    fi

    if [[ "$task_desc" =~ [Dd]ocument|[Ww]rite.doc|[Cc]omment|[Rr]eadme ]]; then
        score=$(( score + 2 ))
    fi

    # Ensure score stays in range [0, 10]
    if [[ $score -lt 0 ]]; then score=0; fi
    if [[ $score -gt 10 ]]; then score=10; fi

    echo "$score"
}

recommend_model_by_score() {
    local score="$1"

    if [[ $score -le 1 ]]; then
        echo "fable"
    elif [[ $score -le 2 ]]; then
        echo "haiku"
    elif [[ $score -le 5 ]]; then
        echo "sonnet"
    else
        echo "opus"
    fi
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

get_current_model() {
    if [[ -f ~/.claude/settings.json ]]; then
        grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' ~/.claude/settings.json 2>/dev/null | \
            head -1 | cut -d'"' -f4 || echo "${CLAUDE_MODEL:-unknown}"
    else
        echo "${CLAUDE_MODEL:-unknown}"
    fi
}

normalize_model_key() {
    local model="$1"
    # Extract the core model name (fable, haiku, sonnet, opus)
    if [[ "$model" =~ fable ]]; then
        echo "fable"
    elif [[ "$model" =~ haiku ]]; then
        echo "haiku"
    elif [[ "$model" =~ sonnet ]]; then
        echo "sonnet"
    elif [[ "$model" =~ opus ]]; then
        echo "opus"
    else
        echo "$model"
    fi
}

show_executable_mode() {
    local task_desc="$1"
    local current_model
    current_model=$(get_current_model)
    local complexity
    complexity=$(score_task_complexity "$task_desc")
    local recommended_key
    recommended_key=$(recommend_model_by_score "$complexity")
    local recommended_display
    recommended_display=$(get_model_display_name "$recommended_key")

    echo ""
    echo -e "${BLUE}## Model Recommendation${NC}"
    echo ""

    if [[ "$current_model" != "unknown" ]]; then
        echo "**Current model:** $(get_model_display_name "$current_model")"
    else
        echo "**Current model:** Not configured (will use Claude Code default)"
    fi

    echo "**Task complexity score:** $complexity / 10"
    echo "**Recommended model:** $recommended_display"
    echo ""

    # Provide reasoning
    case "$recommended_key" in
        fable)
            echo -e "${GREEN}Fable 5 is recommended.${NC}"
            echo "This task is trivial and doesn't require deep reasoning."
            echo "Fable 5 is fastest and cheapest."
            ;;
        haiku)
            echo -e "${GREEN}Haiku 4.5 is recommended.${NC}"
            echo "This task has low-to-moderate complexity and fits a narrow scope."
            echo "Haiku 4.5 offers good speed with sufficient reasoning depth."
            ;;
        sonnet)
            echo -e "${YELLOW}Sonnet 4.6 is recommended.${NC}"
            echo "This task involves multi-step reasoning or moderate complexity."
            echo "Sonnet 4.6 balances reasoning capability and speed."
            ;;
        opus)
            echo -e "${RED}Opus 4.8 is recommended.${NC}"
            echo "This task requires deep reasoning, architectural decisions, or rigorous analysis."
            echo "Opus 4.8 is the most capable model; speed is secondary here."
            ;;
    esac

    echo ""

    # Compare with current model
    if [[ "$current_model" != "unknown" ]]; then
        local current_key
        current_key=$(normalize_model_key "$current_model")
        if [[ "$current_key" == "$recommended_key" ]]; then
            echo -e "${GREEN}✓ Current model matches recommendation.${NC}"
            echo ""
            return 0
        else
            echo -e "${YELLOW}Current model differs from recommendation.${NC}"
            echo ""
        fi
    fi

    # Show config update suggestion
    echo -e "${CYAN}## Config Update Suggestion${NC}"
    echo ""
    echo "To use $recommended_display for future sessions, update \`~/.claude/settings.json\`:"
    echo ""
    echo "Find the \`model\` key:"
    echo "  \`\`\`json"
    echo "  \"model\": \"...\""
    echo "  \`\`\`"
    echo ""
    echo "And update it to:"
    echo "  \`\`\`json"
    case "$recommended_key" in
        fable)
            echo '  "model": "claude-fable-5"'
            ;;
        haiku)
            echo '  "model": "claude-haiku-4-5-20251001"'
            ;;
        sonnet)
            echo '  "model": "claude-sonnet-4-6"'
            ;;
        opus)
            echo '  "model": "claude-opus-4-8"'
            ;;
    esac
    echo "  \`\`\`"
    echo ""
    echo "Then save and restart your Claude Code session for changes to take effect."
    echo ""

    return 0
}

# Main logic
if [[ $# -eq 0 ]]; then
    # Procedural mode: show decision tree
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
            show_executable_mode "$task_description"
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Usage:"
            echo "  $0                      # Procedural mode (show decision tree)"
            echo "  $0 --task \"description\" # Executable mode (recommend model)"
            exit 1
            ;;
    esac
fi
