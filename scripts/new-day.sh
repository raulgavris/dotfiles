#!/bin/bash
# new-day.sh — Creates daily Bible Study + Learning Journal notes in Apple Notes
# Usage: ./new-day.sh [DD-MM-YYYY]  (defaults to today)

if [ -n "$1" ]; then
    DATE_STR="$1"
else
    DATE_STR=$(date +"%d-%m-%Y")
fi

BS_TITLE="📖 Bible Study — $DATE_STR"
LJ_TITLE="📘 Learning Journal — $DATE_STR"

echo "Creating notes for $DATE_STR..."

# ─── Bible Study ───
osascript <<EOF
tell application "Notes"
    set betterMe to folder "Better Me"
    set targetFolder to folder "Bible Study" of betterMe

    set existingNotes to (every note of targetFolder whose name is "$BS_TITLE")
    if (count of existingNotes) > 0 then
        return "SKIP: Bible Study already exists for $DATE_STR"
    end if

    set n to ""
    set n to n & "<div>📖<b> Bible Study — $DATE_STR</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><i>&bdquo;Fiiți împlinitori ai Cuvântului, nu numai ascultători.&rdquo; &mdash; Iacov 1:22</i></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Plan de citire:</b> [carte] cap X-Y</div>"
    set n to n & "<div><b>Ieri am citit:</b> ...</div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Ce am citit azi?</b></div>"
    set n to n & "<ul><li><b>Cartea:</b></li><li><b>Capitolul / Versetele:</b></li></ul>"
    set n to n & "<div><b>Ce mi-a atras atenția?</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Ce înțeleg despre caracterul lui Dumnezeu din acest pasaj?</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Cum se aplică asta în viața mea concret?</b></div>"
    set n to n & "<ul><li><b>Mâine voi:</b></li></ul>"
    set n to n & "<div><b>Aplicare practică (verifică mâine):</b></div>"
    set n to n & "<ul><li>☐ </li><li>☐ </li></ul>"
    set n to n & "<div><b>Verset cheie de memorat:</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Rugăciune:</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><i>&bdquo;Cuvântul Tău este o candelă pentru picioarele mele și o lumină pe cărarea mea.&rdquo; &mdash; Psalmul 119:105</i></div>"

    set noteBody to "<html><head></head><body>" & n & "</body></html>"
    make new note at targetFolder with properties {body:noteBody}
    return "OK: Bible Study created"
end tell
EOF

# ─── Learning Journal ───
osascript <<EOF
tell application "Notes"
    set betterMe to folder "Better Me"
    set targetFolder to folder "Learning" of betterMe

    set existingNotes to (every note of targetFolder whose name is "$LJ_TITLE")
    if (count of existingNotes) > 0 then
        return "SKIP: Learning Journal already exists for $DATE_STR"
    end if

    set n to ""
    set n to n & "<div>📘<b> Learning Journal — $DATE_STR</b></div>"
    set n to n & "<div><i>&bdquo;Toate le fac pentru Cel care mă întărește &mdash; îmi disciplinez mintea, corpul și craft-ul ca să fiu un om pe care Dumnezeu îl poate folosi oricând, și o fundație solidă pentru familia mea.&rdquo;</i></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Obiectivul săptămânii:</b> ...</div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Ce am studiat azi?</b></div>"
    set n to n & "<ul><li><b>Subiect:</b></li><li><b>Resurse folosite:</b></li></ul>"
    set n to n & "<div><b>Timp studiu:</b> ___ min</div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Ce am învățat?</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Ce NU am înțeles?</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Conexiuni cu ce am învățat anterior:</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><b>Ce fac mâine concret?</b></div>"
    set n to n & "<ul><li></li></ul>"
    set n to n & "<div><b>Nivel de focus (1-10):</b></div>"
    set n to n & "<div><b>Note extra:</b></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><br></div>"
    set n to n & "<div><i>&bdquo;Nu că am și câștigat, dar alerg înainte.&rdquo; &mdash; Filipeni 3:12</i></div>"

    set noteBody to "<html><head></head><body>" & n & "</body></html>"
    make new note at targetFolder with properties {body:noteBody}
    return "OK: Learning Journal created"
end tell
EOF

echo "Done!"
