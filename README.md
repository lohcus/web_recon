Simples WebRecon, ainda em construção.

Uso: ./web_recon_options.sh <opcoes>
Opcoes:
	-u url				URL base a ser pesquisada
	-w wordlist			Wordlist utilizada na pesquisa
	-x extensao			Pesquisa por extensao [opcional]
	-d profundidade			Profundidade da pesquisa (min=1) [opcional]

Exemplo: ./web_recon.sh -w lista.txt -u localhost -a Mozila -x php,html,aspx -d 5
