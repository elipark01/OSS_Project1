#!/bin/bash

# Check if CSV file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <CSV file>"
    exit 1
fi

CSV_FILE=$1

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: File '$CSV_FILE' not found."
    exit 1
fi

# Header
echo "************OSS1 - Project1************"
echo "* StudentID : 12201738 *"
echo "* Name : Joonha Park *"
echo "***************************************"

while true; do
    echo "[MENU]"
    echo "1. Search player stats by name in MLB data"
    echo "2. List top 5 players by SLG value"
    echo "3. Analyze the team stats - average age and total home runs"
    echo "4. Compare players in different age groups"
    echo "5. Search the players who meet specific statistical conditions"
    echo "6. Generate a performance report (formatted data)"
    echo "7. Quit"
    echo -n "Enter your COMMAND (1~7) : "
    read command

    case $command in
    1)
        echo -n "Enter a player name to search: "
        read name
        result=$(awk -F, -v name="$name" 'BEGIN{IGNORECASE=1}
            NR > 1 && tolower($2) ~ tolower(name) {
                printf "Player stats for \"%s\":\n", name;
                printf "Player: %s, Team: %s, Age: %s, WAR: %s, HR: %s, BA: %s\n", $2, $4, $3, $6, $15, $20;
                found = 1
            }
            END {
                if (!found) print "No player found with that name."
            }' "$CSV_FILE")
        echo "$result"
        ;;

    2)
        echo -n "Do you want to see the top 5 players by SLG? (y/n) : "
        read answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            echo "***Top 5 Players by SLG***"
            awk -F, 'NR > 1 && $8 >= 502 { 
                printf "%s,%s,%s,%s,%s,%s\n", $2, $4, $6, $15, $16, $21
            }' "$CSV_FILE" | sort -t, -k6 -nr | head -n 5 | awk -F, '{
                printf "%d. %s (Team: %s) - SLG: %s, HR: %s, RBI: %s\n", NR, $1, $2, $6, $4, $5
            }'
        else
            echo "Canceled."
        fi
        ;;

    3)
        echo -n "Enter team abbreviation (e.g., NYY, LAD, BOS): "
        read team
        result=$(awk -F, -v team="$team" '
            BEGIN {count = 0; sum_age = 0; sum_hr = 0; sum_rbi = 0}
            NR > 1 && $4 == team {
                sum_age += $3
                sum_hr += $15
                sum_rbi += $16
                count++
            }
            END {
                if (count == 0)
                    print "Error: Team \"" team "\" not found."
                else {
                    printf "Team stats for %s:\n", team
                    printf "Average age: %.1f\n", sum_age / count
                    printf "Total home runs: %d\n", sum_hr
                    printf "Total RBI: %d\n", sum_rbi
                }
            }' "$CSV_FILE")
        echo "$result"
        ;;

    4)
        echo "Compare players by age groups:"
        echo "1. Group A (Age < 25)"
        echo "2. Group B (Age 25-30)"
        echo "3. Group C (Age > 30)"
        echo -n "Select age group (1-3): "
        read group

        case "$group" in
        1)
            condition='($3 < 25 && $8 >= 502)'
            label="Group A (Age < 25)"
            ;;
        2)
            condition='($3 >= 25 && $3 <= 30 && $8 >= 502)'
            label="Group B (Age 25-30)"
            ;;
        3)
            condition='($3 > 30 && $8 >= 502)'
            label="Group C (Age > 30)"
            ;;
        *)
            echo "Invalid selection."
            continue
            ;;
        esac

        echo "Top 5 by SLG in $label:"
        awk -F, -v cond="$condition" '
            NR > 1 {
                if ('$condition') {
                    print $2 "," $4 "," $3 "," $21 "," $20 "," $15
                }
            }' "$CSV_FILE" | sort -t, -k4 -nr | head -n 5 | awk -F, '{
            printf "%s (%s) - Age: %s, SLG: %s, BA: %s, HR: %s\n", $1, $2, $3, $4, $5, $6
        }'
        ;;

    5)
        echo "Find players with specific criteria"
        echo -n "Minimum home runs: "
        read min_hr
        echo -n "Minimum batting average (e.g., 0.280): "
        read min_ba

        echo "Players with HR ≥ $min_hr and BA ≥ $min_ba:"
        awk -F, -v hr="$min_hr" -v ba="$min_ba" '
            NR > 1 && $8 >= 502 && $15 >= hr && $20 >= ba {
                printf "%s,%s,%s,%s,%s,%s\n", $2, $4, $15, $20, $16, $21
        }' "$CSV_FILE" | sort -t, -k3 -nr | awk -F, '{
            printf "%s (%s) - HR: %s, BA: %s, RBI: %s, SLG: %s\n", $1, $2, $3, $4, $5, $6
        }'
        ;;

    6)
        echo "Generate a formatted player report for which team?"
        echo -n "Enter team abbreviation (e.g., NYY, LAD, BOS): "
        read team

        count=$(awk -F, -v team="$team" 'NR > 1 && $4 == team {print $0}' "$CSV_FILE" | wc -l)

        if [ "$count" -eq 0 ]; then
            echo "Error: Team \"$team\" not found."
        else
            echo "================== $team PLAYER REPORT =================="
            echo -n "Date: "
            date +%Y/%m/%d
            echo "-------------------------------------------------------"
            echo "PLAYER                     HR   RBI   AVG   OBP   OPS"
            echo "-------------------------------------------------------"
            awk -F, -v team="$team" 'NR > 1 && $4 == team {
                printf "%-25s %3d  %4d  %.3f  %.3f  %.3f\n", $2, $15, $16, $20, $21, $23
            }' "$CSV_FILE" | sort -k2 -nr
            echo "--------------------------------------"
            echo "TEAM TOTALS: $count players"
        fi
        ;;

    7)
        echo "Have a good day!"
        exit 0
        ;;

    *)
        echo "Invalid command. Please enter a number from 1 to 7."
        ;;
    esac
    echo ""
done
