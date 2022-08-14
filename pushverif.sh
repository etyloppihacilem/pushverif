#!/bin/bash

echo -e "\033[1;34;40m####################################################################
# Ce script vous est proposé par\033[1;37;40m hmelica \033[1;34;40mpour tester votre code :) #
# Utilisez le flag\033[0;37;40m -v \033[1;34;40mpour afficher les commandes utilisées.       #
# Bon code !                                                       #
# N'hesitez pas à partager ce repository, mais il est important    #
# de bien le cloner pour pouvoir bénéficier des mises à jour       #
# automatiques !                                                   #
# TIP: pour le partager rapidement, essayez le flag\033[0;37;40m -p \033[1;34;40m            #
####################################################################\033[0m\n"

verbose=0
while getopts "vup" opt; do
	case $opt in
		v)
			verbose=1
			;;
		u)
			upd=$(cd $(dirname $(realpath -P $0)) ; git pull -ff)
			echo -e "\033[1;32;40m OK \033[0m: Script is up to date :)"
			exit
			;;
		p)
			echo -e "\033[1;32;40m OK \033[0m: repo link copied to clipboard :)"
			echo -n "https://github.com/etyloppihacilem/pushverif.git" | xclip -sel clip
			echo -e " Use it with 
	\033[36;40mgit clone https://github.com/etyloppihacilem/pushverif.git\033[0m"
			exit
			;;
			
	esac
done

majRepo=$(cd $(dirname $(realpath $0)) ; git remote update 2>&1 | grep -o -e "" ; git status -bs | grep -e "#" | grep -o -e ".[0-9]")
if [[ $majRepo ]]; then
	echo -e "\033[1;33;40m WARN \033[0m: New update avaliable ! Run with the flag\033[0;37;40m -u \033[0mto update :\)"
else
	echo -e "\033[1;32;40m OK \033[0m: Script is up to date :)"
fi

if [ $verbose -eq 1 ] ; then
	echo -e "\033[34;40m git status -s \033[0m"
fi

statusLines=$(git status -s | wc -l)
if [ $statusLines -eq 0 ] ; then
	echo -e "\033[1;32;40m OK \033[0m: All files commited :
\033[32;40m$(git ls-files | sed "s/^/\t/")\033[0m"
else
	echo -e "\033[1;31;40m ERROR \033[0m: Some files are uncommited : 
\033[35;40m$(git status -s | sed "s/^/\t/")\033[0m"
fi
echo -e ""

if [ $verbose -eq 1 ] ; then
	echo -e "\033[34;40m git status -bs \033[0m"
fi
modifications=$(git status -bs | grep "#" | grep --color=always -o -e ".[0-9]*\[.*\]")
if [[ $modifications ]] ; then
	echo -e "\033[1;31;40m ERROR \033[0m: Repo is not up to date, 
	$(git status -bs | grep "#")
	try \033[36;40mgit pull ; git push\033[0m"
else 
	echo -e "\033[1;32;40m OK \033[0m: Repo is up to date with origin"
fi

if [ $verbose -eq 1 ] ; then
	echo -e "\033[34;40m git ls-files \033[0m"
fi
trackedFiles=$(git ls-files)
pbInFiles=0
for file in $trackedFiles; do
	inFile=$(cat $file | sed -r ':a; s%(.*)/\*.*\*/%\1%; ta; /\/\*/ !b; N; ba' | grep -n -e "main(.*)")
	if [[ $inFile ]]; then
		toPrint=""
		if [ $pbInFiles -eq 0 ]; then
			toPrint="\033[1;33;40m WARN \033[0m: main detected in file(s)"
			pbInFiles=1
		fi
		echo -e "
$toPrint
	\033[36;40m$file\033[0m
	$(cat $file | grep --color=always -n -e "main(.*)")"
	fi
done
if [ $pbInFiles -eq 0 ]; then
	echo -e "\033[1;32;40m OK \033[0m: No main in tracked files"
else
	echo -e ""
fi
if [ $verbose -eq 1 ] ; then
	echo -e "\033[34;40m norminette -R CheckForbiddenSourceHeader \033[0m"
fi
norminette=$(norminette -R CheckForbiddenSourceHeader)
if [[ $(echo $norminette | grep -i "error") ]]; then
	echo -e "\033[1;31;40m ERROR \033[0m: Norm error(s)"
	echo -e "$(norminette -R CheckForbiddenSourceHeader | grep --color=always -i "error" | sed "s/^/\t/") \n" 
else 
	echo -e "\033[1;32;40m OK \033[0m: Norm ok for all tracked files"
fi

if [ $verbose -eq 1 ] ; then
	echo -e "\033[34;40m gcc -fsyntax-only -Wall -Werror -Wextra \033[0m"
fi
echo -e "";
pbInFiles=0
trackedFiles=$(git ls-files | grep -e ".*\.c")
for file in $trackedFiles; do
	compil=$(gcc -fdiagnostics-color=always -fsyntax-only -Wall -Werror -Wextra $file 2>&1)
	if [[ $compil ]]; then
		pbInFiles=1
		echo -e "\t\033[1;31;40m ERROR \033[0m: $file does not compile :"
		echo -e "$(gcc -fdiagnostics-color=always -fsyntax-only -Wall -Werror -Wextra $file 2>&1 | sed "s/^/\t/")\n"
	else
		echo -e "\t\033[1;32;40m OK \033[0m: $file does compile"
	fi
done
if [ $pbInFiles -eq 0 ]; then
		echo -e "\033[1;32;40m OK \033[0m: All tracked files do compile"
fi
