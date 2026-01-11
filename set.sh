#!/bin/bash

#calea fisierului
file="$1"

#calea in fisierul xml care trebuie modificata
cale="$2"

#valoarea cu care o modificam
x="$3"

#o copie a caii din fisier o sa ne trebuiasca la final la afisare
cale_afis="$2"

#lista cu tag uri
tag_arr=()

#lista cu indexi
index_arr=()

#adancimea setata la minus 1 pentru ca ea este incrementata imediat ce este gasit un tag deshis
adancime=-1

#elementul curent pleaca de la pozitia 0 pentru ca pima pozitie intr un array este 0
element_curent=0

inside_value=0
flag=0


skip=0
skip_depth=0

tmpfile=$(mktemp)

cale="${cale#/}"

#pune tag-urile si indexii corespunzatori in tag_arr respectiv index_arr
while [[ "$cale" =~ ^([^/]+)(/.*)?$ ]]; do
    segment="${BASH_REMATCH[1]}"
    rest="${BASH_REMATCH[2]}"

    if [[ "$segment" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)\[([0-9]+)\]$ ]]; then
        tag="${BASH_REMATCH[1]}"
        idx="${BASH_REMATCH[2]}"
    else
        tag="$segment"
        idx=1
    fi

    tag_arr+=("$tag")
    index_arr+=("$idx")

    cale="${rest#/}"
done

#calculeaza targetul la care trebuie sa ajugem pentru a schimba valoare acela fiind lungimea tag_arr - 1 deoarece aceea este lungimea caii care ne este pasata drept paramerru la lina de comanda
target=$((${#tag_arr[@]} - 1))


#vom itera pe fiecare linie si vom pastra identarile iar ulterior vom itera pe fiecare linie in parte pentru a identifica tag-urile
while IFS= read -r linie; do
    if (( inside_value == 1 )); then
        value_indent="${linie%%[^[:space:]]*}"
        value_suffix="${linie##*[![:space:]]}"
        linie="${value_indent}${x}${value_suffix}"
        inside_value=0
    fi

    if (( flag == 1 )); then
        printf '%s\n' "$linie" >> "$tmpfile"
        continue
    fi


    linie_out="$linie"
    work="$linie"

    while [[ "$work" =~ \<([^>]*)\> ]]; do
        tag="${BASH_REMATCH[1]}"
        tag_name="${tag%% *}"
        #verificam daca e cazul de skip adica daca avem din intamplare un tag cu indexul mai mare decat 1
        if (( skip == 1 )); then
            if [[ "$tag" != /* ]]; then
                ((adancime+=1))
            else
                ((adancime-=1))
                if (( adancime == skip_depth )); then
                    skip=0
                fi
            fi

            work="${work#*>}"
            continue
        fi
        #verificam daca am intalnit un tag de deschidere
        if [[ "$tag" != /* ]]; then
            ((adancime+=1))
            #verificam daca adincimea este egala cu numarul de ordine al elementului curent adica pozitia pe care o ocupa elementul curent in array
            if (( adancime == element_curent )); then
                if [[ "${tag_arr[$element_curent]}" == "$tag_name" ]]; then
                    #verificam daca indexul elementului curent este 1 daca da putem inainta pe cale altfel trebuie sa intram in skip mode
                    if [[ "${index_arr[$element_curent]}" -eq 1 ]]; then
                        index_arr[$element_curent]=0
                        #daca elementul curent este egal cu targetul atunci e bine yaaay am ajuns unde planuiam
                        if (( element_curent == target )); then
                            if [[ "$linie_out" =~ \<"$tag_name"\>.*\<\/"$tag_name"\> ]]; then
                                linie_out="$(sed -E "s|(<$tag_name>[[:space:]]*)[^<]*([[:space:]]*</$tag_name>)|\1$x\2|" <<< "$linie_out")"
                                echo "Valoarea a fost schimbata la calea: $cale_afis"
                                flag=1
                            elif [[ "$linie_out" =~ \<"$tag_name"\> ]]; then
                                inside_value=1
                                echo "Valoarea a fost schimbata la calea: $cale_afis"
                                flag=1
                            fi
                        else
                            ((element_curent++))
                        fi
                    #cum am spus intram in skip mode
                    else
                        ((index_arr[$element_curent]--))
                        skip=1
                        skip_depth=$((adancime - 1))
                    fi
                fi
            fi
        else
            #aici este cazul in care tag ul este de inchidere
            closing_name="${tag:1}"
            closing_name="${closing_name%% *}"
            #scadem adancimea deoarece ne intoarcem pe un nivel mai sus cand inchidem un tag
            ((adancime-=1))

            if (( element_curent > 0 )) && [[ "$closing_name" == "${tag_arr[$((element_curent-1))]}" ]]; then
                ((element_curent--))
            fi
        fi

        work="${work#*>}"
    done

    #punem outputul pe care l am creat in variabila linie out intr un fisier temporar
    printf '%s\n' "$linie_out" >> "$tmpfile"

done < "$file"

#mutam fisierul temporar in fisierul principal daca flag ul este setat la 1 (adica daca a ajuns sa faca schimbarea daca nu a facut nicio schimbare atunci calea este una incorecta) 
if (( flag == 1 )); then
    mv "$tmpfile" "$file"
else
    echo "cale incorecta"
    rm -f "$tmpfile"
fi

exit 0
