*********************************************************************
* Projeto hbNFe (Nota Fiscal Eletronica/Danfe) para [x]Harbour      *
* hbNFe é um projeto para uso Livre, toda e qualquer alteração deve *
* ser remetida ao Administrador Fernando Athayde, qualquer          *
* modificação no código viola o direito de uso dos códigos fontes   *
*********************************************************************

30/08/2011
1a revisão

05/09/2011
versao 1.0 rc3 ultimo release antes da versao estavel

site de apoio a validação e assinatura
http://www.sefaz.rs.gov.br/NFE/NFE-VAL.aspx


    Quando podemos emitir a CC-e?

    A CC-e pode ser emitida para "corrigir" alguns erros de preenchimento da Nota Fiscal eletrônica.

    O que pode ser corrigido com a CC-e?

    O Ajuste SINIEF 01/07 veda a correção das seguintes informações relacionadas com o Fato Gerador do ICMS da NF-e: I - as variáveis que determinam o valor do imposto tais como: base de cálculo, alíquota, diferença de preço, quantidade, valor da operação ou da prestação;
    II - a correção de dados cadastrais que implique mudança do remetente ou do destinatário;
    III - a data de emissão ou de saída.

    O que devo fazer se precisar alterar a base de cálculo, alíquota, diferença de preço, quantidade, valor da operação ou da prestação?
        para aumentar o valor do ICMS ou da operação - o procedimento correto é a emissão da NF-e de complemento do ICMS ou da NF-e de complemento de Valor;
        para reduzir o valor do ICMS - se o valor do ICMS foi destacado a maior não existe uma forma padrão de saneamento do problema, depende da UF. A única regra padrão é que o destinatário não pode fazer o crédito de ICMS maior que o devido na operação, mesmo que o emitente tenha destacado um valor maior;
        para reduzir o valor da operação - o procedimento mais adequado seria o destinatário recusar o recebimento da mercadoria ou fazer a devolução da mercadoria para anular a operação e receber a NF-e com o valor correto.

    O que devo fazer para corrigir os dados cadastrais que implique mudança do remetente ou do destinatário?

    Não existe regra objetiva que define quais são as alterações de dados cadastrais que implicam na mudança do remetene ou do destinatário, assim o emissor e o destinatário terão menos dor de cabeça se não tentarem corrigir qualquer informação relacionado com os dados cadastrais do remetente ou do destinatário, para minizar o problema recomendamos as seguintes ações:
        O emissor deve tentar obter os dados cadastrais do remetente ou do destinatário através do Portal da SEFAZ, muitas SEFAZ já oferecem a consulta cadastro que permite obter os dados cadastrais do contribuintes do ICMS.
        O destinatário deve recusar o recebimento de mercadorias acobertadas com NF-e que não tenham os dados do destinatário corretos.

    O que devo fazer se precisar alterar a data de emissão ou a data de saída?

    Em algumas situações é possível que a mercadoria fique à disposição para retirada do transportador, mas a retirada ocorra com atraso. O procedimento mais adequado nesta situação é a substituição da NF-e com a emissão de uma nova NF-e com a data de emissão e/ou data de saída correta.

    Como minimizar a ocorrência de problemas

    Consulta Cadastro - tente utilizar a consulta cadastro que a SEFAZ oferece para obter os dados cadastrais do destinatário; envio/disponibilização da NF-e - envie ou disponbilize a NF-e para o destinatário com antecedência para que o destinatário possa conferir as informações;

    É possível emitir a CC-e para acompanhar o trânsito de uma mercadoria?

    Não existe impedimento para emitir uma CC-e para corrigir uma NF-e de mercadoria qua ainda não deu saída da empresa, contudo o procedimento mais adequado nesta situação é o cancelamento da NF-e incorreta e a emissão de uma NF-e com os dados corretos.

    Existe algum modelo ou leiaute para imprimir a CC-e?

    Não existe modelo ou leiaute de impressão da CC-e, assim como inexiste o modelo de impresso para a carta de correção em papel. Entendemos que a carta de correção é uma correspondência do emissor emitida para o remetente/destinatário para informar o erro de preenchimento da NF-e e pode ser impressa no padrão que o emissor julgar conveniente.

    O que devo informar na CC-e?
        chave de acesso da NF-e objeto da correção;
        data da correção;
        sequencial da correção (1 a 20), a última correção deve substituir a correção anterior;
        texto da correção, texto livre com tamanho limitado a 1000 caracteres;

    Como deve ser informado o texto da correção?

    O texto da correção é um texto livre com tamanho limitado a 1000 caracteres e inexiste modelo ou padrão do texto, assim o emissor deve descrever de forma clara e objetiva a correção que deve ser considerada.

    Já tenho uma carta de correção registrada e preciso fazer uma nova carta de correção, como devo agir?

    A carta de correção com data mais recente substitui as cartas de correções existentes, assim a nova carta de correção deve consolidar todas as correções.

    Emiti uma carta de correção com dados incorretos, como devo agir?

    A carta de correção com data mais recente substitui as cartas de correções existentes, assim basta emitir uma carta de correção com os dados corretos.

    Emiti uma carta de correção para uma NF-e incorreta, como devo agir?

    Não existe cancelamento de carta de correção, assim o procedimento mais adequado para esta situação seria a emissão de uma nova carta de correção que não tenha a correção indevida.

    O que devo fazer com a carta de correção emitida?

    O XML da carta de correção e a resposta de registro da carta de correção deve ser mantida em arquivo pelo emissor, além de ser envida para o destinatário.

    A carta de correção deve ser enviada para o destinatário?

    Sim, o XML da carta de correção e a resposta de registro da carta de correção deve ser envida para o destinatário.
