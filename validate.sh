#!/bin/bash

file="$1"

#ne vom folosi de o stiva pentru procesul de validare tocmai pentru faptul ca tag urile dintr un xml trebuie sa respecte principiul unei stiva(last in, first out)
stack=()

#pentru comoditate am creat functii de push si pop pe stiva
push(){
    stack+=("$1")
}

pop() {
    unset 'stack[-1]'
}

#functia prelucreaza are rolul de a inspecta tag urile trimise ca parametru 
prelucreaza(){
    local tag="$1"
    #aici verificam daca tag ul este inchidere
    if [[ "$tag" == /* ]]; then
        tag="${tag:1}"
        #aici verificam daca stiva este goala daca da cu siguranta xmlul este invalid in vreme ce am primit acum un tag de inchidere deoarece nu aveam inainte niciun tag deschis care ar fi trebuit inchis
        if [ ${#stack[@]} -eq 0 ]; then
            echo "XML Invalid"
            exit 1
        fi
        #verificam daca tag ul de inchidere fara "/" ul de la inceput este diferit fata de ultimul tag din stiva daca da clar xmlul este invalid
        if [[ "${stack[-1]}" != "$tag" ]]; then
            echo "XML Invalid"
            exit 1
        else
            pop
        fi
    else
        #impartim tag ul in tag name si atribute tocmai pentru faptul ca tag urile de deschidere pot avea atribute
        tag_name="${tag%% *}"
        atribute="${tag#"$tag_name"}"
        if [[ -n "$atribute" ]]; then
            #cu ajutorul unei expresii regulate verificam daca atributele sunt bine scrise(un atribut in xml trebuie sa fie de forma: atribut="ceva" incorect atribut=1 spre exemplu)
            if ! [[ "$atribute" =~ ^([[:space:]]+[a-zA-Z_][a-zA-Z0-9_-]*=\"[^\"]*\")+$ ]]; then
                echo "XML Invalid"
                exit 1
            fi
        fi
        #punem numele tag ului pe stiva
        push "$tag_name"
    fi
}
#iteram prin fisier linie cu linie 
while IFS= read -r linie; do
    #iteram prin fisier pentru a identifica tagurile(tot cu ajutorul unei expresii regulate identificam un tag ca fiind ceva intre "<" si ">")
    while [[ "$linie" =~ \<([^>]*)\> ]]; do
        #cu ajutorul BASH_REMATCH[1] scoatem doar ce este in interiorul la "<" si ">"
        tag="${BASH_REMATCH[1]}"
        prelucreaza "$tag"
        linie="${linie#*>}"
    done
done < "$file"

#daca stiva e goala atunci xml este valid
if [ ${#stack[@]} -eq 0 ]; then
    echo "XML Valid"
    exit 0
else
    echo "XML Invalid"
    exit 1
fi
