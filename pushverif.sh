#!/bin/bash

verbose=0
checkMain=1
silent=0
while getopts "vuphirs" opt; do
	case $opt in
		v)
			verbose=1
			;;
		u)
			upd=$(cd $(dirname $(realpath -P $0)) ; git pull -ff)
			echo -e "\033[1;32m OK \033[0m: Script is up to date :)"
			exit
			;;
		p)
			echo -e "\033[1;32m OK \033[0m: repo link copied to clipboard :)"
			echo -n "https://github.com/etyloppihacilem/pushverif.git" | xclip -sel clip
			echo -e " Use it with 
	\033[36mgit clone https://github.com/etyloppihacilem/pushverif.git\033[0m"
			exit
			;;
		r)
			x-www-browser https://github.com/etyloppihacilem/pushverif
			exit
			;;
		h)
			cat $(dirname $(realpath -P $0))/README.md
			exit
			;;
		i)
			checkMain=0
			;;
		s)
			silent=1
			;;
	esac
done

if ! [ silent ]; then
	echo -e "\033[1;34m####################################################################
# This script was written by\033[1;37m hmelica \033[1;34mto test your code :)          #
# Use the\033[0;37m -v \033[1;34mflag to enable verbose and see used commands.         #
# Happy coding !                                                   #
#                                                                  #
# If you like the script, use the\033[0;37m -r \033[1;34mflag to give the repo a star  #
# on github !                                                      #
#                                                                  #
# If you do not want to check for \033[0;37mmain()\033[1;34m in your files, use the    #
# the\033[0;37m -i \033[1;34mflag to ignore.                                           #
#                                                                  #
# Do not hesitate to share this repository, but remember using the #
# github link to enable auto-updates.                              #
#                                                                  #
# TIP: to quickly share the script, use the\033[0;37m -p \033[1;34mflag :)             #
####################################################################\033[0m\n"

	majRepo=$(cd $(dirname $(realpath $0)) ; git remote update 2>&1 | grep -o -e "" ; git status -bs | grep -e "#" | grep -o -e ".[0-9]")
	if [[ $majRepo ]]; then
		echo -e "\033[1;33m WARN \033[0m: New update avaliable ! Run with the flag\033[0;37m -u \033[0mto update :)"
	else
		echo -e "\033[1;32m OK \033[0m: Script is up to date :)"
	fi

	if [ $verbose -eq 1 ] ; then
		echo -e "\033[34m git status -s \033[0m"
	fi
fi

statusLines=$(git status -s | wc -l)
if [ $statusLines -eq 0 ] ; then
	echo -e "\033[1;32m OK \033[0m: All files commited :
\033[32m$(git ls-files | sed "s/^/\t/")\033[0m"
else
	echo -e "\033[1;33m WARN \033[0m: Some files are uncommited : 
\033[35m$(git status -s | sed "s/^/\t/")\033[0m"
fi
echo -e ""

if [ $verbose -eq 1 ] ; then
	echo -e "\033[34m git status -bs \033[0m"
fi
modifications=$(git remote update 2>&1 | grep -o -e "" ; git status -bs | grep "#" | grep --color=always -o -e ".[0-9]*\[.*\]")
if [[ $modifications ]] ; then
	echo -e "\033[1;31m ERROR \033[0m: Repo is not up to date, 
	$(git status -bs | grep "#")
	try \033[36mgit pull ; git push\033[0m"
else 
	echo -e "\033[1;32m OK \033[0m: Repo is up to date with origin"
fi

if [ $verbose -eq 1 ] ; then
	echo -e "\033[34m git ls-files \033[0m"
fi
trackedFiles=$(git ls-files)
pbInFiles=0
for file in $trackedFiles; do
	if [ $checkMain -eq 1 ]; then
		inFile=$(cat $file | sed -e "/\/\*/,/\*\//d" | grep -n -e "main.*(.*)" -e "printf.*(.*)")
	else
		inFile=$(cat $file | sed -e "/\/\*/,/\*\//d" | grep -n -e "printf.*(.*)")
	fi
	if [[ $inFile ]]; then
		toPrint=""
		if [ $pbInFiles -eq 0 ]; then
			toPrint="\033[1;33m WARN \033[0m: forbidden function(s) detected in file(s)"
			pbInFiles=1
		fi
		echo -e "$toPrint"
		if [ $checkMain -eq 1 ]; then
			echo -e "\t\033[36m$file\033[0m
$(cat $file | sed -e 's/\/\/.*//' -r -e '/\/\*/,/\*\//d' | grep --color=always -n -e "main.*(.*)" -e "printf.*(.*)" | sed "s/^/\t/")"
		else
			echo -e "\t\033[36m$file\033[0m
$(cat $file | sed -e 's/\/\/.*//' -r -e '/\/\*/,/\*\//d' | grep --color=always -n -e "printf.*(.*)" | sed "s/^/\t/")"
		fi
	fi
done
if [ $pbInFiles -eq 0 ]; then
	echo -e "\033[1;32m OK \033[0m: No forbidden fonction in tracked files"
else
	echo -e ""
fi
if [ $verbose -eq 1 ] ; then
	echo -e "\033[34m norminette -R CheckForbiddenSourceHeader \033[0m"
fi
trackedFiles=$(git ls-files | grep -e ".*\.c" -e ".*\.h")
norminette=$($(echo "norminette -R CheckForbiddenSourceHeader $trackedFiles" | sed "s/'//"))
if [[ $(echo $norminette | grep -i "error") ]]; then
	echo -e "\033[1;31m ERROR \033[0m: Norm error(s) on tracked file(s)"
	echo -e "$($(echo "norminette -R CheckForbiddenSourceHeader $trackedFiles" | sed "s/'//") | grep --color=always -i "error" | sed "s/^/\t/") \n" 
else 
	echo -e "\033[1;32m OK \033[0m: Norm ok for all tracked files"
fi

if [ $verbose -eq 1 ] ; then
	echo -e "\033[34m gcc -c -Wall -Werror -Wextra -o /tmp/DoNotOpen_$USER.out\033[0m"
fi
echo -e "";
pbInFiles=0
trackedFiles=$(git ls-files | grep -e ".*\.c")
for file in $trackedFiles; do
	compil=$(gcc -fdiagnostics-color=always -c -Wall -Werror -Wextra -o /tmp/DoNotOpen_$USER.out $file 2>&1)
	if [[ $compil ]]; then
		pbInFiles=1
		echo -e "\t\033[1;31m ERROR \033[0m: $file does not compile :"
		echo -e "$(gcc -fdiagnostics-color=always -c -Wall -Werror -Wextra -o /tmp/DoNotOpen_$USER.out $file 2>&1 | sed "s/^/\t/")\n"
	else
		echo -e "\t\033[1;32m OK \033[0m: $file does compile"
	fi
done
if [ $pbInFiles -eq 0 ]; then
		echo -e "\033[1;32m OK \033[0m: All tracked files do compile"
fi
