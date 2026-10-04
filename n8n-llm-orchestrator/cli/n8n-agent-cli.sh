#!/bin/bash
#
# n8n Multi-Agent Orchestrator CLI
# Version: 4.0.0
# Description: Command-line interface for Coder Agent and Web Agent
#
# Usage:
#   ./n8n-agent-cli.sh coder /path/to/codebase "Task description"
#   ./n8n-agent-cli.sh web https://example.com "Task description"
#
# Environment Variables:
#   N8N_WEBHOOK_URL - n8n webhook endpoint (default: http://localhost:5678/webhook/agent)
#   N8N_API_KEY     - Optional API key for authentication
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
N8N_WEBHOOK_URL=${N8N_WEBHOOK_URL:-"http://localhost:5678/webhook/agent"}
N8N_API_KEY=${N8N_API_KEY:-""}

# Function: Print usage
usage() {
    cat << EOF
${BLUE}n8n Multi-Agent Orchestrator CLI v4.0.0${NC}

${YELLOW}Usage:${NC}
    $(basename $0) <agent_type> <codebase_or_url> <task_description> [options]

${YELLOW}Arguments:${NC}
    agent_type          Either 'coder' or 'web'
    codebase_or_url     For coder: absolute path to codebase
                        For web: target URL
    task_description    Natural language task description (quoted)

${YELLOW}Options:${NC}
    --auto-push         (Coder Agent only) Auto-push git commits to remote
    --headless=false    (Web Agent only) Run browser in non-headless mode
    --help, -h          Show this help message

${YELLOW}Environment Variables:${NC}
    N8N_WEBHOOK_URL     n8n webhook endpoint
                        Default: http://localhost:5678/webhook/agent
    N8N_API_KEY         Optional API key for authentication

${YELLOW}Examples:${NC}
    ${GREEN}# Coder Agent: Refactor authentication${NC}
    $(basename $0) coder /home/user/my-app "Refactor auth to use JWT tokens"

    ${GREEN}# Coder Agent: Generate tests with auto-push${NC}
    $(basename $0) coder /home/user/my-app "Write unit tests for user service" --auto-push

    ${GREEN}# Web Agent: Research competitor pricing${NC}
    $(basename $0) web https://competitor.com/pricing "Research their pricing tiers"

    ${GREEN}# Web Agent: Extract product data${NC}
    $(basename $0) web https://shop.example.com/products "Extract all product names and prices"

${YELLOW}Output:${NC}
    - Formatted response with status, result, cost breakdown
    - For Coder Agent: git branch, commit hash, files modified
    - For Web Agent: report path, screenshots, pages visited
    - Real-time status updates during execution

${YELLOW}Exit Codes:${NC}
    0    Success
    1    Invalid arguments
    2    n8n webhook unreachable
    3    Agent execution failed
    4    Budget exhausted

EOF
    exit 1
}

# Function: Print colored message
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function: Validate agent type
validate_agent_type() {
    local agent=$1
    if [[ "$agent" != "coder" && "$agent" != "web" ]]; then
        log_error "Invalid agent type: $agent"
        log_error "Must be either 'coder' or 'web'"
        exit 1
    fi
}

