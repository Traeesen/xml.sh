#!/bin/bash

file="$1" #In aceasta variabila retinem numele primului argument.
stiva=()  #Stiva o vom folosi pentru memorarea tag-urilor.
path=""   #In aceasta variabila retinem numele tag-urilor, separate de '/'.

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  echo "$s"
}
#In aceasta functie, eliminam spatiile din jurul variabilei s, dupa care returnam s.

regex1='<([a-zA-Z0-9]+)>.*</\1>'

while read -r line; do
  line="$(trim "$line")"
  [ -z "$line" ] && continue


  if [[ $line =~ $regex1 ]]; then
    tag="${BASH_REMATCH[1]}"
    val="${line#*>}"
    val="${val%%<*}"
    echo "$path/$tag = \"$val\""
    continue
  fi
  
  # Aceasta conditie verifica daca linia curenta este de forma <tag>...</tag>. In acest caz, retinem numele tag-ului in variabila tag si valoarea sa in variabila val,
  # dupa ce eliminam spatiile din jurul ei. In cele din urma, afisam calea curenta, adaugand la ea numele tag-ului respectiv, precum si valoarea dinauntrul tag-urilor
  # si trecem la urmatoarea linie.

  if [[ $line =~ ^\<([a-zA-Z0-9_]+)([[:space:]]+[^>]*)?\>$ ]]; then
    tag="${BASH_REMATCH[1]}"
    stiva+=("$tag")
    path="/$(IFS=/; echo "${stiva[*]}")"
    echo "$path"
    continue
  fi

  # Aceasta conditie verifica daca linia curenta este de forma <tag> si daca contine totodata si atribute (ex:<tag id="nume">). In acest caz, retinem numele tag-ului in variabila tag,
  # dupa care il vom adauga pe stiva. In urmatoarea linie, "punem stiva in variabila path", punand atat intre fiecare element din stiva '/', cat si la inceputul valorii lui path, folosind
  # separatorul de text IFS. In cele din urma, afisam ce am obtinut in variabila path si trecem la urmatoarea linie. 

  if [[ $line =~ ^\</([a-zA-Z0-9_]+)\>$ ]]; then
    unset 'stiva[-1]'
    path="/$(IFS=/; echo "${stiva[*]}")"
    continue
  fi

  # Aceasta conditie verifica daca linia curenta este de forma </tag>. In acest caz, eliminam ultimul tag din stiva si, ca in conditia precedenta, folosind IFS, atribuim variabilei path
  # ce obtinem in urma punerii a cate un '/' atat intre fiecare tag, cat si la inceput. In cele din urma, trecem la urmatoarea linie.

  if [[ ! $line =~ \<.*\> ]]; then
    echo "$path = \"$line\""
  fi

  # Aceasta conditie verifica daca linia curenta contine doar o valoare dintre tag-uri. In acest caz, afisam valoarea variabilei path, adaugand la ea "=" si numele valorii respective.

done < "$file"
