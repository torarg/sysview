STATUSES="critical warning outdated unknown ok"
STATUSES_FOOTER="ok warning critical outdated unknown"

html_head() {
    echo "$(cat <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>sysview: $1</title>
        <link rel="stylesheet" href="style.css">
        <link rel="icon" type="image/png" href="favicon-96x96.png" sizes="96x96" />
        <link rel="icon" type="image/svg+xml" href="favicon.svg" />
        <link rel="shortcut icon" href="favicon.ico" />
        <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png" />
        <link rel="manifest" href="site.webmanifest" />
        <meta name="apple-mobile-web-app-title" content="sysview" />
        <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0">
        <meta http-equiv="refresh" content="60">
    </head>
    <body>
    <header>
        <div><a class="header_link" href=index.html>sysview</a></div>
        <div>:</div>
        <div>$1</div>
    </header>
    <div class="menu">
EOF
)"
    # slightly modified order for footer
    for _status in $STATUSES_FOOTER; do
        echo "<a href=${_status}.html><p id='legend' class='item_${_status}'>${_status}</p></a>"
    done
    echo "    </div>"
}

html_main_start() {
    echo "$(cat <<EOF
    <main>
    <section class="tiles-container">
EOF
)"
}

html_main_end() {
    echo "$(cat <<EOF
    </section>
    </main>
EOF
)"
}

html_foot() {
    echo "$(cat <<EOF
    <footer>
    <div><p>version: $VERSION</p></div>
    </footer>
    </body>
</html>
EOF
)"
}

update_outdated() {
    find ${cache_dir}/ -name "*.html" -mtime +${outdated_after} -exec sed -i 's/pre class="item_.*$/pre class="item_outdated">/g' {} \;
    find ${cache_dir}/ -name "*.html.detail.part.*" -mtime +${outdated_after} -exec sed -i 's/pre class="item_.*$/pre class="item_outdated">/g' {} \;
    find ${cache_dir}/ -name "*.html.overview.part" -mtime +${outdated_after} -exec sed -i 's/div class="tile_.*$/div class="tile_outdated">/g' {} \;
}


parse_report_items() {
    item_count=0
    item_pointer=0
    item_title="no"
    header_printed="no"
    items=""
    while read line; do
        if echo "$line" |egrep -q '^OK:|^CRITICAL:|^WARNING:|^UNKNOWN:' && [ "$header_printed" == "no" ] ; then
            item_status="$(echo $line | cut -f 1 -d ':' |  tr '[:upper:]' '[:lower:]')"
            items="${items}Date: $date\n--\n${line}"
            items="$(echo "$items" | sed "s/CSS_CLASS/item_$item_status/g")\n"
            header_printed="yes"
        elif [ "$item_title" == "yes" ]; then
            items="${items}<b>${line}</b>\n"
            item_title="no"
        elif [ "$line" == "---" ] && [ "$item_count" -eq "0" ]; then
            item_count=1
            item_pointer=1
            items="${items}<pre class=\"CSS_CLASS\">\n"
            item_title="yes"
            header_printed="no"
        elif [ "$line" == "---" ] && [ "$item_count" -gt "0" ]; then
            items="${items}</pre>\n<pre class=\"CSS_CLASS\">\n"
            item_count="$((item_count + 1 ))"
            item_status=""
            item_title="yes"
            header_printed="no"
        elif [ "$item_count" -gt "0" ] && [ "$item_pointer" -ne "$item_count" ]; then
            items="${items}${line}\n"
            item_pointer="$((item_pointer + 1 ))"
        elif [ "$item_count" -gt "0" ]; then
            items="${items}${line}\n"
        fi
    done
    if [ -n "$items" ]; then
        items="$(echo "$items" | sed '$ d')"
        items="$items\n</pre>"
    fi
    echo "$items"
}


