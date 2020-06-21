#!/bin/bash

#Criado por Daniel Domingues
#https://github.com/lohcus

array_diretorios=("")
colunas=$(tput cols) # VERIFICA O TAMANHO DA JANELA PARA PODER DESENHAR O LAYOUT

divisao () {
	printf "\r\033[35;1m=\033[m"
	# LACO PARA PREENCHER UMA LINHA COM "="
	for i in $(seq 0 1 $(($colunas-2)))
	do
		printf "\033[35;1m=\033[m"
	done
	echo
}

diretorios () { #PROCURA POR DIRETORIOS
	resposta=$(curl -s -H 'User-Agent: DesecTool' -o /dev/null -w '%{http_code}' $1/$2/)
	if [ $resposta == "200" ]
	then
		printf "\r\033[32;1m$4[+] Diretorio encontrado:\033[36;1m $1/$2\n\033[m"
		# CADA DIRETORIO EXISTENTE EH ADICIONADO A UM ARRAY PARA POSTERIOR PESQUISA DE ARQUIVOS NO MESMO
		array_diretorios[$((${#array_diretorios[*]}+1))]="$2"
	fi
}

arquivos () { # PROCURA POR ARQUIVOS
	# PESQUISA PELOS NOMES DA WORDLIST SEM EXTENSAO
#	echo -n "curl -s -H 'User-Agent: DesecTool' -o /dev/null -w '%{http_code}' $1/$2"
	resposta=$(curl -s -H 'User-Agent: DesecTool' -o /dev/null -w '%{http_code}' $1/$2)
#	echo " - $resposta"
	if [ $resposta == "200" ]
	then
		printf "\r\033[33;1m$4|- Arquivo encontrado:\033[37;1m $1/$2\n\033[m"
	fi
	# PESQUISA PELOS NOMES DA WORDLIST COM EXTENSAO
#	echo -n "curl -s -H 'User-Agent: DesecTool' -o /dev/null -w '%{http_code}' $1/$2.$3"
	resposta=$(curl -s -H 'User-Agent: DesecTool' -o /dev/null -w '%{http_code}' $1/$2.$3)
#	echo " - $resposta"
	if [ $resposta == "200" ]
	then
		printf "\r\033[33;1m$4|- Arquivo $3 encontrado:\033[37;1m $1/$2.$3\n\033[m"
	fi
}

clear

#QUANTIDADE DE NOMES NA WORDLIST
nomes=$(wc -l $2 | cut -d " " -f 1)

#CHAMA A FUNCAO PARA DESENHAR UMA DIVISORIA
divisao
echo

centro_coluna=$(( $(( $(( $colunas-16))/2 )))) #CALCULO PARA CENTRALLIZAR O TITULO
tput cup 0 $centro_coluna #POSICIONAR O CURSOR
printf "\033[37;1mLOHCUS WEB RECON\n\033[m"

if [ ! -z $2 ] # VERIFICA SE FORAM DIGITADOS PELO MENOS 2 ARGUMENTOS
then
	if [ ! -f $2 ] # VERIFICA SE A WORDLIST EXISTE
	then
		printf "\033[31;1m[-] Verifique se a wordlist realmente existe!\n\033[m"
		printf "\033[37;1m[-] Uso: $0 url wordlist [extensao]\n\033[m"
		divisao
		echo
		exit 1
	fi

	url=$(curl -s -H 'User-Agent: DesecTool' -I $1/$palavra)

	if [ "$url" == "" ] # VERIFICA SE A URL NAO EXISTE OU NAO ESTA RESPONDENDO
	then
		printf "\033[31;1m[-] Verifique a URL digitada!\n\033[m"
		printf "\033[37;1m[-] Uso: $0 url wordlist [extensao]\n\033[m"
		divisao
		echo
		exit 1
	fi
	# BUSCA INFORMACOES PARA OBTER O SERVER E A TECNOLOGIA UTILIZADA NAS PAGINAS
	server=$(echo "$url" | grep -E "Server:" | cut -d ":" -f 2)
	tecnologia=$(echo "$url" | grep -E "X-Powered-By" | cut -d ":" -f 2)
	printf "\033[32;1m[+] WebServer identificado:\033[36;1m$server\n\033[m"
	if [[ $tecnologia != "" ]]
	then
		printf "\033[32;1m[+] Tecnologias:\033[36;1m$tecnologia\n\033[m"
	fi

	divisao
	printf "\033[37;1m[+] Buscando por Diretorios\n\033[m"
	divisao

	# BUSCA POR DIRETORIOS
	cont=1
	for diretorio in $(cat $2)
	do
		# CONTADOR DE NOMES
		printf "\r \033[31;1m$cont de $nomes nomes\033[m"

		diretorios $1 $diretorio $3 ""

		cont=$(($cont+1))
		
	done

	divisao

	# SE FOR DIGITADO O TERCEIRO PARAMETRO (EXTENSAO) PESQUISA POR ARQUIVOS NA RAIZ E EM CADA DIRETORIO ENCONTRADO, UTILIZANDO A MESMA WORDLIST
	if [ ! -z $3 ]
	then
	for elemento in "${array_diretorios[@]}"
	do
		printf "\033[37;1m[+] Buscando por Arquivos em \033[36;1m$1/$elemento\n\033[m"
		cont=1
		for arquivo in $(cat $2)
		do
			# CONTADOR DE NOMES
			printf "\r \033[31;1m$cont de $nomes nomes\033[m"
			
			if [ -z "$elemento" ]
			then
				arquivos "$1" $arquivo $3 " "
			else
				arquivos "$1/$elemento" $arquivo $3 " "
			fi
			
			cont=$(($cont+1))
		done
		divisao
	done
	fi
else
	printf "\033[37;1m[-] Uso: $0 url wordlist [extensao]\n\033[m"
	divisao
fi
echo
