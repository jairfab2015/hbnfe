*********************************************************************
* Projeto hbNFe (Nota Fiscal Eletronica/Danfe) para [x]Harbour      *
* hbNFe � um projeto para uso Livre, toda e qualquer altera��o deve *
* ser remetida ao Administrador Fernando Athayde, qualquer          *
* modifica��o no c�digo viola o direito de uso dos c�digos fontes   *
*********************************************************************

30/08/2011
1a revis�o

05/09/2011
versao 1.0 rc3 ultimo release antes da versao estavel

site de apoio a valida��o e assinatura
http://www.sefaz.rs.gov.br/NFE/NFE-VAL.aspx


    Quando podemos emitir a CC-e?

    A CC-e pode ser emitida para "corrigir" alguns erros de preenchimento da Nota Fiscal eletr�nica.

    O que pode ser corrigido com a CC-e?

    O Ajuste SINIEF 01/07 veda a corre��o das seguintes informa��es relacionadas com o Fato Gerador do ICMS da NF-e: I - as vari�veis que determinam o valor do imposto tais como: base de c�lculo, al�quota, diferen�a de pre�o, quantidade, valor da opera��o ou da presta��o;
    II - a corre��o de dados cadastrais que implique mudan�a do remetente ou do destinat�rio;
    III - a data de emiss�o ou de sa�da.

    O que devo fazer se precisar alterar a base de c�lculo, al�quota, diferen�a de pre�o, quantidade, valor da opera��o ou da presta��o?
        para aumentar o valor do ICMS ou da opera��o - o procedimento correto � a emiss�o da NF-e de complemento do ICMS ou da NF-e de complemento de Valor;
        para reduzir o valor do ICMS - se o valor do ICMS foi destacado a maior n�o existe uma forma padr�o de saneamento do problema, depende da UF. A �nica regra padr�o � que o destinat�rio n�o pode fazer o cr�dito de ICMS maior que o devido na opera��o, mesmo que o emitente tenha destacado um valor maior;
        para reduzir o valor da opera��o - o procedimento mais adequado seria o destinat�rio recusar o recebimento da mercadoria ou fazer a devolu��o da mercadoria para anular a opera��o e receber a NF-e com o valor correto.

    O que devo fazer para corrigir os dados cadastrais que implique mudan�a do remetente ou do destinat�rio?

    N�o existe regra objetiva que define quais s�o as altera��es de dados cadastrais que implicam na mudan�a do remetene ou do destinat�rio, assim o emissor e o destinat�rio ter�o menos dor de cabe�a se n�o tentarem corrigir qualquer informa��o relacionado com os dados cadastrais do remetente ou do destinat�rio, para minizar o problema recomendamos as seguintes a��es:
        O emissor deve tentar obter os dados cadastrais do remetente ou do destinat�rio atrav�s do Portal da SEFAZ, muitas SEFAZ j� oferecem a consulta cadastro que permite obter os dados cadastrais do contribuintes do ICMS.
        O destinat�rio deve recusar o recebimento de mercadorias acobertadas com NF-e que n�o tenham os dados do destinat�rio corretos.

    O que devo fazer se precisar alterar a data de emiss�o ou a data de sa�da?

    Em algumas situa��es � poss�vel que a mercadoria fique � disposi��o para retirada do transportador, mas a retirada ocorra com atraso. O procedimento mais adequado nesta situa��o � a substitui��o da NF-e com a emiss�o de uma nova NF-e com a data de emiss�o e/ou data de sa�da correta.

    Como minimizar a ocorr�ncia de problemas

    Consulta Cadastro - tente utilizar a consulta cadastro que a SEFAZ oferece para obter os dados cadastrais do destinat�rio; envio/disponibiliza��o da NF-e - envie ou disponbilize a NF-e para o destinat�rio com anteced�ncia para que o destinat�rio possa conferir as informa��es;

    � poss�vel emitir a CC-e para acompanhar o tr�nsito de uma mercadoria?

    N�o existe impedimento para emitir uma CC-e para corrigir uma NF-e de mercadoria qua ainda n�o deu sa�da da empresa, contudo o procedimento mais adequado nesta situa��o � o cancelamento da NF-e incorreta e a emiss�o de uma NF-e com os dados corretos.

    Existe algum modelo ou leiaute para imprimir a CC-e?

    N�o existe modelo ou leiaute de impress�o da CC-e, assim como inexiste o modelo de impresso para a carta de corre��o em papel. Entendemos que a carta de corre��o � uma correspond�ncia do emissor emitida para o remetente/destinat�rio para informar o erro de preenchimento da NF-e e pode ser impressa no padr�o que o emissor julgar conveniente.

    O que devo informar na CC-e?
        chave de acesso da NF-e objeto da corre��o;
        data da corre��o;
        sequencial da corre��o (1 a 20), a �ltima corre��o deve substituir a corre��o anterior;
        texto da corre��o, texto livre com tamanho limitado a 1000 caracteres;

    Como deve ser informado o texto da corre��o?

    O texto da corre��o � um texto livre com tamanho limitado a 1000 caracteres e inexiste modelo ou padr�o do texto, assim o emissor deve descrever de forma clara e objetiva a corre��o que deve ser considerada.

    J� tenho uma carta de corre��o registrada e preciso fazer uma nova carta de corre��o, como devo agir?

    A carta de corre��o com data mais recente substitui as cartas de corre��es existentes, assim a nova carta de corre��o deve consolidar todas as corre��es.

    Emiti uma carta de corre��o com dados incorretos, como devo agir?

    A carta de corre��o com data mais recente substitui as cartas de corre��es existentes, assim basta emitir uma carta de corre��o com os dados corretos.

    Emiti uma carta de corre��o para uma NF-e incorreta, como devo agir?

    N�o existe cancelamento de carta de corre��o, assim o procedimento mais adequado para esta situa��o seria a emiss�o de uma nova carta de corre��o que n�o tenha a corre��o indevida.

    O que devo fazer com a carta de corre��o emitida?

    O XML da carta de corre��o e a resposta de registro da carta de corre��o deve ser mantida em arquivo pelo emissor, al�m de ser envida para o destinat�rio.

    A carta de corre��o deve ser enviada para o destinat�rio?

    Sim, o XML da carta de corre��o e a resposta de registro da carta de corre��o deve ser envida para o destinat�rio.
