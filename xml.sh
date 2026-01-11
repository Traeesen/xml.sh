#!/bin/bash

#verificare daca exita fisierul trimis ca paremetru la linia de comanda
if [ $# -lt 1 ]; then
    exit 1
fi

file="$1"
shift


tag=""
item=""
valoare=""

out="$(./validate.sh "$file" | tr -d '\r\n')"

if [[ "$out" == "XML Invalid" ]]; then
    echo "XML Invalid"
    exit 0
fi



while [ $# -gt 0 ]; do
    case "$1" in
        -validate)
            ./validate.sh "$file"
            shift
            ;;  
        -list)
            ./list.sh "$file"
            shift
            ;;
        -set)
            if [ $# -lt 3 ]; then
                echo "Parametrii invalizi"
                exit 1
            fi

            item="$2"
            valoare="$3"
            ./set.sh "$file" "$item" "$valoare"
            shift 3
            ;;
        -get)
            if [ $# -lt 2 ]; then
                echo "Parametrii invalizi"
                exit 1
            fi
            tag="$2"
            ./prettify.sh "$file" | ./get.sh "$tag"
            shift 2
            ;;
       -insert)
            if [ $# -lt 3 ]; then
                echo "Parametrii invalizi"
                exit 1
            fi
            item="$2"
            tag="$3"
            ./insert.sh "$file" "$item" "$tag"
            shift 3
           ;;
        -prettify)
            ./prettify.sh "$file" 
            shift
            ;;
        *)
            shift
            ;;
    esac
done

exit 1
