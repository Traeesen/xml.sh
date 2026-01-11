#!/bin/bash

tag="$1"  #al doilea argument
attr="$2" #al treilea argument

OK=0
NAME=""

while read -r line; do

  if [ -n "$attr" ]; then  #Verificam daca exista un atribut.
    if [[ "$line" =~ \<$tag ]]; then   #Verificam daca linia curenta este de forma "<tag...", unde tag este tag-ul transmis de noi
      tmp="$line"   
      tmp="${tmp#*${attr}=\"}"
      tmp="${tmp%%\"*}"
      echo "$tmp"
    #Retinem valoarea atributului in variabila tmp, in urma eliminarii spatiilor din jurul ei. 
    fi
    continue
  fi

  if [[ "$line" =~ \<$tag\>.*\</$tag\> ]]; then #Verificam daca linia curenta este de forma "<tag>...</tag>", unde tag este tag-ul transmis de noi
    val="${line#*>}"
    val="${val%%<*}"
    echo "$val"
    continue
    #Retinem valoarea dintre tag-uri in variabila val, in urma eliminarii spatiilor din jurul ei, dupa care o afisam si trecem la linia urmatoare.
  fi

  if [[ "$line" =~ ^[[:space:]]*\<${tag}\>[[:space:]]*$ ]]; then #Verificam daca linia curenta este de forma "<tag>"
    OK=1
    continue
    #Stabilim OK=1, pentru a stii ca suntem inauntrul tag-ului.
  fi

  if [ "$OK" -eq 1 ] && [[ ! "$line" =~ \</$tag\> ]]; then #Verificam daca OK este egal cu 1 si daca linia nu este de forma "/tag", unde tag este tag-ul transmis de noi.
    NAME="$line"
    continue
    #Retinem in variabila NAME numele valorii dinauntrul tagului transmis de noi.
  fi

  if [ "$OK" -eq 1 ] && [[ "$line" =~ \</$tag\> ]]; then #Verificam daca OK este egal cu 1 si daca linia este de forma "/tag", unde tag este tag-ul transmis de noi.
    echo "$NAME"
    OK=0
    NAME=""
    #Afisam numele variabilei NAME si restabilim OK=0, dupa care golim variabila NAME.
  fi

done
