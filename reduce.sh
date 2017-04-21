#!/bin/bash

# Put the script in an image tree, it will duplicate the tree in 
# ../___reduce_outputs.
# All jpg will be crushed to 60% and non opaque png will be converted into jpg
# if there is a size win.
# The script generate a ../___reduce_outputs/rename_list.txt with a list
# of png files turned into jpg.


# JPG procedure
function proceedjpg {
  echo '   JPG detected.'
  ext=${1##*\.}
  noext=${1%%.$ext}
  
  convert -strip -quality 60 "$1" "$noext.tmp.$ext"
  
  oldsize=`du -b "$1"  | cut -f1`
  newsize=`du -b "$noext.tmp.$ext"  | cut -f1`
  echo "   $oldsize --> $newsize"
  
  win=`echo '('$oldsize'-'$newsize')*'100'/'$oldsize | bc -l`
  if [ $(echo $win'>'0 | bc -l) -eq 1 ]
  then
    echo "   image reduction : $win%"
    rm "$1"
    mv "$noext.tmp.$ext" "$1"
  else
    echo '   no reduction'
    rm "$noext.tmp.$ext"
  fi
  
}


function proceedpng {
  echo '   PNG detected.'
  ext=${1##*\.}
  noext=${1%%.$ext}
  
  mean=`convert "$1" -alpha on -alpha extract -format "%[fx:mean]" info:`
  if [ $(echo $mean'=='1 | bc -l) -eq 1 ]
  then
    echo '   PNG is opaque, let’s convert it to JPG'
    convert "$1" "$noext.jpg"
    convert -strip -quality 60 "$noext.jpg" "$noext.tmp.jpg"
    
    oldsize=`du -b "$1"  | cut -f1`
    newsize=`du -b "$noext.tmp.jpg"  | cut -f1`
    echo "   $oldsize --> $newsize"
    
    win=`echo '('$oldsize'-'$newsize')*'100'/'$oldsize | bc -l`
    if [ $(echo $win'>'0 | bc -l) -eq 1 ]
    then
      echo "   image reduction : $win%"
      rm "$1" "$noext.jpg"
      mv "$noext.tmp.jpg" "$noext.jpg"
      echo "$1" replaced by "$noext.jpg" >> rename_list.txt
    else
      echo '   no reduction'
      rm "$noext.tmp.jpg" "$noext.jpg"
    fi
  else
    echo '   PNG with transparency. Skip.'
  fi
}

# ====
# MAIN
# ====

echo "GO!"
\rm -rf ../___reduce_outputs
cp -r . ../___reduce_outputs
cd ../___reduce_outputs

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for f in `find -type f -iregex '.*\.\(jpg\|png\|JPG\|PNG\)'`
do
  n=`basename "$f"`
  # echo "$n"
  echo "----------------------------------------"
  echo -- reducing "$f"...
  ext=${f##*\.}
  case "$ext" in
    jpg) proceedjpg "$f"
      ;;
    JPG) proceedjpg "$f"
      ;;
    png) proceedpng "$f"
      ;;
    PNG) proceedpng "$f"
      ;;
    *) echo " $f : Not processed"
      ;;
  esac
  echo "   done"
done
echo "----------------------------------------"
echo "see ../___reduce_outputs/rename_list.txt to get list of renamed files."
IFS=$SAVEIFS

cd -