# Function: Validate codebase path (for Coder Agent)
validate_codebase_path() {
    local path=$1

    # Check if path is absolute
    if [[ "$path" != /* ]]; then
        log_error "Codebase path must be absolute (start with /)"
        log_error "Got: $path"
        exit 1
    fi

    # Check if path exists
    if [[ ! -d "$path" ]]; then
        log_error "Codebase path does not exist: $path"
        exit 1
    fi

    # Check if it's a git repository
    if [[ ! -d "$path/.git" ]]; then
        log_warning "Path is not a git repository: $path"
        log_warning "Git operations may fail"
    fi
}

# Function: Validate URL (for Web Agent)
validate_url() {
    local url=$1

    # Basic URL validation
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_error "Invalid URL: $url"
        log_error "URL must start with http:// or https://"
        exit 1
    fi
}

# Function: Check n8n webhook is reachable
check_n8n_webhook() {
    log_info "Checking n8n webhook at $N8N_WEBHOOK_URL..."

    if ! curl -s -f -o /dev/null --max-time 5 "${N8N_WEBHOOK_URL%/webhook/agent}/healthz" 2>/dev/null; then
        log_error "n8n webhook unreachable at $N8N_WEBHOOK_URL"
        log_error "Is n8n running? Check N8N_WEBHOOK_URL environment variable"
        exit 2
    fi

    log_success "n8n webhook is reachable"
}

# Function: Build JSON payload
build_payload() {
    local agent=$1
    local target=$2
    local task=$3
    local auto_push=$4
    local headless=$5

    # Escape quotes in task description
    task=$(echo "$task" | sed 's/"/\\"/g')

    # Build JSON based on agent type
    if [[ "$agent" == "coder" ]]; then
        cat <<EOF
{
  "agent": "coder",
  "codebase": "$target",
  "task": "$task",
  "options": {
    "auto_push": $auto_push
  }
}
EOF
    else
        cat <<EOF
{
  "agent": "web",
  "target_url": "$target",
  "task": "$task",
  "options": {
    "headless": $headless
  }
}
EOF
    fi
}

# Function: Format response
format_response() {
    local response=$1

    # Check if jq is available for pretty printing
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '
            "\(.status | ascii_upcase):",
            "",
            if .status == "completed" then
                if .agent == "coder" then
                    "Git Branch: \(.git_branch // "N/A")",
                    "Commit Hash: \(.commit_hash // "N/A")",
                    "Files Modified: \(.files_modified | length)",
                    if .files_modified then
                        (.files_modified | map("  - " + .) | join("\n"))
                    else "" end,
                    "",
                    "Cost Breakdown:",
                    "  Architect: $\(.cost_breakdown.architect // 0)",
                    "  Executor:  $\(.cost_breakdown.executor // 0)",
                    "  Reviewer:  $\(.cost_breakdown.reviewer // 0)",
                    "  TOTAL:     $\(.total_cost)",
                    "",
                    "Duration: \(.duration_ms)ms"
                elif .agent == "web" then
                    "Report Path: \(.report_path // "N/A")",
                    "Pages Visited: \(.pages_visited | length)",
                    if .pages_visited then
                        (.pages_visited | map("  - " + .) | join("\n"))
                    else "" end,
                    "Screenshots: \(.screenshots | length)",
                    "",
                    "Cost Breakdown:",
                    "  Architect: $\(.cost_breakdown.architect // 0)",
                    "  Executor:  $\(.cost_breakdown.executor // 0)",
                    "  Vision:    $\(.cost_breakdown.vision // 0)",
                    "  TOTAL:     $\(.total_cost)",
                    "",
                    "Duration: \(.duration_ms)ms"
                else
                    "Result: \(.result // .message)"
                end
            elif .status == "error" then
                "Error: \(.error // .message)",
                if .details then
                    "",
                    "Details:",
                    "\(.details)"
                else "" end
            else
                "Status: \(.status)",
                if .message then "Message: \(.message)" else "" end
            end
        '
    else
        # Fallback to simple text output if jq not available
        echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 | tr '[:lower:]' '[:upper:]'
        echo ""
        echo "$response"
    fi
}

# Function: Call n8n webhook
call_webhook() {
    local payload=$1

    log_info "Sending request to n8n..."
    log_info "Agent: $(echo "$payload" | grep -o '"agent":"[^"]*"' | cut -d'"' -f4)"

    # Build curl command
    local curl_cmd="curl -s -X POST"
    curl_cmd="$curl_cmd -H 'Content-Type: application/json'"

    if [[ -n "$N8N_API_KEY" ]]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $N8N_API_KEY'"
    fi

    curl_cmd="$curl_cmd -d '$payload'"
    curl_cmd="$curl_cmd $N8N_WEBHOOK_URL"

    # Execute request
    local response=$(eval $curl_cmd)

    # Check if response is empty
    if [[ -z "$response" ]]; then
        log_error "Empty response from n8n webhook"
        exit 2
    fi

    # Extract status
    local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    # Print formatted response
    echo ""
    format_response "$response"
    echo ""

    # Check status and exit accordingly
    if [[ "$status" == "completed" ]]; then
        log_success "Task completed successfully!"
        exit 0
    elif [[ "$status" == "error" ]]; then
        # Check for budget exhausted
        if echo "$response" | grep -q "budget exhausted"; then
            log_error "Budget exhausted - task blocked"
            exit 4
        fi
        log_error "Task failed"
        exit 3
    else
        log_warning "Unknown status: $status"
        exit 3
    fi
}

# Main script
main() {
    # Check for help flag
    if [[ "$1" == "--help" || "$1" == "-h" || $# -lt 3 ]]; then
        usage
    fi

    # Parse arguments
    local agent=$1
    local target=$2
    local task=$3
    shift 3

    # Parse options
    local auto_push=false
    local headless=true

    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-push)
                auto_push=true
                shift
                ;;
            --headless=*)
                headless="${1#*=}"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate inputs
    validate_agent_type "$agent"

    if [[ "$agent" == "coder" ]]; then
        validate_codebase_path "$target"
    else
        validate_url "$target"
    fi

    # Check n8n availability
    check_n8n_webhook

    # Build and send request
    local payload=$(build_payload "$agent" "$target" "$task" "$auto_push" "$headless")
    call_webhook "$payload"
}

# Run main function
main "$@"
