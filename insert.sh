#!/usr/bin/bash

FILE="$1"
RAW_PATH="$2"
INSERT="$3"
OUT=""

if [[ "${RAW_PATH:0:1}" == "/" ]]; then
    RAW_PATH="${RAW_PATH:1}" # Trim first '/' from path input.
fi

TARGET_PATH=()
IFS="/" read -r -a TARGET_PATH <<< "$RAW_PATH" # This organises the path into a depth-accesible array.
TARGET_SIZE=${#TARGET_PATH[@]}
((TARGET_SIZE--))

TARGET_INDEXES=()
for ((i=0; i<=TARGET_SIZE; i++)); do
    if [[ "${TARGET_PATH[$i]}" =~ ^([^\[]+)\[([^\]]+)\]$ ]]; then # This regex atrocity checks if there's a specified index.
        TARGET_PATH[$i]=${BASH_REMATCH[1]}
        TARGET_INDEXES[$i]=${BASH_REMATCH[2]}
    else
        TARGET_INDEXES[$i]=""
    fi 
done

CUR_DEPTH=0
CUR_VALID=-1
BAD_INDEX_DEPTH=-1

SEARCHED_INDEXES=()
for ((i=0; i<=TARGET_SIZE; i++)); do
    SEARCHED_INDEXES+=(0)
done
FOUND_VALID=()
for ((i=0; i<=TARGET_SIZE; i++)); do
    FOUND_VALID+=(0)
done

xml=$(<"$FILE")
while [ -n "$xml" ]; do
    if [[ "$xml" =~ \<([^>]+)\> ]]; then # Regex pattern matches a tag.
        tag=${BASH_REMATCH[1]%%[[:space:]]*} # Remove any attributes and <>s, we only need the tag name.

        if [[ ${tag:0:1} == "/" ]]; then # We found a closing tag.

            if [[ ${FOUND_VALID[$CUR_DEPTH]} -eq 0 && BAD_INDEX_DEPTH -eq -1 && "$tag" = "/${TARGET_PATH[$CUR_DEPTH-1]}" ]]; then # Path does not exist, but must be made.
                #echo "PASSED FORCED INSERTION CHECK WITH TAG $tag."

                for((i=CUR_DEPTH; i<=TARGET_SIZE; i++)); do
                    indent=""
                    for((j=0;j<i;j++)); do
                        indent+="  "
                    done
                    if [[ "${OUT: -1}" != $'\n' ]]; then
                        OUT+=$'\n'
                    fi
                    OUT+="$indent<${TARGET_PATH[$i]}>"
                done

                indent=""
                for((j=0;j<TARGET_SIZE+1;j++)); do
                    indent+="  "
                done
                OUT+=$'\n'"$indent$INSERT"

                for((i=TARGET_SIZE; i>=CUR_DEPTH; i--)); do
                    indent=""
                    for((j=0;j<i;j++)); do
                        indent+="  "
                    done
                    if [[ "${OUT: -1}" != $'\n' ]]; then
                        OUT+=$'\n'
                    fi
                    OUT+="$indent</${TARGET_PATH[$i]}>"
                done

                FOUND_VALID[$CUR_DEPTH]=1
            fi

            #echo "Insert status: ${FOUND_VALID[$CUR_DEPTH]} Index: $BAD_INDEX_DEPTH $tag"

            if [[ FOUND_VALID[$CUR_DEPTH] -eq 1 ]]; then FOUND_VALID[$((CUR_DEPTH-1))]=1; fi
            FOUND_VALID[$CUR_DEPTH]=0;
            ((CUR_DEPTH--))
            if (( CUR_DEPTH == CUR_VALID )); then
                CUR_VALID=-1
            fi
            if ((CUR_DEPTH == BAD_INDEX_DEPTH)); then
                BAD_INDEX_DEPTH=-1
            fi

            OUT+="${xml%%${BASH_REMATCH[0]}*}" # Stores everything before the current tag.
            OUT+="${BASH_REMATCH[0]}" # Adds the tag as well.
            xml="${xml#*${BASH_REMATCH[0]}}" # Removes everything before and including the tag from the rest of the file.

        else # If it isn't a closing tag, it's an opening tag

            OUT+="${xml%%${BASH_REMATCH[0]}*}" # Stores everything before the current tag.
            OUT+="${BASH_REMATCH[0]}" # Adds the tag as well.
            xml="${xml#*${BASH_REMATCH[0]}}" # Removes everything before and including the tag from the rest of the file.

            if (( CUR_VALID == -1 && BAD_INDEX_DEPTH == -1)); then
                #echo "Comparing $tag to ${TARGET_PATH[$CUR_DEPTH]}"
                if [[ "$tag" = "${TARGET_PATH[$CUR_DEPTH]}" ]]; then # Tags are equal.

                    if [[ ! -z "${TARGET_INDEXES[$CUR_DEPTH]}" ]]; then # We're searching for a specific index.

                        ((SEARCHED_INDEXES[$CUR_DEPTH]++)) 
                        if (( SEARCHED_INDEXES[$CUR_DEPTH] != TARGET_INDEXES[$CUR_DEPTH] && BAD_INDEX_DEPTH == -1)); then 
                            BAD_INDEX_DEPTH=$CUR_DEPTH
                        else
                            if (( CUR_DEPTH == TARGET_SIZE )); then
                                indent=""
                                for((i=0; i<=CUR_DEPTH; i++)); do
                                    indent+="  "
                                done
                                OUT+=$'\n'
                                OUT+="$indent$INSERT"
                                FOUND_VALID[$CUR_DEPTH+1]=1
                            fi
                        fi
                    else 
                        if (( CUR_DEPTH == TARGET_SIZE )); then
                                indent=""
                                for((i=0; i<=CUR_DEPTH; i++)); do
                                    indent+="  "
                                done
                                OUT+=$'\n'
                                OUT+="$indent$INSERT"
                                FOUND_VALID[$CUR_DEPTH+1]=1
                        fi
                    fi
                else # Everything until we reach a lower index is invalid.
                    CUR_VALID=$CUR_DEPTH
                    ((CUR_VALID--))
                fi
            fi 
            ((CUR_DEPTH++))
        fi
    fi

done

OUT+=$xml
printf '%s' "$OUT"