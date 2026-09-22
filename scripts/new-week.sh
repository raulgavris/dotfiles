#!/bin/bash
# new-week.sh — Creates weekly Reflecție Săptămânală note in Apple Notes
# Usage: ./new-week.sh [DD-MM-YYYY]  (defaults to next Saturday, or today if Saturday)

if [ -n "$1" ]; then
    DATE_STR="$1"
else
    DOW=$(date +%u)  # 1=Mon, 6=Sat, 7=Sun
    if [ "$DOW" -eq 6 ]; then
        DATE_STR=$(date +"%d-%m-%Y")
    else
        DAYS_UNTIL_SAT=$(( (6 - DOW + 7) % 7 ))
        if [ "$DAYS_UNTIL_SAT" -eq 0 ]; then
            DAYS_UNTIL_SAT=7
        fi
        DATE_STR=$(date -v+"${DAYS_UNTIL_SAT}"d +"%d-%m-%Y")
    fi
fi

TITLE="🔥 Reflecție Săptămânală — $DATE_STR"

echo "Creating Reflecție Săptămânală for $DATE_STR..."

CS="border-style: solid; border-width: 1.0px 1.0px 1.0px 1.0px; border-color: #ccc; padding: 3.0px 5.0px 3.0px 5.0px; min-width: 70px"

osascript <<EOF
tell application "Notes"
    set betterMe to folder "Better Me"
    set targetFolder to folder "Reflecții" of betterMe

    set existingNotes to (every note of targetFolder whose name is "$TITLE")
    if (count of existingNotes) > 0 then
        return "SKIP: Reflecție already exists for $DATE_STR"
    end if

    set cs to "$CS"
    set n to ""
    set n to n & "<div>🔥<b> Reflecție Săptămânală — $DATE_STR</b></div>"
    set n to n & "<div><i>&bdquo;Alerg spre țintă, spre premiul chemării de sus a lui Dumnezeu, în Hristos Iisus.&rdquo; &mdash; Filipeni 3:14</i></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Misiunea mea:</b></div>"
    set n to n & "<div><i>&bdquo;Toate le fac pentru Cel care mă întărește &mdash; îmi disciplinez mintea, corpul și craft-ul ca să fiu un om pe care Dumnezeu îl poate folosi oricând, și o fundație solidă pentru familia mea.&rdquo;</i></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Săptămâna trecută media: _/10</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Top 3 wins:</b></div>"
    set n to n & "<ul><li></li><li></li><li></li></ul>"
    set n to n & "<div><b>Top 3 lecții:</b></div>"
    set n to n & "<ul><li></li><li></li><li></li></ul>"
    set n to n & "<div><b>1. Unde am cedat săptămâna asta?</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>2. Unde am rezistat când era greu?</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>3. Ce vreau să fac mai bine săptămâna viitoare?</b></div>"
    set n to n & "<ul><li></li><li></li><li></li></ul>"
    set n to n & "<div><b>4. Pentru ce sunt recunoscător?</b></div>"
    set n to n & "<ul><li></li><li></li><li></li></ul>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Scorecard săptămânal (1-10):</b></div>"

    set t to "<object><table cellspacing='0' cellpadding='0' style='border-collapse: collapse; direction: ltr'><tbody>"
    set t to t & "<tr><td valign='top' style='" & cs & "'><div><b>Arie</b></div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><div><b>Scor</b></div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><div><b>Note</b></div></td></tr>"
    set t to t & "<tr><td valign='top' style='" & cs & "'><div>Credință</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><div>/10</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><br></td></tr>"
    set t to t & "<tr><td valign='top' style='" & cs & "'><div>Craft (programming/security)</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><div>/10</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><br></td></tr>"
    set t to t & "<tr><td valign='top' style='" & cs & "'><div>Fizic (sală + alergare)</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><div>/10</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><br></td></tr>"
    set t to t & "<tr><td valign='top' style='" & cs & "'><div>Familie</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><div>/10</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><br></td></tr>"
    set t to t & "<tr><td valign='top' style='" & cs & "'><div>Disciplină generală</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><div>/10</div></td>"
    set t to t & "<td valign='top' style='" & cs & "'><br></td></tr>"
    set t to t & "</tbody></table></object>"

    set n to n & "<div>" & t & "</div>"
    set n to n & "<div><b>Media săptămânii: /10</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Ce am învățat din Bible Study săptămâna asta care m-a marcat cel mai mult?</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Un lucru pe care vreau să-l schimb începând de luni:</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><i>&bdquo;Cercetează-mă, Dumnezeule, și cunoaște-mi inima! Încearcă-mă și cunoaște-mi gândurile!&rdquo; &mdash; Psalmul 139:23</i></div>"

    set noteBody to "<html><head></head><body>" & n & "</body></html>"
    make new note at targetFolder with properties {body:noteBody}
    return "OK: Reflecție created"
end tell
EOF

echo "Done!"