parse_report() {
    report_started=0
    report=""

    while read line; do
        if [[ "$line" == "Hostname: "* ]] ; then
            report_started=1
            hostname=$(echo "$line" | awk '{ print $2 }')
            report="${report}${line}\n"
        elif [[ "$line" == "Date: "* ]] && [ "$report_started" -eq "1" ]; then
            date=$(echo "$line" | cut -f 2- -d " ")
            report="${report}${line}\n"
        elif [[ "$line" == "Type: "* ]] && [ "$report_started" -eq "1" ]; then
            type=$(echo "$line" | cut -f 2- -d " ")
            report="${report}${line}\n"
        elif [ "$report_started" -eq "1" ]; then
            report="${report}${line}\n"
        fi
    done

    if [ -z "$hostname" ] || [ -z "$date" ] || [ -z "$report" ]; then
        echo "failed parsing report"
        exit 0
    fi

    [ -z "$type" ] && type="sysreport" # fallback for now, since this is a new field
    #echo "$report"
}

get_worst_status() {
    text="$report"
    if stat -q ${cache_dir}/${hostname}.html.detail.part.* > /dev/null; then
        #find ${cache_dir}/${hostname}.html.detail.part.* -mtime -1 -exec sed -i 's/pre class="item_outdated.*$/pre class="item_ok">/g' {} \;
        for file in  ${cache_dir}/${hostname}.html.detail.part.*; do
            if [[ "$file" == *".part.${type}"* ]]; then
                continue
            fi
            text="${text}\n$(cat ${file})"
        done
    fi

    if echo "$text" | egrep -q '<pre class="item_outdated">'; then
        worst_status="outdated"
    elif echo "$text" | grep -q "CRITICAL: "; then
        worst_status="critical"
    elif echo "$text" | grep -q "WARNING: "; then
        worst_status="warning"
    elif echo "$text" | grep -q "OK: "; then
        worst_status="ok"
    else
        worst_status="unknown"
    fi
}

process_report() {
    worst_status="unknown"
    parse_report
    report_items="$(echo -e "$report" | parse_report_items)"
    get_worst_status
    overview_part="${cache_dir}/${hostname}.html.overview.part"
    detail_view_part="${cache_dir}/${hostname}.html.detail.part.${type}"
    [ -f "$overview_part" ] && rm $overview_part
    [ -f "$detail_view_part" ] && rm $detail_view_part

    cat > ${overview_part} <<EOF
<a href="$hostname.html">
    <div class="tile_$worst_status">
        <h4>$hostname</h5>
        <p>$date</p>
    </div>
</a>
EOF

    echo "$report_items" > $detail_view_part
}

update_index_cache() {
    tmp_index_file="${cache_dir}/index.html"

    # render overview
    html_head "index" > $tmp_index_file
    html_main_start >> $tmp_index_file
    for status in $STATUSES; do
        for file in ${cache_dir}/*.overview.part; do
            if grep -q "tile_${status}" $file; then
                cat $file >> $tmp_index_file
            fi
        done
    done
    html_main_end >> $tmp_index_file
    html_foot >> $tmp_index_file
}

update_host_cache() {
    tmp_detail_file="${cache_dir}/${hostname}.html"
    # render detail views
    html_head "$hostname" > $tmp_detail_file
    html_main_start >> $tmp_detail_file
    for file in ${cache_dir}/${hostname}.html.detail.part.*; do
        item_updated="no"
        for status in $STATUSES; do
            grep -q "<pre class=\"item_$status\">" $file && cat $file >> $tmp_detail_file && item_updated="yes" && break
        done
        [ "$host_updated" == "yes" ] && continue
    done
    html_main_end >> $tmp_detail_file
    html_foot >> $tmp_detail_file
}

update_status_cache() {
    # render "filtered by status" pages
    for status in $STATUSES; do
        file="${cache_dir}/${status}.html"
        html_head "$status" > $file
        html_main_start >> $file
        for overview_part in ${cache_dir}/*.overview.part; do
            if grep -q "tile_${status}" $overview_part; then
                cat $overview_part >> $file
            fi
        done
        html_main_end >> $file
        html_foot >> $file
    done
}
