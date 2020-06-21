#!/bin/bash

#Criado por Daniel Domingues
#https://github.com/lohcus

array_diretorios=("")
colunas=$(tput cols) # VERIFICA O TAMANHO DA JANELA PARA PODER DESENHAR O LAYOUT
#=================================================================================================================

function uso() {
	divisao
	printf "\033[37;1mLohcus Web Recon\n\033[m"
	printf "\033[37;1mUso: $0 <opcoes>\n\033[m"
	printf "\033[37;1mOpcoes:\n\033[m"
	printf "\033[37;1m	-u url				URL base a ser pesquisada\n\033[m"
	printf "\033[37;1m	-w wordlist			Wordlist utilizada na pesquisa\n\033[m"
	printf "\033[37;1m	-x extensao			Pesquisa por extensao [opcional]\n\033[m"
	printf "\033[37;1m	-d profundidade			Profundidade da pesquisa (min=1) [opcional]\n\033[m"
	divisao
	exit 1
}
#=================================================================================================================

divisao () {
	printf "\r\033[35;1m=\033[m"
	# LACO PARA PREENCHER UMA LINHA COM "="
	for i in $(seq 0 1 $(($colunas-2)))
	do
		printf "\033[35;1m=\033[m"
	done
	echo
}
#=================================================================================================================

diretorios () { #PROCURA POR DIRETORIOS
#	echo "curl -s -H 'User-Agent: DesecTool' -o /dev/null -w '%{http_code}' $1/$2/"
	resposta=$(curl -s -H 'User-Agent: DesecTool' -o /dev/null -w '%{http_code}' $1/$2/)
#	echo " - $resposta"
	if [ $resposta == "200" ]
	then
		printf "\r\033[32;1m$3[+] Diretorio encontrado:\033[36;1m $1/$2\n\033[m"
		
		# CADA DIRETORIO EXISTENTE EH ADICIONADO A UM ARRAY PARA POSTERIOR PESQUISA DE ARQUIVOS NO MESMO
		array_diretorios[$((${#array_diretorios[*]}+1))]=$(echo "$1/$2" | cut -d "/" -f 2-)
		
		# IDENTACAO DOS DIRETORIOS
		espaco=$3
		espaco=$(echo "$espaco-")

		if [ $contador -lt $deep ] 
		then
			contador=$((contador+1))
			for diretorio in $(cat $wordlist)
			do	
				diretorios "$1/$2" $diretorio $espaco
			done		
		fi
	fi
}
#=================================================================================================================

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
#=================================================================================================================

clear

#CHAMA A FUNCAO PARA DESENHAR UMA DIVISORIA
divisao
echo

centro_coluna=$(( $(( $(( $colunas-16))/2 )))) #CALCULO PARA CENTRALLIZAR O TITULO
tput cup 0 $centro_coluna #POSICIONAR O CURSOR
printf "\033[37;1mLOHCUS WEB RECON\n\033[m"

deep=9999
while getopts "hu:w:x:d:" OPTION
do
	case $OPTION in
    	"h") uso
        	;;
      	"u") url=$OPTARG
         	;;
      	"w") wordlist=$OPTARG
	  		# QUANTIDADE DE NOMES NA WORDLIST
			nomes=$(wc -l $wordlist | cut -d " " -f 1)
         	;;
      	"x") extensao=$OPTARG
        	;;
      	"d") deep=$OPTARG
        	;;
      	"?") uso
        	;;
   esac
done
shift $((OPTIND-1))

[ -z "$url" -o -z "$wordlist" ] && uso

numeric='^[0-9]+$'
if ! [[ $deep =~ $numeric ]] ; then
   	printf "\033[31;1m[-] A profundidade deve ser numeria maior que 0!\n\033[m"
   	uso
fi

# VERIFICA SE A WORDLIST EXISTE
if [ ! -f "$wordlist" ]
then
	printf "\033[31;1m[-] Verifique a WORDLIST digitada!\n\033[m"
	uso
fi

# VERIFICA SE A URL NAO EXISTE OU NAO ESTA RESPONDENDO
status=$(curl -s -H 'User-Agent: DesecTool' -I $url)
if [ "$status" == "" ]
then
	printf "\033[31;1m[-] Verifique a URL digitada!\n\033[m"
	uso
fi

# BUSCA INFORMACOES PARA OBTER O SERVER E A TECNOLOGIA UTILIZADA NAS PAGINAS
server=$(echo "$status" | grep -E "Server:" | cut -d ":" -f 2)
tecnologia=$(echo "$status" | grep -E "X-Powered-By" | cut -d ":" -f 2)
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
for diretorio in $(cat $wordlist)
do
	contador=1
	# CONTADOR DE NOMES
	printf "\r \033[31;1m$cont de $nomes nomes\033[m"

	diretorios $url $diretorio ""

	cont=$(($cont+1))
	
done

divisao

#echo ${array_diretorios[*]}

# SE FOR DIGITADO O TERCEIRO PARAMETRO (EXTENSAO) PESQUISA POR ARQUIVOS NA RAIZ E EM CADA DIRETORIO ENCONTRADO, UTILIZANDO A MESMA WORDLIST
if [ ! -z $extensao ]
then
for elemento in "${array_diretorios[@]}"
do
	printf "\033[37;1m[+] Buscando por Arquivos em \033[36;1m$1/$elemento\n\033[m"
	cont=1
	for arquivo in $(cat $wordlist)
	do
		# CONTADOR DE NOMES
		printf "\r \033[31;1m$cont de $nomes nomes\033[m"
		
		if [ -z "$elemento" ]
		then
			arquivos "$url" $arquivo $extensao " "
		else
			arquivos "$url/$elemento" $arquivo $extensao " "
		fi
		
		cont=$(($cont+1))
	done
	divisao
done
fi
echo
