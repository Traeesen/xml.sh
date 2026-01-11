#!/usr/bin/bash

FILE="$1"
OUT=""

CUR_DEPTH=0

xml=$(<"$FILE")
while [ -n "$xml" ]; do
    if [[ "$xml" =~ \<([^>]+)\> ]]; then # Regex pattern matches a tag.

        PREFIX="${xml%%${BASH_REMATCH[0]}*}" # Everything before the current tag.
        TAG="${BASH_REMATCH[0]}" # The value of the tag.
        xml="${xml#*${BASH_REMATCH[0]}}" # Removes everything before and including the tag from the rest of the file.

        if [[ -n "$PREFIX" ]]; then
            PREFIX="${PREFIX#"${PREFIX%%[![:space:]]*}"}"
            PREFIX="${PREFIX%"${PREFIX##*[![:space:]]}"}"
            if [[ -n "$PREFIX" ]]; then
                OUT+="  $indent$PREFIX"$'\n'
            fi
        fi

        if [[ ${TAG:1:1} == "/" ]]; then # Closing tag.
            ((CUR_DEPTH--))
            indent=""
            for(( i=0; i<CUR_DEPTH; i++ )); do
                indent+="  "; 
            done
            OUT+="$indent$TAG"$'\n'
            
        else # Opening tag
            indent=""
            for(( i=0; i<CUR_DEPTH; i++ )); do
                indent+="  "; 
            done
            OUT+="$indent$TAG"$'\n'
            ((CUR_DEPTH++))
        fi

    fi

done

OUT+=$xml
printf '%s\n' "$OUT"