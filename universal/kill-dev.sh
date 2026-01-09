#!/bin/bash

# Development Process Killer Script
# Usage: ./kill-dev [level]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


kill_by_port() {
    local ports=("$@")
    local force_kill=${FORCE_KILL:-false}

    for port in "${ports[@]}"; do
        local pids=$(lsof -ti:$port 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo -e "${YELLOW}Killing processes on port $port${NC}"

            if [ "$force_kill" = true ]; then
                # Use kill -9 for higher levels
                echo "$pids" | xargs kill -9 2>/dev/null || true
            else
                # For level 1, try graceful SIGTERM first, then SIGINT if needed
                echo "$pids" | xargs kill -15 2>/dev/null || true
                sleep 0.5

                # Check if processes still exist
                local remaining=$(lsof -ti:$port 2>/dev/null || true)
                if [ -n "$remaining" ]; then
                    echo "$remaining" | xargs kill -2 2>/dev/null || true
                fi
            fi
        fi
    done
}

kill_by_name() {
    local processes=("$@")
    for process in "${processes[@]}"; do
        local pids=$(pgrep -f "$process" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo -e "${YELLOW}Killing $process processes${NC}"
            pkill -f "$process" 2>/dev/null || true
        fi
    done
}

level_1() {
    echo -e "${GREEN}Level 1: Killing dev server ports${NC}"
    kill_by_port 3000 3001 3002 5173 8080 4000 8000
}

level_2() {
    echo -e "${GREEN}Level 2: Killing dev servers + Node processes${NC}"
    FORCE_KILL=true level_1
    kill_by_name "node" "npm" "yarn" "pnpm"
}

level_3() {
    echo -e "${GREEN}Level 3: Killing dev servers + Node + build tools${NC}"
    level_2
    kill_by_name "vite" "next-server" "next dev" "playwright" "jest" "vitest" "webpack"
}

level_4() {
    echo -e "${GREEN}Level 4: Killing dev tools + IDEs${NC}"
    level_3
    kill_by_name "code" "webstorm" "idea" "cursor" "zed"
}

level_5() {
    echo -e "${RED}Level 5: Nuclear option - All dev processes${NC}"
    level_4
    kill_by_name "docker" "docker-compose" "redis-server" "postgres" "mongod" "electron"
    # Kill any remaining processes on common dev ports
    kill_by_port 5432 3306 6379 27017 9000 9001
}

interactive_mode() {
    while true; do
        echo ""
        echo -e "${BLUE}Development Process Killer${NC}"
        echo "Select kill level:"
        echo "1) Dev servers only (ports 3000-3002, 5173, 8080)"
        echo "2) + Node/npm/yarn processes"
        echo "3) + Vite/Next.js/Playwright/build tools"
        echo "4) + IDEs (VSCode, WebStorm, Cursor, Zed)"
        echo "5) Nuclear option (everything including Docker, DBs)"
        echo "0) Exit"

        read -p "Choose level (0-5): " level

        case $level in
            1)
                level_1
                ask_continue
                ;;
            2)
                level_2
                ask_continue
                ;;
            3)
                level_3
                ask_continue
                ;;
            4)
                level_4
                ask_continue
                ;;
            5)
                echo -e "${RED}Are you sure you want the nuclear option? (y/N)${NC}"
                read -p "" confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    level_5
                    ask_continue
                else
                    echo "Cancelled."
                fi
                ;;
            0)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose 0-5.${NC}"
                ;;
        esac
    done
}

ask_continue() {
    echo ""
    echo -e "${GREEN}Done! Processes killed.${NC}"
    echo -e "${YELLOW}Would you like to kill more processes? (y/N)${NC}"
    read -p "" continue_choice
    if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
        echo "Goodbye!"
        exit 0
    fi
}

# Main logic - Always run interactive mode
interactive_mode