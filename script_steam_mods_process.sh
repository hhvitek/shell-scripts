#!/bin/bash

# for every file found (mod/*/descriptor.mod) do the following:
# 1] remove existing path= variable
# 2] remove existing archive= variable
# 3] add modified path= variable
# 4] remove all empty lines
# 5] copy result file to a file's parent folder with different a modified name (use parent folder name)

MOD_FOLDER="mod"

FILES="$MOD_FOLDER/*/descriptor.mod"

for mod_descriptor_filename in $FILES; do
    if [ ! -e "$mod_descriptor_filename" ]; then
        continue
    fi
    
    echo
    echo "---- $mod_descriptor_filename ----"
    
    #    echo "GREP PERL"
    #    smallish issue here... path="hello world" returns <hello world"> with the double-quotes at the end...
    #    grep -Po 'path="\K(.+?)"' "$mod_descriptor_filename"
    #
    #    echo "GREP CUTTED"
    #    grep -Po 'path=".+?"' "$mod_descriptor_filename" | tr -d '"' | cut -c6-
    #    grep -Po 'path=".+?"' "$mod_descriptor_filename" | tr -d '"' | sed 's/^path=//'
    #
    #    echo "SED"
    #    sed -En 's/path=\"(.+?)\"/\1/p' "$mod_descriptor_filename"
    #
    #    echo "BASH GREP TRICK"
    #    source <(grep = "$mod_descriptor_filename")
    #    echo "$path"
    
    # see double-quotes -- must for any filenames - may contain spaces or expanse(*)
    # see (--) -- tells the command to finish parameters processing,
    # may arise rare error if a file name starts with (-) character
    parent_folder_name="$(basename -- "$(dirname -- "$mod_descriptor_filename")")"
    
    parent_folder_absolute_path="$(readlink -f -- "$(dirname -- "$mod_descriptor_filename")")"
    
    echo "$parent_folder_name"
    echo "$parent_folder_absolute_path"
    
    windows_drive_letter=$( echo "$parent_folder_absolute_path" | cut -c2  )
    
    windows_parent_folder_absolute_path=$( echo "$parent_folder_absolute_path" | sed "s/^../${windows_drive_letter}:/"  )
    
    echo "$parent_folder_name"
    echo "$windows_parent_folder_absolute_path"
    
    # 1
    sed -i '/^path="/d' "$mod_descriptor_filename"
    
    # 2
    sed -i '/^archive="/d' "$mod_descriptor_filename"
    
    # 3
    echo -e "\npath=\"$windows_parent_folder_absolute_path\"" >> "$mod_descriptor_filename"
    
    # 4
    sed -i '/^ *$/d' $mod_descriptor_filename
    
    # 5
    cp -- "$mod_descriptor_filename" "${MOD_FOLDER}/${parent_folder_name}.mod"
    
done

