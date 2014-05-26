/*
   Classe para integração da CT-e com  xHarbour | HWgui | PostgreSQL
   Mauricio Cruz - 15/07/2013
   - cruz@sygecom.com.br
   - www.sygecom.com.br
   
Pl/SQL: 
   -- Esta PL foi criada por que tinhamos um problema em fazer uma inserção com um returning usando a SQLRDD
   -- Ira fazer um insert e retornar o parametro informado
   create or replace function adiciona(cTabela text, cCampos text, cValores text, cRetornar text) RETURNS text AS $$ 
   declare    
      nRet Int; 
   begin    
      execute 'insert into '||cTabela||'('||cCampos||') 
                values ('||cValores||') 
                returning '||cRetornar into nRet;    
      return nRet::text; 
   end; $$ language plpgsql;

RESUMO DA OPERAÇÃO:
   Transmição de CT-e:
   - Criar a strutura XML
     ::oCTe_SEFAZ:ctXMLGeral(nCTE_ID)
   - Criar a strutura XML do modal
     ::oCTe_SEFAZ:ctXMLRodoviario(nCTE_ID)
   - Validar com o Schema o XML modal e anexar o XML modal ao XML principal
     ::oCTe_SEFAZ:ctValidaXML(cXML)
   - Assinar o XML da transmissão
     ::oCTe_SEFAZ:ctAssinaXML(cXML,cID,cURI)
   - Validar com o Schema o XML geral
     ::oCTe_SEFAZ:ctValidaXML(cXML)
   - Empacotar no SOAP ACTION
     ::oCTe_SEFAZ:ctSoapAction(cXML,cServ)
   - Enviar para o SEFAZ e receber seu retorno
     ::oCTe_SEFAZ:ctComunicaWebService(cXML,cSoap,cService)    
     - Trata a duplicidade
       ::oCTe_SEFAZ:ctConsultaProtocolo()
   - Ler a resposta do SEFAZ
     ::oCTe_SEFAZ:ctPegaRetornoSEFAZ(cXML)
   - Consultar o retorno da recepção da CT-e e Anexar o protocolo ao XML da CT-e
     ::oCTe_SEFAZ:ctRetornoRecepcao(cREC)   
   
   Cancelamento:
   ::ctCancela(oBrw)
    - Gera o arquivo XML
    - Assina
    - Valida com o Schema XML
    - Empacota no SOAP ACTION
    - Comunica com o SEFAZ
    - Le a Resposta
      -- Trata duplicidade
    - Anexa o protocolo
   
   Inutilização:
   ::ctInutiliza(oBrw)
    - Gera o XML
    - Assina
    - Valida com o Schemas XML
    - Empacota no SOAP ACTION   
    - Comunica com o SEFAZ
    - Le a Resposta
      -- Trata duplicidade
    - Anexa o protocolo
   

EXEMPLO DE CHAMADA DA CLASSE

   FUNCTION LISTA_CTE()
   LOCAL oUICTE:=oCTe_HWgui(), hIni
   LOCAL lERR:=.F.

   oUICTE:cCte_Filial:='MATRIZ'  (MATRIZ,FILIAL1,FILIAL2...)
   oUICTE:cCte_Operador := 'OPERADOR DO SISTEMA'
   oUICTE:cCte_Estado:='UF'
   oUICTE:cCte_Cidade:='CIDADE'
   oUICTE:versaoApp := '7.4397'  // VERSAO DO APLICATIVO EMISSOR
   oUICTE:cCte_CNPJ := 'CNPJ DO EMISSO'
   oUICTE:cCte_IE := 'IE DO EMISSO'
   oUICTE:cCte_RAZAO := 'RAZAO SOCIAL DO EMISSO'
   oUICTE:cCte_FANTASIA := 'NOME FANTASIA DO EMISSOR'
   oUICTE:cCte_ENDERECO := 'ENDERECO DO EMISSO'
   oUICTE:cCte_NUMERO := 'NUMERO DO ENDERECO DO EMISSO'
   oUICTE:cCte_BAIRRO := 'BAIRRO DO EMISSO'
   oUICTE:cCte_CEP := 'CEP DO EMISSOR'
   oUICTE:cCte_FONE := '(51)3333-3333'  // TELEFONE DO EMISSOR
   oUICTE:cPastaEnvRes := GETENV('temp') + '\hbnfe\'+ALLTRIM(STR(_RegEmpresa()))  // CAMINHO DA PASTA PARA GERAR OS XMLs
   oUICTE:cVersao_DADOS:='1.04'   // VERSAO DO DADOS DO SOAP ACTION
   oUICTE:cVersao_CTe:='1.04'  // VERSAO DO XML DA CTE
   oUICTE:cVersao_Modal_RODOVIARIO := '1.04'  // VERSAO DO MODAL RODOVIARIO
   oUICTE:lCte_ELETRONICO := .T.   // HABILITA OU NAO O USO DA CT ELETRONICA
   TRY
      IF oUICTE:lCte_ELETRONICO
         hIni:=HB_ReadIni( GETENV('temp')+'\hbnfe\'+ALLTRIM(STR(_RegEmpresa()))+'\hbnfe.ini' )   // ARQUIVO INI DE CONFIGURACAO DA CTE
         oUICTE:tpEmis := hIni['DACTE-Principais']['tpEmis']   // TIPO DE EMISSAO (NORMA,SCAN...)
         oUICTE:tpAmb := hIni['DACTE-Principais']['tpAmb']   // TIPO DE AMBIENTE (PRODUCAO, HOMOLOGACAO)
         oUICTE:cJustCont:= hIni['DACTE-Principais']['xJust']  // JUSTIFICATIVA DO MODO SCAN
         oUICTE:cPastaSchemas := hIni['Principais']['cPastaSchemas']  //CAMINHO DA PASTA SCHEMAS PARA VALIDACAO DOS XMLs
         oUICTE:cSerialCert := hIni['Certificado-'+ALLTRIM(_FILIAL())]['Serial']  // SERIAL DO CERTIFICADO
      ENDIF
   CATCH
      ?'Não foi possível carregar os dados da configuração da CT eletrônica.'
      lERR:=.T.
   END

   IF !lERR
      oUICTE:uiListaCte()
   ENDIF

   RETURN(.T.)


ESTRUTURA DAS TABELAS:
   TABELA: SAGI_CTE
   
   CAMPO                       TIPO  TAMANHO DECIMAL   UNICIDADE  CHAVE PRIMARIA  CHAVE ESTRANGEIRA  SERIAL  NOT NULL  SET DEFAULT   DESCRICAO
   --------------------------- ----- ------- --------- ---------- --------------- ------------------ ------- --------- ------------- -------------------------------------------
   CTE_ID                      N          10       0      .T.         .T.                             .T.       .T.       .T.        CODIGO DO CT-e
   EMPRESA                     C          10       0      .F.         .F.                             .F.       .T.       .T.        EMPRESA
   CTE_MODALIDADE              N          02       0      .F.         .F.                             .F.       .T.       .T.        USE:01-RODOV,02-AEREO,03-AQUAVIARIO,04-FERROV,05-DUTOVIARIO
   CTE_MODELO                  N          02       0      .F.         .F.                             .F.       .T.       .T.        MODELO DA DACT-e
   CTE_SERIE                   N          03       0      .F.         .F.                             .F.       .T.       .T.        SERIE DA DACT-e
   CTE_NUMERODACTE             N          10       0      .F.         .F.                             .F.       .T.       .T.        NUMERO DA DACT-e
   CTE_DATAEMISSAO             D          08       0      .F.         .F.                             .F.       .T.       .T.        DATA EMISSAO CT-e
   CTE_HORAEMISSAO             C          08       0      .F.         .F.                             .F.       .T.       .T.        HORA EMISSAO CT-e
   CTE_TIPO                    N          01       0      .F.         .F.                             .F.       .T.       .T.        USE:0-NORMAL,1-COMPLEMENTO,2-ANULACAO,3-SUBST
   CTE_TIPOSERVICO             N          01       0      .F.         .F.                             .F.       .T.       .T.        USE:0-NORMAL,1-SUBCONTRAT,2-REDESPACHO,3-REDESPACHO INTERM.
   CTE_TOMADORSERVICO          N          01       0      .F.         .F.                             .F.       .T.       .T.        USE:0-REMETENTE,1-EXPEDIDOR,2-RECEBEDOR,3-DESTINATARIO
   CTE_FORMAPAGAMENTO          N          01       0      .F.         .F.                             .F.       .T.       .T.        USE:0-PAGO,1-A PAGAR,2-OUTROS
   CFOP_ID                     N          10       0      .F.         .F.                             .F.       .T.       .T.        PREST_ID_CTE FK
   CTE_DATAAUTORIZACAO         D          08       0      .F.         .F.                             .F.       .T.       .T.        DATA AUTORIZACAO CT-e
   CTE_CHAVEACESSO             C          44       0      .F.         .F.                             .F.       .T.       .T.        CHAVE DE ACESSO DA CT-e
   CTE_PROTOCOLO               C          50       0      .F.         .F.                             .F.       .T.       .T.        PROTOCOLO DA CT-e
   CTE_RECIBO                  C          44       0      .F.         .F.                             .F.       .T.       .T.        RECIBO DA CT-e
   CTE_IBGEORIGEMPRESTACAO     N          10       0      .F.         .F.                             .F.       .T.       .T.        CTE_ORIGEMPRESTACAO FK
   CTE_IBGEDESTINOPRESTACAO    N          10       0      .F.         .F.                             .F.       .T.       .T.        CTE_DESTINOPRESTACAO FK
   REMETENTE_ID                N          10       0      .F.         .F.                             .F.       .T.       .T.        REMETENTE_ID FK
   DESTINATARIO_ID             N          10       0      .F.         .F.                             .F.       .T.       .T.        DESTINATARIO_ID FK
   EXPEDIDOR_ID'               N          10       0      .F.         .F.                             .F.       .T.       .T.        EXPEDIDOR ID
   RECEBEDOR_ID'               N          10       0      .F.         .F.                             .F.       .T.       .T.        RECEBEDOR ID
   SEGURADORA                  C          30       0      .F.         .F.                             .F.       .T.       .T.        SEGURADORA
   CTE_DESCRICAOPREDOMINANTE   C          40       0      .F.         .F.                             .F.       .T.       .T.        DESCRICAO DO PRODUTO PREDOMINANTE
   CTE_OUTRASCARACTER          C          40       0      .F.         .F.                             .F.       .T.       .T.        OUTRAS CARACTERISTICAS
   CTE_VALORTOTALMERCAD        N          17       2      .F.         .F.                             .F.       .T.       .T.        VALOR TOTAL DA MERCADORIA
   CTE_PESOBRUTO               N          12       4      .F.         .F.                             .F.       .T.       .T.        PESO BRUTO
   CTE_PESOBASECALC            N          12       4      .F.         .F.                             .F.       .T.       .T.        PESO BASE CALCULO
   CTE_PESOAFERIDO             N          12       4      .F.         .F.                             .F.       .T.       .T.        PESO AFERIDO
   CTE_UNIDADE                 C          02       0      .F.         .F.                             .F.       .T.       .T.        CODIGO DA UNIDADE
   CTE_TIPO_MEDIDA             C          20       0      .F.         .F.                             .F.       .T.       .T.        TIPO DE MEDIDA
   CTE_CUBAGEM                 N          12       4      .F.         .F.                             .F.       .T.       .T.        PESO CUBAGEM
   CTE_VOLUMES                 N          12       4      .F.         .F.                             .F.       .T.       .T.        VOLUMES
   CTE_RESPONSAVEL_SEGURO      N          01       0      .F.         .F.                             .F.       .T.       .T.        RESPONSAVEL PELO SEGURO
   CTE_VALORSERVICO            N          17       2      .F.         .F.                             .F.       .T.       .T.        VALOR SERVICO PRESTADO
   CTE_VALORRECEBER            N          17       2      .F.         .F.                             .F.       .T.       .T.        VALOR RECEBIDO PELO SERVICO PRESTADO
   CTE_APOLICE_SEGURO          C          20       0      .F.         .F.                             .F.       .T.       .T.        APOLICE DO SEGURO
   CTE_AVERBACAO_SEGURO        C          20       0      .F.         .F.                             .F.       .T.       .T.        NUMERO DA AVERBACAO
   CTE_VALORCARGA_AVERBACAO    N          17       2      .F.         .F.                             .F.       .T.       .T.        VALOR DA CARGA DESTINADO A AVERBACAO
   CTE_IMPOSTO                 N          02       0      .F.         .F.                             .F.       .T.       .T.        IMPOSTO
   CTE_ICMSBASECALC            N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DA BASE DE CALCULO DO ICMS
   CTE_ICMSALIQ                N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DA ALIQUOTA ICMS EM PERCENTUAL
   CTE_ICMSVALOR               N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DO ICMS
   CTE_ICMSREDUCAOBC           N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DA ALIQUOTA DE ICMS DE REDUCAO NA BASE DE CALCULO
   CTE_VBCSTRET                N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DA BASE DE CALCULO DO ICMS ST RETIDO
   CTE_VICMSSTRET              N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DO ICMS ST RETIDO
   CTE_PICMSSTRET              N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DO % DA ALIQUOTA DO ICMS ST RETIDO
   CTE_VCRED                   N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DO CREDITO OUTORGADO/PRESUMIDO
   CTE_VBC                     N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DA BASE DE CALCULO DO ICMS
   CTE_PREDBCOUTRAUF           N          17       3      .F.         .F.                             .F.       .T.       .T.        ALIQUOTA DE REDUÇÃO DA BC
   CTE_VBCOUTRAUF              N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DA BC DO ICMS OUTRA UF
   CTE_PICMSOUTRAUF            N          17       3      .F.         .F.                             .F.       .T.       .T.        ALIQUOTA DO ICMS OUTRA UF
   CTE_VICMSOUTRAUF            N          17       3      .F.         .F.                             .F.       .T.       .T.        VALOR DO ICMS DEVIDO OUTRA UF
   CTE_OBSERVACAO              M          10       0      .F.         .F.                             .F.       .T.       .T.        OBSERVACAO DA CT-e
   CTE_RNTRC                   C          10       0      .F.         .F.                             .F.       .T.       .T.        RNTRC / ANTT
   CTE_LOTACAO                 L          01       0      .F.         .F.                             .F.       .T.       .T.        CASO A CARGA TRANSPORTADA SEJA A LOTACAO DO VEICULO
   CTE_DATAPREVISTAENTREGA     D          08       0      .F.         .F.                             .F.       .T.       .T.        DATA PREVISTA DA ENTREGA
   CTE_PROT_CANC               C          50       0      .F.         .F.                             .F.       .T.       .T.        PROTOCOLO DE CANCELAMENTO
   CTE_PROT_INUT               C          50       0      .F.         .F.                             .F.       .T.       .T.        PROTOCOLO DE INUTILIZACAO
   CTE_ESPECIE                 C          20       0      .F.         .F.                             .F.       .T.       .T.        ESPECIE
   CTE_PLACA                   C          10       0      .F.         .F.                             .F.       .T.       .T.        PLACA DO VEICULO
   CTE_VALFRETE                N          17       2      .F.         .F.                             .F.       .T.       .T.        VALOR DO FRETE
   CTE_VALPEDAGIO              N          17       2      .F.         .F.                             .F.       .T.       .T.        VALOR DO PEDAGIO
   CTE_OUTROS                  N          17       2      .F.         .F.                             .F.       .T.       .T.        OUTROS VALORES
   CTE_COD_PRAZO               N          10       0      .F.         .F.                             .F.       .T.       .T.        CODIGO DO PRAZO DE PAGAMENTO
   CTE_FRETE_RESPONSA          C          01       0      .F.         .F.                             .F.       .T.       .T.        RESPONSABILIDADE DO FRETE
   CTE_CHAVE_COMPLETA          C          44       0      .F.         .F.                             .F.       .T.       .T.        CHAVE DA CTE COMPLEMENTAR


   TABELA: SAGI_CTE_PRESTACAO_SERVICO

   CAMPO                       TIPO  TAMANHO DECIMAL   UNICIDADE  CHAVE PRIMARIA  CHAVE ESTRANGEIRA  SERIAL  NOT NULL  SET DEFAULT   DESCRICAO
   --------------------------- ----- ------- --------- ---------- --------------- ------------------ ------- --------- ------------- -------------------------------------------
   CTE_PRESTACAO_SERVICO_ID    N          10       0      .T.         .T.                             .T.       .T.        .T.       CODIGO DA PRESTACAO DE SERVICOS
   PREST_ID_CTE                N          10       0      .F.         .F.         SAGI_CTE.CTE_ID     .F.       .T.        .T.       PREST_CTE_ID FK
   PREST_ID_CTE_CAD_SERVICO    N          10       0      .F.         .F.                             .F.       .T.        .T.       PREST_CAD_SERVICO_ID FK
   PREST_QUANT                 N          17       2      .F.         .F.                             .F.       .T.        .T.       QUANTIDADE DA PRESTACAO SERVICOS
   PREST_VALOR                 N          17       2      .F.         .F.                             .F.       .T.        .T.       VALOR DA PRESTACAO SERVICOS


   
   TABELA: SAGI_CTE_DOCS

   CAMPO                       TIPO  TAMANHO DECIMAL   UNICIDADE  CHAVE PRIMARIA  CHAVE ESTRANGEIRA  SERIAL  NOT NULL  SET DEFAULT   DESCRICAO
   --------------------------- ----- ------- --------- ---------- --------------- ------------------ ------- --------- ------------- -------------------------------------------
   CTE_DOCS_ID                 N          10       0      .T.         .T.                             .T.       .T.        .T.       CODIGO DOS DOCUMENTOS NA CT-e
   DOCS_ID_CTE                 N          10       0      .F.         .F.          SAGI_CTE.CTE_ID    .F.       .T.        .T.       CTE_ID FK
   DOCS_TIPO                   C          10       0      .F.         .F.                             .F.       .T.        .T.       TIPO DO DOCUMENTO (NF,NF-e)
   DOCS_MOD                    N          02       0      .F.         .F.                             .F.       .T.        .T.       MODELO NF
   DOCS_SERIE                  C          03       0      .F.         .F.                             .F.       .T.        .T.       SERIE NF
   DOCS_NDOC                   C          20       0      .F.         .F.                             .F.       .T.        .T.       NUMERO DOCUMENTO NF
   DOCS_DEMI                   D          08       0      .F.         .F.                             .F.       .T.        .T.       DATA EMISSAO NF
   DOCS_VBC                    N          17       2      .F.         .F.                             .F.       .T.        .T.       VALOR BASE CALCULO NF
   DOCS_VICMS                  N          17       2      .F.         .F.                             .F.       .T.        .T.       VALOR ICMS NF
   DOCS_VBCST                  N          17       2      .F.         .F.                             .F.       .T.        .T.       VALOR DA BASE DE CALCULO NF
   DOCS_VST                    N          17       2      .F.         .F.                             .F.       .T.        .T.       VALOR DA SUBST TRIB NF
   DOCS_VPROD                  N          17       2      .F.         .F.                             .F.       .T.        .T.       VALOR TOTAL DOS PRODUTOS
   DOCS_VNF                    N          17       2      .F.         .F.                             .F.       .T.        .T.       VALOR TOTAL DA NF
   DOCS_NCFOP                  N          04       0      .F.         .F.                             .F.       .T.        .T.       CFOP PREDOMINANTE NF
   DOCS_NPESO                  N          17       3      .F.         .F.                             .F.       .T.        .T.       PESO EM KG
   DOCS_CHAVENFE               C          44       0      .F.         .F.                             .F.       .T.        .T.       CHAVE NFE
   DOCS_DESCRICAOOUTROS        C         100       0      .F.         .F.                             .F.       .T.        .T.       DESCRICAO DE TIPOS=99


   TABELA: SAGI_CTE_ANEXO

   CAMPO                       TIPO  TAMANHO DECIMAL   UNICIDADE  CHAVE PRIMARIA  CHAVE ESTRANGEIRA  SERIAL  NOT NULL  SET DEFAULT   DESCRICAO
   --------------------------- ----- ------- --------- ---------- --------------- ------------------ ------- --------- ------------- -------------------------------------------
   CTE_ANEXO_ID                   N       10       0      .T.         .T.                             .T.       .T.        .T.       CODIGO DO ANEXO DO CT-e
   ANEXO_ID_CTE                   N       10       0      .F.         .F.          SAGI_CTE.CTE_ID    .F.       .T.        .T.       SEGUR_ID_CAG_CRE FK
   ANEXO_TIPO                     C       60       0      .F.         .F.                             .F.       .T.        .T.       TIPO DO ARQUIVO DA CT-e
   ANEXO_NOME                     C      250       0      .F.         .F.                             .F.       .T.        .T.       NOME DO ANEXO
   ANEXO_ARQUIVO                  M       10       0      .F.         .F.                             .F.       .T.        .T.       CONTEUDO DO ARQUIVO
   ANEXO_DATA                     D        8       0      .F.         .F.                             .F.       .T.        .T.       DATA
   ANEXO_HORA                     C        8       0      .F.         .F.                             .F.       .T.        .T.       HORA
   ANEXO_USUARIO                  C       30       0      .F.         .F.                             .F.       .T.        .T.       USUARIO
   

   TABELA: SAGI_CTE_CCE Carta de correção da CTe

   CAMPO                       TIPO  TAMANHO DECIMAL   UNICIDADE  CHAVE PRIMARIA  CHAVE ESTRANGEIRA  SERIAL  NOT NULL  SET DEFAULT   DESCRICAO
   --------------------------- ----- ------- --------- ---------- --------------- ------------------ ------- --------- ------------- -------------------------------------------
   CTE_ID                         N       10       0       .F.         .F.         SAGI_CTE.CTE_ID     .F.      .T.        .T.       IDENTIFICAO
   CTE_01                         L       01       0       .F.         .F.                             .F.      .T.        .T.       01   
   CTE_02                         L       01       0       .F.         .F.                             .F.      .T.        .T.       02   
   CTE_03                         L       01       0       .F.         .F.                             .F.      .T.        .T.       03   
   CTE_04                         L       01       0       .F.         .F.                             .F.      .T.        .T.       04   
   CTE_05                         L       01       0       .F.         .F.                             .F.      .T.        .T.       05   
   CTE_06                         L       01       0       .F.         .F.                             .F.      .T.        .T.       06   
   CTE_07                         L       01       0       .F.         .F.                             .F.      .T.        .T.       07   
   CTE_08                         L       01       0       .F.         .F.                             .F.      .T.        .T.       08   
   CTE_09                         L       01       0       .F.         .F.                             .F.      .T.        .T.       09   
   CTE_10                         L       01       0       .F.         .F.                             .F.      .T.        .T.       10   
   CTE_11                         L       01       0       .F.         .F.                             .F.      .T.        .T.       11   
   CTE_12                         L       01       0       .F.         .F.                             .F.      .T.        .T.       12   
   CTE_13                         L       01       0       .F.         .F.                             .F.      .T.        .T.       13   
   CTE_14                         L       01       0       .F.         .F.                             .F.      .T.        .T.       14   
   CTE_15                         L       01       0       .F.         .F.                             .F.      .T.        .T.       15   
   CTE_16                         L       01       0       .F.         .F.                             .F.      .T.        .T.       16   
   CTE_17                         L       01       0       .F.         .F.                             .F.      .T.        .T.       17   
   CTE_18                         L       01       0       .F.         .F.                             .F.      .T.        .T.       18   
   CTE_19                         L       01       0       .F.         .F.                             .F.      .T.        .T.       19   
   CTE_20                         L       01       0       .F.         .F.                             .F.      .T.        .T.       20   
   CTE_21                         L       01       0       .F.         .F.                             .F.      .T.        .T.       21   
   CTE_22                         L       01       0       .F.         .F.                             .F.      .T.        .T.       22   
   CTE_23                         L       01       0       .F.         .F.                             .F.      .T.        .T.       23   
   CTE_24                         L       01       0       .F.         .F.                             .F.      .T.        .T.       24   
   CTE_25                         L       01       0       .F.         .F.                             .F.      .T.        .T.       25   
   CTE_26                         L       01       0       .F.         .F.                             .F.      .T.        .T.       26   
   CTE_27                         L       01       0       .F.         .F.                             .F.      .T.        .T.       27   
   CTE_28                         L       01       0       .F.         .F.                             .F.      .T.        .T.       28   
   CTE_29                         L       01       0       .F.         .F.                             .F.      .T.        .T.       29   
   CTE_30                         L       01       0       .F.         .F.                             .F.      .T.        .T.       30   
   CTE_31                         L       01       0       .F.         .F.                             .F.      .T.        .T.       31   
   CTE_32                         L       01       0       .F.         .F.                             .F.      .T.        .T.       32   
   CTE_OBS                        M       10       0       .F.         .F.                             .F.      .T.        .T.       OBS

   
   TABELA: SAGI_CTE_VEICULOS Detalhes de lotação

   CAMPO                       TIPO  TAMANHO DECIMAL   UNICIDADE  CHAVE PRIMARIA  CHAVE ESTRANGEIRA  SERIAL  NOT NULL  SET DEFAULT   DESCRICAO
   --------------------------- ----- ------- --------- ---------- --------------- ------------------ ------- --------- ------------- -------------------------------------------
   VEIC_ID                        N     10         0       .T.         .T.                             .T.      .T.        .T.       CODIGO DO VEICULO DO CT-e
   CTE_ID                         N     10         0       .F.         .F.          sagi_cte.cte_id    .F.      .F.        .F.       SEGUR_ID_CAG_CRE FK
   VEIC_CODIGO                    C     10         0       .F.         .F.                             .F.      .F.        .F.       CODIGO DO VEICULO
   VEIC_RENAVAM                   C     11         0       .F.         .F.                             .F.      .F.        .F.       RENAVAM DO VEICULO
   VEIC_PLACA                     C     07         0       .F.         .F.                             .F.      .F.        .F.       PLACA DO VEICULO
   VEIC_TARA                      N     06         0       .F.         .F.                             .F.      .F.        .F.       TARA DO VEICULO
   VEIC_CAPAC_KG                  N     06         0       .F.         .F.                             .F.      .F.        .F.       CAPACIDADE EM KG DO VEICULO
   VEIC_CAPAC_M3                  N     03         0       .F.         .F.                             .F.      .F.        .F.       CAPACIDADE EM M3 DO VEICULO
   VEIC_TP_PROPR                  C     01         0       .F.         .F.                             .F.      .F.        .F.       TIPO DE PROPRIETARIO DO VEICULO
   VEIC_TP_VEICULO                N     01         0       .F.         .F.                             .F.      .F.        .F.       TIPO DO VEICULO
   VEIC_TP_RODADO                 N     02         0       .F.         .F.                             .F.      .F.        .F.       TIPO DE RODADO DO VEICULO
   VEIC_TP_CARROC                 N     02         0       .F.         .F.                             .F.      .F.        .F.       TIPO DE CARROCERIA DO VEICULO
   VEIC_UF_LICENC                 C     02         0       .F.         .F.                             .F.      .F.        .F.       UF DE LICENCIAMENTO DO VEICULO
   
*/

#include "common.ch"
#include "hbclass.ch"
#Include "hwgui.ch"
#include "HBXML.ch"
#include "hbCTe.ch"

#define x_BLUE  16711680
#define x_BLACK 0
#define aLISTA_UF {'AC','AL','AP','AM','BA','CE','DF','GO','ES','MA','MT','MS','MG','PA','PB','PR','PE','PI','RN','RS','RJ','RO','RR','SC','SP','SE','TO','EX'}

Class oCTe_HWgui
   DATA oFuncoes INIT hbNFeFuncoes()   // DO PROJETO HBNFE
   DATA oCTe_SEFAZ INIT oCTe_SEFAZ()   // CLASSE DE COMUNICACAO COM O SEFAZ
   DATA oCTe_GERAIS INIT oCTe_GERAIS() // CLASSE COM ROTINAS GERAIS
   DATA cSerialCert                    // SERIAL DO CERTIFICADO
   DATA tpEmis                         // Forma de emissão do CT-e
   DATA tpAmb                          // AMBIENTE DE EMISSAO - 1-PRODIUCAO|2-HOMOLOGACAO
   DATA cPastaSchemas                  // CAMINHO DA PASTA DOS SCHEMAS PARA VALIDACAO DOS XML
   DATA cJustCont                      // JUSTIFICATIVA DA CONTIGENCIA 
   DATA versaoApp                      // VERSAO DO APLICATIVO (EMISSOR)
   DATA cPastaEnvRes                   // PASTA ONDE SALVAR OS ARQUIVOS XML
   DATA cCte_Operador                  // OPERADORA, USUARIO DA TRANSMISSAO   (OPERADOR PARA ENTRAR NO DESIGNER DO FASTREPORT:  SYGECOM)
   DATA cCte_Filial                    // FILIAL OU CODIGO DA FILIAL   (USANDO:  MATRIZ, FILIAL1, FILIAL2, ...)
   DATA cCte_Estado                    // ESTADO DO EMISSOR
   DATA cCte_Cidade                    // CIDADE DO EMISSOR
   DATA cCte_CNPJ                      // CNPJ DO EMISSOR
   DATA cCte_IE                        // INSCRICAO ESTADUDAL DO EMISSOR
   DATA cCte_RAZAO                     // RAZAO SOCIAL DO EMISSOR
   DATA cCte_FANTASIA                  // NOME FANTASIA DO EMISSOR
   DATA cCte_ENDERECO                  // ENDERECO DO EMISSOR
   DATA cCte_NUMERO                    // NUMERO DO ENDERECO DO EMISSOR
   DATA cCte_BAIRRO                    // BAIRRO DO EMISSOR
   DATA cCte_CEP                       // CEP DO EMISSOR
   DATA cCte_FONE                      // TELEFONE DO EMISSOR
   DATA nCOD_SRV_PADRAO                // CODIGO DA PRESTACAO DE SERVICO PADRAO
   DATA nCOD_FIXA_EMP                  // USO DA SYGECOM
   
   DATA nCte_Icont        INIT 1001    READONLY  // SUBSTITUIR POR RESORCE DO ICONE DO SISTEMA
   DATA nCte_Img_Buscar   INIT 1010    READONLY  // SUBSTITUIR POR RESORCE DA IMAGEM PARA BOTAO DE BUSCA (LUPA)
   DATA nCte_Img_Salvar   INIT 1002    READONLY  // SUBSTITUIR POR RESORCE DA IMAGEM PARA BOTAO SALVAR / OK 
   DATA nCte_Img_Sair     INIT 1003    READONLY  // SUBSTITUIR POR RESORCE DA IMAGEM PARA BOTAO SAIR / FECHAR
   DATA cCte_Planilha     INIT 'res\planilha.bmp'  READONLY
   DATA cCte_Printer      INIT 'res\printer.bmp' READONLY
   
   DATA cCte_Chave  READONLY     // CHAVE DA CTE
   DATA cCte_DV     READONLY     // DIGITO DV DA CHAVE DA CTE
   DATA nCte_NUMERO READONLY     // NUMERO DA CTE
   DATA cVersao_DADOS            // VERSAO DOS DADOS DO SOAP ACTION ('1.04')
   DATA cVersao_CTe              // VERSAO DOS DADOS DA CT-e ('1.04')
   DATA cVersao_Modal_RODOVIARIO // VERSAO DOS DADOS DA MODAL RODOVIARIA ('1.04')
   DATA lCte_ELETRONICO INIT .T. // RECEBER .T. HABILITA A CT ELETRONICA, .F. SOMENTE CT NÃO ELETRONICA
   DATA lCte_Emulador INIT .F.
   DATA lCte_VERAO INIT .F.      // .T. HORARIO DE VERAO, .F. HORARIO DE INVERNO
   DATA cUTC INIT ''             // HORARIO UTC

   // SUBSTITUIR POR TABELA DE CFOP
   DATA tCte_CFOP READONLY INIT {'cfop'     => 'cfop',;       // NOME DA TABELA
                                 'natureza' => 'natureza' }   // CAMPO: descricao da natureza de operacao  (C,40,0)

   // SUBSTITUIR POR TABELA SERIES DE CT-e
   DATA tCte_SERIES READONLY INIT {'series'  => 'series',;  // NOME DA TABELA
                                   'serie'   => 'serie',;   // CAMPO: serie da cte (N,3,0)
                                   'tipo'    => 'tipo',;    // CAMPO: Tipo do documento ('CT-ELETRONICA','CT-FORMULARIO'),  (C,15,0)
                                   'empresa' => 'empresa' } // CAMPO: Filial ('MATRIZ','FILIAL1','FILIAL2'), (C,10,0)
                          
   // SUBSTITUIR POR TABELA DE PRESTACAO DE SERVICOS
   DATA tCte_SERVICO READONLY INIT {'tipserv' => 'tipserv',; // NOME DA TABELA
                                    'servico' => 'servico',; // CAMPO: descrição do serviço (C,30,0)
                                    'codserv' => 'codserv',; // CAMPO: Código do serviço (N,6,0)
                                    'valor'   => 'valor'}    // CAMPO: Valor do serviço (N,17,2)

   // SUBSTITUIR POR TABELA DE CADASTRO DE PRAZOS DE PAGAMENTO
   DATA tCte_PRAZO READONLY INIT {'prazo'  => 'cad_prazo',;   // NOME DA TABELA
                                  'codigo' => 'cod',;         // CAMPO: Código do prazo de pagamento
                                  'descricao' => 'descricao'} // CAMPO: Descricao do prazo de pagamento
                                    
   // SUBSTITUIR POR TABELA DE CADASTRO DE CLIENTES
   DATA tCte_CLIENTE READONLY INIT {'cag_cli'  => 'cag_cli',;  // NOME DA TABE
                                    'codcli'   => 'codcli',;   // CAMPO: Código do cliente (N,6,0)
                                    'cliente'  => 'cliente',;  // CAMPO: Nome/Razão socia do cliente (C,60,0)
                                    'fantasia' => 'fantasia',; // CAMPO: Nome fantasia / Apelido  (C,30,0)
                                    'cgc'      => 'cgc',;      // CAMPO: CGC da empresa (C,28,0)
                                    'cpf'      => 'cpf',;      // CAMPO: CPF ps fisica (C,14,0)
                                    'iest'     => 'iest',;     // CAMPO: Inscrição estadual (C,15,0)
                                    'rg'       => 'rg',;       // CAMPO: RG (C,15,0)
                                    'fone'     => 'fone',;     // CAMPO: Tefone (C,14,0)
                                    'ende'     => 'ende',;     // CAMPO: Endereço sem o Numero (C,60,0)
                                    'numende'  => 'numende',;  // CAMPO: Numero do endereço (C,8,0)
                                    'bairro'   => 'bairro',;   // CAMPO: Bairro (C,25,0)
                                    'cidade'   => 'cidade',;   // CAMPO: Cidade (C,35,0)   --> Pais no caso de exterior
                                    'cep'      => 'cep',;      // CAMPO: CEP (C,8,0)
                                    'uf'       => 'uf',;       // CAMPO: Estado (C,2,0)  --> Sigla para exterior  "EX"
                                    'email'    => 'email' }    // CAMPO: Email (M,10,0)

                                    
   // SUBSTITUIR POR TABELA DE CADASTRO DE TRANSPORTADORAS
   DATA tCte_TRANSP READONLY INIT{'transp'   => 'transp',;     // NOME DA TABELA
                                  'codigo'   => 'codigo',;     // CAMPO: Código do transportador (N,6,0)
                                  'nome'     => 'nome',;       // CAMPO: Nome/Razão social do transportador (C,60,0)
                                  'cnpj'     => 'cnpj',;       // CAMPO: CNPJ do transportador (C,18,0)
                                  'cpf'      => 'cpf',;        // CAMPO: CPF do transportador (C,14,0)
                                  'ie'       => 'ie',;         // CAMPO: Inscrição estadual do transportador (C,15,0)
                                  'rg'       => 'rg',;         // CAMPO: RG do transportador (C,12,0)
                                  'email'    => 'email',;      // CAMPO: email do transportador (C,80,0)
                                  'foneresi' => 'foneresi',;   // CAMPO: Telefone do transportador (C,14,0)
                                  'endereco' => 'endereco',;   // CAMPO: Endereço sem o número (C,60,0)
                                  'numende'  => 'numende',;    // CAMPO: Número do endereço (C,10,0)
                                  'bairro'   => 'bairro',;     // CAMPO: Bairro (C,25,0)
                                  'cidade'   => 'cidade',;     // CAMPO: Cidade (C,35,0)
                                  'ufcid'    => 'ufcid',;      // CAMPO: Estado (C,2,0)
                                  'cep'      => 'cep'}         // CAMPO: CEP (C,8,0)

                                    
***

   // Methodos de interface com o usuário (HWgui)
   Method uiListaCte()                             //  Lista das CTe
   Method uiFiltraCte(oOBJ,nORD)                   //  Filtro das CTe
   Method uiCadastraCTe(oOBJ,cLAN,nCTE_ID,lCCe)    //  Cadastro de CTe
   Method uiExluiCTe(oOBJ)                         //  Exclusão de CTe
   Method uiCad_prest_servico(oOBJ,cLAN)           //  Cadastro de prestação de serviço
   Method uiSalva_prest_servico(oOBJ,oOBJ2,cLAN)   //  Salva a prestação de serviço
   Method uiDel_prest_servico(oOBJ)                //  Exclusão de prestação de serviço
   Method uiCad_doc_orig(oOBJ,cLAN,hNNF,lCCe)      //  Cadastro de documentos originários
   Method uiValida_tipo_documento(oOBJ)            //  Valida os tipos de documentos
   Method uiSalva_doc_originario(oOBJ,oOBJ2,cLAN)  //  Salva um documento originário
   Method uiDel_doc_orig(oOBJ)                     //  Exclusão de documento originário
   Method uiSalva_cte(oOBJ,nCTE_ID)                //  Salva a CTe
   Method uiCalcula_totais(oOBJ)                   //  Calcula os totais da CTe
   Method uiImprime_dact(nCTEid)                   //  Impressão da DACTE
   Method uiEnviarPorEmail(oOBJ,nCTE_ID)           //  Envio de email da CTe
   Method uiExportaArquivos(oOBJ)                  //  Exportação de arquvivos da CTe
   Method uiMotivo(cTit)                           //  Motivo do cancelamento da CTe
   Method uiVer_dacte_xml()                        //  Visualização de um arquivo XML da DACTE
   Method uiVerificaSit_CTe(oOBJ,nCTE_ID)          //  Verifica a situação de uma CTe
   Method uiCarregaDados(nCTE_ID)                  //  Carrega os dados da CTe para o objeto da transmissão
   Method uiAtualiza_estado_municipio(oOBJ)        //  Atualiza a lista de municipio ao alterar a UF
   Method uiCartaCorrecao()                        //  Carta de correção da CTe
   Method uiRelatorioGeral()                       //  Relatorio geral de CTe
   Method uiPegaRetornoCTe(oOBJ)                   //  pega o retorno da pesquisa das CTe selecionadas 
   Method uiPegaCte(oNUM,oMOD,oSER,oEMI,oCOD_REM,oNOM_REM,oCOD_DES,oNOM_DES)  // pega uma ou mais CTe
   Method uiSalvaCCCTe(oOBJ)                       // Salva a carta de correcao da CT-e
   Method uiCarregaAnexos(oOBJ,nCTE_ID)            // Carrega os anexos
   Method uiIncluiArquivoCTe(oOBJ,nCTE_ID)         // Inclui um arquivo para a CTe
   Method uiExcluiArquivoCTe(oOBJ,nCTE_ID)         // Remove um arquivo da CTe
   Method uiAbreArquivoCTe(oOBJ,nCTE_ID)           // Abre o arquivo da CTe
   Method uiExportaArquivoCTe(oOBJ,nCTE_ID)        // Exporta um arquivo da CTe
   Method uiConfiguraHorario()                     // Configura o horario de verao / inver / UTC
   Method uiCartaCorrecao200(oOBJ,nCTE_ID)         // Carta de correcao 2.00
   Method uiPegaChaveCteComple(oCTE_COMPLE)        // Pega a chave de uma Cte
   Method uiCad_pedagio(oOBJ,cLAN)                 // Cadastro/Alteração dos dados de pedágio
   Method uiDel_pedagio(oOBJ)                      // Excluir um dado de pedágio
   
   // Metodos de comunicacao com o sefaz
   Method ctTransmite(nCTE_ID)                     //  Transmissão da CTe
   Method ctInutiliza(oBrw)                        //  Inutilização de CTe
   Method ctCancela(oBrw)                          //  Cancelamento de CTe
   

   // SUBSTITUIR POR ROTINA DE MSG DE AGUARDE PARA O USUARIO (MENSAGEM A EXIBIR, CODBLOCK A EXECUTAR)
   Method uiMsgRun(cMsg,bExec) INLINE MsgRun(cMsg,bExec)   
      
   // SUBSTITUIR POR TELA DE BUSCA DE CLIENTE (CODIGO,NOME,OBJETO DO CODIGO,OBJETO DO NOME)
   Method uiPegaCli(nCod,cNom,oCod,oNom) INLINE PEGACLI(@nCod,@cNom,oCod,oNom)
   
   // SUBSTITUIR POR TELA DE BUSCA DE PRODUTO (CODIGO,SUBCODIGO,DESCRICAO,OBJETO DO CODIGO,OBJETO DO SUBCODIGO,OBJETO DA DESCRICAO,OBJETO DA DESCRICAO DO SUBCODIGO,OBJETO DA UNIDADE,'FILTRO SQL A SER APLICADO NA LISTA DOS PRODUTO')
   Method uiPega_Produto(cCOD,cSUB,cDES,oCOD,oSUB,oDES,oDESsub,oUNI,cFILTRO) INLINE PEGA_PRODUTO(@cCOD,@cSUB,LEFT(@cDES,40),oCOD,oSUB,oDES,oDESsub,oUNI,cFILTRO)
   
   // SUBSTITUIR POR ROTINA DE TELA DE BUSCA DE SERVICOS  (CODIGO,DESCRICAO,OBJETO DO CODIGO,OBJETO DA DESCRICAO)
   Method uiPega_Servico(nCOD,cDES,oCOD,oDES) INLINE PEGA_SERVICO(@nCOD,@cDES,oCOD,oDES) 
   
   //SUBSTITUIR POR ROTINA DE TELA DE BUSCA DE CFOP
   Method uiPega_Cfop(nCFOP,cDES_CFOP,oCFOP,oDES_CFOP) INLINE PEGACFOP(@nCFOP,@cDES_CFOP,oCFOP,oDES_CFOP,'S')
   
   // SUBSTITUIR POR ROTINA DE BUSCA DE TRANSPORTADORA
   Method uiPegaTrp(nCOD,cTRP,oTRP,oCNP,oINS,oFON,oEND,oEST,oCID,oCEP,oCOD) INLINE PEGA_TRP(nCOD,cTRP,oTRP,oCNP,oINS,oFON,oEND,oEST,oCID,oCEP,oCOD)
   
   // SUBSTITUIR POR METHODO PROPRIO DE BUSCA DE NOTA FISCAL (TEM DE REFAZER)
   Method uiLocaliaNF(oOBJ,hNNF)
   
   // SUBSTITUIR POR METHODO PROPRIO DE BUSCA DE NOTA FISCAL E AUTO PREENCHIMENTO DA TELA (TEM DE REFAZER)
   Method uiImporta_NF(oOBJ,lCCe)

   Method uiCadLota(oOBJ)
   Method uiDelLota(oOBJ)
   Method uiSalvaLotacao(oOBJ,oOBJ2,cLAN)
   

EndClass

   
Method uiListaCte(cTIP) Class oCTe_HWgui
/*
   Lista de CTes
   Mauricio Cruz - 15/07/2013
*/
LOCAL oDlg, oSta
LOCAL oGroup1, oGroup2
LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6
LOCAL oPER, oINI, oFIM, oSIT, oDES, oBr1, oSEL, oBUS
LOCAL oButtonex1, oButtonex2, oButtonex3, oButtonex4, oButtonex5, oButtonex6, oButtonex7, oButtonex8, oButtonex9, oButtonex10, oButtonex11, oButtonex12
LOCAL oContainer1, oContainer2
LOCAL nPER:=1, nSIT:=1, nORD:=2
LOCAL dINI:=BOM(DATE()), dFIM:=EOM(DATE())
LOCAL cDES:='', cBUS:=''
LOCAL lSEL:=.F.
LOCAL aPOS:={.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.}
LOCAL nHANDLE_OLD := Getactivewindow() // salva o handle da janela anterior
LOCAL aSQL:={}, aRET:={}

IF cTIP=NIL
   cTIP:='CAD'
ENDIF

::cCte_CNPJ:=STRTRAN(STRTRAN(STRTRAN(::cCte_CNPJ,'/'),'-'),'.')
::uiConfiguraHorario()

IF ::nCOD_SRV_PADRAO=NIL .OR. ::nCOD_SRV_PADRAO<=0
   ::oCTe_GERAIS:uiAviso('Favor informar um item de prestação de serviço padrão nos parametros do sistema( aba CONHECIMENTO DE TRANSPORTE ).')
   RETURN(.F.)
ENDIF

INIT DIALOG oDlg TITLE "Conhecimento de Transporte Eletrônico (CTE) - "+IF(::tpAmb='1','Produção','Homologação')+' - Versão: '+::cVersao_CTe+IF(::lCte_Emulador,' -- EMULACAO','') AT 0,0 SIZE GETDESKTOPWIDTH()-15-IF(cTIP='PESQ',20,0),GETDESKTOPHEIGHT()-170-IF(cTIP='PESQ',30,0) FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     ON INIT{|| ::uiFiltraCte(oDlg,nORD), COLORHEAD(oBr1,nORD,9) };
     ON EXIT{|| aRET:=::uiPegaRetornoCTe(oDlg), HWG_BRINGWINDOWTOTOP(nHANDLE_OLD) };
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_SYSMENU+WS_SIZEBOX ICON HIcon():AddResource(::nCte_Icont)

oDlg:minHeight := 0555
oDlg:minWidth  := 1032

@ 000,003 SAY oLabel1 CAPTION "F1-Sobre / F2-Busca / F5-Excel / F6-Atualiza / F9-Calculadora" SIZE oDlg:nWidth,20 COLOR x_BLUE STYLE SS_CENTER
              oLabel1:ANCHOR:=48

@ 002,020 GROUPBOX oGroup1 CAPTION "Filtro"  SIZE oDlg:nWidth-10,50 STYLE BS_LEFT COLOR x_BLUE
          oGroup1:Anchor := 11 

@ 008,038 GET COMBOBOX oPER VAR nPER  ITEMS {'Emissão','Autorizada'} SIZE 118,24  ;
          TOOLTIP 'Selecione o período'

@ 129,041 SAY oLabel2 CAPTION "de:"  SIZE 22,21  
@ 155,038 GET DATEPICKER oINI VAR dINI SIZE 98,24;
          TOOLTIP 'Informe a data inicial'

@ 262,041 SAY oLabel3 CAPTION "ate"  SIZE 22,21
@ 286,038 GET DATEPICKER oFIM VAR dFIM SIZE 98,24;
          TOOLTIP 'Informe a data final'

@ 390,041 SAY oLabel4 CAPTION "Situação:"  SIZE 58,21  
@ 451,038 GET COMBOBOX oSIT VAR nSIT  ITEMS {'TODAS','NÃO TRANSMITIDA','AUTORIZADA','INUTILIZADA','CANCELADA'} SIZE 154,24  ; 
          TOOLTIP 'Selecione a situação do documento'

@ 616,041 SAY oLabel5 CAPTION "Destinatário:"  SIZE 79,21  
@ 692,038 GET oDES VAR cDES SIZE oGroup1:nWidth-774,24  PICTURE '@!' MAXLENGTH 150;
          TOOLTIP 'Informe o nome do destinatário ou parte do nome'
          oDES:Anchor := 11 

@ oGroup1:nWidth-76,038 BUTTONEX oButtonex10 CAPTION "&Filtrar"   SIZE 75,24 STYLE BS_CENTER +WS_TABSTOP;
                        ON CLICK{|| ::uiFiltraCte(oDlg,nORD) }
                        oButtonex10:Anchor := 8 


@ oGroup1:nLeft,oGroup1:nTop+oGroup1:nHeight GROUPBOX oGroup2 CAPTION "CT-e"  SIZE oGroup1:nWidth,oDlg:nHeight-136 STYLE BS_LEFT  
                                                      oGroup2:Anchor := 15 

@ oGroup2:nLeft+05,oGroup2:nTop+20 BROWSE oBr1 ARRAY SIZE oGroup2:nWidth-15,oGroup2:nHeight-55 STYLE WS_TABSTOP+WS_VSCROLL+WS_HSCROLL FONT HFont():Add( '',0,-11,400,,,);
                                   ON CLICK{|| IF(cTIP='PESQ',oDlg:CLOSE(),(::uiCadastraCTe(oDlg,'A'), ::uiFiltraCte(oDlg,nORD)))   }
                                          oBr1:Anchor := 15
                                          oBr1:lESC:=.T.
                                          oBr1:aArray := {{.F.,0,DATE(),'DELETA',DATE(),0,0,'DELETA',0,0}}
                                          CreateArList( oBr1, {{.F.,0,DATE(),'DELETA',DATE(),0,0,'DELETA',0,0}} )

                                          oBr1:aColumns[1]:heading := 'Sel'
                                          oBr1:aColumns[2]:heading := 'Número'
                                          oBr1:aColumns[3]:heading := 'Emissão'
                                          oBr1:aColumns[4]:heading := 'Situação'
                                          oBr1:aColumns[5]:heading := 'Data Autorização'
                                          oBr1:aColumns[6]:heading := 'Série'
                                          oBr1:aColumns[7]:heading := 'Modelo'
                                          oBr1:aColumns[8]:heading := 'Destinatário'
                                          oBr1:aColumns[9]:heading := 'Valor'
      
                                          oBr1:aColumns[1]:length := 2
                                          oBr1:aColumns[2]:length := 10       
                                          oBr1:aColumns[3]:length := 10
                                          oBr1:aColumns[4]:length := 17 //15
                                          oBr1:aColumns[5]:length := 8  //10
                                          oBr1:aColumns[6]:length := 3
                                          oBr1:aColumns[7]:length := 3
                                          oBr1:aColumns[8]:length := 65 //70
                                          oBr1:aColumns[9]:length := 15
      
                                          oBr1:aColumns[1]:picture:='@!'
                                          oBr1:aColumns[2]:picture:='@9'
                                          oBr1:aColumns[3]:picture:='@D 99/99/9999'
                                          oBr1:aColumns[4]:picture:='@!'
                                          oBr1:aColumns[5]:picture:='@D 99/99/9999'
                                          oBr1:aColumns[6]:picture:='@!'
                                          oBr1:aColumns[7]:picture:='@!'
                                          oBr1:aColumns[8]:picture:='@!'
                                          oBr1:aColumns[9]:picture:='@E 999,999,999.99'

                                          oBr1:aColumns[1]:lEDITABLE := .T.
                                          
                                          oBr1:aColumns[1]:nJusHead:= DT_LEFT
                                          oBr1:aColumns[2]:nJusHead:= DT_RIGHT
                                          oBr1:aColumns[3]:nJusHead:= DT_LEFT
                                          oBr1:aColumns[4]:nJusHead:= DT_LEFT
                                          oBr1:aColumns[5]:nJusHead:= DT_LEFT
                                          oBr1:aColumns[6]:nJusHead:= DT_RIGHT
                                          oBr1:aColumns[7]:nJusHead:= DT_RIGHT
                                          oBr1:aColumns[8]:nJusHead:= DT_RIGHT
                                          oBr1:aColumns[9]:nJusHead:= DT_RIGHT
                                          
                                          oBr1:aColumns[1]:nJusFoot:= DT_LEFT
                                          oBr1:aColumns[2]:nJusFoot:= DT_RIGHT
                                          oBr1:aColumns[3]:nJusFoot:= DT_LEFT
                                          oBr1:aColumns[4]:nJusFoot:= DT_LEFT
                                          oBr1:aColumns[5]:nJusFoot:= DT_LEFT
                                          oBr1:aColumns[6]:nJusFoot:= DT_RIGHT
                                          oBr1:aColumns[7]:nJusFoot:= DT_RIGHT
                                          oBr1:aColumns[8]:nJusFoot:= DT_RIGHT
                                          oBr1:aColumns[9]:nJusFoot:= DT_RIGHT
                                          
                                          oBr1:aColumns[1]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[2]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[3]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[4]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[5]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[6]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[7]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[8]:bColorFoot := {|| {x_BLACK , 12632256} }                                          
                                          oBr1:aColumns[9]:bColorFoot := {|| {x_BLACK , 12632256} }                                          

                                          oBr1:aColumns[1]:bHeadClick := {|| IF(aPOS[1],( ASORT(oBr1:aArray,,,{|x,y|  x[1]<y[1] }),aPOS[1]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[1]>y[1] }),aPOS[1]:=.T.  )  ), nORD:=1, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[2]:bHeadClick := {|| IF(aPOS[2],( ASORT(oBr1:aArray,,,{|x,y|  x[2]<y[2] }),aPOS[2]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[2]>y[2] }),aPOS[2]:=.T.  )  ), nORD:=2, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[3]:bHeadClick := {|| IF(aPOS[3],( ASORT(oBr1:aArray,,,{|x,y|  x[3]<y[3] }),aPOS[3]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[3]>y[3] }),aPOS[3]:=.T.  )  ), nORD:=3, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[4]:bHeadClick := {|| IF(aPOS[4],( ASORT(oBr1:aArray,,,{|x,y|  x[4]<y[4] }),aPOS[4]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[4]>y[4] }),aPOS[4]:=.T.  )  ), nORD:=4, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[5]:bHeadClick := {|| IF(aPOS[5],( ASORT(oBr1:aArray,,,{|x,y|  x[5]<y[5] }),aPOS[5]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[5]>y[5] }),aPOS[5]:=.T.  )  ), nORD:=5, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[6]:bHeadClick := {|| IF(aPOS[6],( ASORT(oBr1:aArray,,,{|x,y|  x[6]<y[6] }),aPOS[6]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[6]>y[6] }),aPOS[6]:=.T.  )  ), nORD:=6, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[7]:bHeadClick := {|| IF(aPOS[7],( ASORT(oBr1:aArray,,,{|x,y|  x[7]<y[7] }),aPOS[7]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[7]>y[7] }),aPOS[7]:=.T.  )  ), nORD:=7, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[8]:bHeadClick := {|| IF(aPOS[8],( ASORT(oBr1:aArray,,,{|x,y|  x[8]<y[8] }),aPOS[8]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[8]>y[8] }),aPOS[8]:=.T.  )  ), nORD:=8, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }
                                          oBr1:aColumns[9]:bHeadClick := {|| IF(aPOS[9],( ASORT(oBr1:aArray,,,{|x,y|  x[9]<y[9] }),aPOS[9]:=.F.  ), ( ASORT(oBr1:aArray,,,{|x,y|  x[9]>y[9] }),aPOS[9]:=.T.  )  ), nORD:=9, COLORHEAD(oBr1,nORD,9), oBr1:REFRESH() }

                                          oBr1:DelColumn( 10 )

@ oBr1:nLeft,oBr1:nTop+oBr1:nHeight+7 GET CHECKBOX oSEL VAR lSEL CAPTION "Selecionar Todos"  SIZE 127,22;
                                      VALID{|| ::oCTe_GERAIS:rgMarcaDesmarcaTudo(oBr1,1,lSEL), oSEL:CAPTION:=IF(lSEL,'Deselecionar todos','Selecionar todos'), oSEL:REFRESH() };
                                      TOOLTIP 'Marque ou desmarque esta opção para selecionar todos ou deselecionar todos.'
                                      oSEL:Anchor := 4 

@ 188,oBr1:nTop+oBr1:nHeight+7 SAY oLabel7 CAPTION "Busca:"  SIZE 45,21
                               oLabel7:Anchor := 4 

@ 231,oBr1:nTop+oBr1:nHeight+3 GET oBUS VAR cBUS SIZE oBr1:nWidth-227,24  PICTURE '@!';
                               ON CHANGE{|| BUSCA_NA_ARRAY(nORD,oBUS:GETTEXT(),oBr1) }; //ON CHANGE{|| ::oCTe_GERAIS:rgBuscaNaArray(nORD,oBUS:GETTEXT(),oBr1) };
                               TOOLTIP ''
                               oBUS:Anchor := 14 

IF cTIP='CAD'
   @ 002,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex1 CAPTION "&Cadastrar"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP;
                                      ON CLICK{|| ::uiCadastraCTe(oDlg,'C'), ::uiFiltraCte(oDlg,nORD)  }
                                      oButtonex1:Anchor := 4 

   @ oButtonex1:nLeft+oButtonex1:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex2 CAPTION "&Alterar"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP;
                                                                     ON CLICK{|| ::uiCadastraCTe(oDlg,'A'), ::uiFiltraCte(oDlg,nORD)  }
                                                                     oButtonex2:Anchor := 4 

   @ oButtonex2:nLeft+oButtonex2:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex8 CAPTION "&Excluir"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP;
                                                                     ON CLICK{|| IF(LEN(oBr1:aArray)>0,::uiMsgRun('Aguarde, exclunido a CTe...',{|| ::uiExluiCTe(oDlg), ::uiFiltraCte(oDlg,nORD) } ) ,.T.) }
                                                                     oButtonex8:Anchor := 4 
                                      
   @ oButtonex8:nLeft+oButtonex8:nWidth,oGroup2:nTop+oGroup2:nHeight+2 CONTAINER oContainer1 SIZE 5,29 STYLE 3 BACKSTYLE 2
                                                                       oContainer1:Anchor := 4 

   @ oContainer1:nLeft+oContainer1:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex3 CAPTION "&Transmitir"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+IF(::lCte_ELETRONICO,0,WS_DISABLED);
                                                                       ON CLICK{|| IF(LEN(oBr1:aArray)>0,::uiMsgRun('Aguarde, '+IF(::lCte_Emulador,'emulando','transmitindo')+' a CTe...',{|| ::ctTransmite(oBr1:aArray[oBr1:nCurrent,10]), ::uiFiltraCte(oDlg,nORD) } ) ,.T.) }
                                                                       oButtonex3:Anchor := 4 

   @ oButtonex3:nLeft+oButtonex3:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex4 CAPTION "&Inutilizar"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+IF(::lCte_ELETRONICO,0,WS_DISABLED);
                                                                     ON CLICK {|| ::uiMsgRun('Aguarde, inutilizando a CTe...'+IF(::lCte_Emulador,'EMULANDO',''),{|| ::ctInutiliza(oBr1), ::uiFiltraCte(oDlg,nORD) } ) }
                                                                     oButtonex4:Anchor := 4 

   @ oButtonex4:nLeft+oButtonex4:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex5 CAPTION "&Cancelar"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP;
                                                                     ON CLICK {|| IF(LEN(oBr1:aArray)>0,::uiMsgRun('Aguarde, cancelando a CTe...'+IF(::lCte_Emulador,'EMULANDO',''),{|| ::ctCancela(oBr1), ::uiFiltraCte(oDlg,nORD)  } ),.T.) }
                                                                     oButtonex5:Anchor := 4 

   @ oButtonex5:nLeft+oButtonex5:nWidth,oGroup2:nTop+oGroup2:nHeight+2 CONTAINER oContainer2 SIZE 5,29 STYLE 3 BACKSTYLE 2
                                                                                 oContainer2:Anchor := 4 

   @ oContainer2:nLeft+oContainer2:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex7 CAPTION "&Carta de Correção" SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+BS_MULTILINE FONT HFont():Add( '',0,-11,400,,,);
                                                                       ON CLICK {|| ::uiMsgRun('Aguarde, carta de correção para a CTe...',{|| IF(::cVersao_CTe='1.04',::uiCartaCorrecao(),::uiCadastraCTe(oDlg,'A',NIL,.T.)),::uiFiltraCte(oDlg,nORD)  })  }
                                                                       oButtonex7:Anchor := 4 
ENDIF
@ 698,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex6 CAPTION "&Imprimir"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP;
                                   ON CLICK{||  IF(LEN(oBr1:aArray)>0,::uiMsgRun('Aguarde, imprimindo a DACTE...',{|| ::uiImprime_dact(oBr1:aArray[oBr1:nCurrent,10]) }),.T.) }
                                   oButtonex6:Anchor := 4 
                                                                  
@ oButtonex6:nLeft+oButtonex6:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex1 CAPTION "&Enviar por email"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+BS_MULTILINE FONT HFont():Add( '',0,-11,400,,,);
                                                                  ON CLICK{|| ::uiMsgRun('Aguarde, enviando por email...',{|| ::uiEnviarPorEmail(oDlg) })  }
                                                                  oButtonex1:Anchor := 4 

@ oButtonex1:nLeft+oButtonex1:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex11 CAPTION "&Exportar"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+BS_MULTILINE+IF(::lCte_ELETRONICO,0,WS_DISABLED) FONT HFont():Add( '',0,-11,400,,,);
                                                                  ON CLICK{||  ::uiMsgRun('Aguarde, exportando arquivos...',{|| ::uiExportaArquivos(oDlg) }) }
                                                                  oButtonex11:Anchor := 4 
                                                                  
@ oButtonex11:nLeft+oButtonex11:nWidth,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex12 CAPTION "&Consultar Status SEFAZ"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+BS_MULTILINE+IF(::lCte_ELETRONICO,0,WS_DISABLED) FONT HFont():Add( '',0,-11,400,,,);
                                                                    ON CLICK{|| ::oCTe_SEFAZ:ctConsultaStatusSEFAZ() }
                                                                    oButtonex12:Anchor := 4 
                                                                  

@ oGroup2:nWidth-120,oGroup2:nTop+oGroup2:nHeight BUTTONEX oButtonex9 CAPTION "&Fechar"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
                                                  BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
                                                  ON CLICK{|| oDlg:CLOSE() }
                                                  oButtonex9:Anchor := 12 

ADD STATUS oSta TO oDlg 
IF cTIP='CAD'
   ACTIVATE DIALOG oDlg NOMODAL
ELSE
   ACTIVATE DIALOG oDlg
ENDIF   

RETURN(aRET)


Method uiPegaRetornoCTe(oOBJ) Class oCTe_HWgui
/*
   carrega uma array para o retorno das CTe selecionadas (CTE_ID)
   Mauricio Cruz - 23/08/2013
*/
LOCAL mI:=0
LOCAL aRET:={}

WITH OBJECT oOBJ:oBr1
   IF LEN(:aArray)<=0
      RETURN(aRET)
   ENDIF
   FOR mI:=1 TO LEN(:aArray)
      IF :aArray[mI,1]
         AADD(aRET,:aArray[mI,10])
      ENDIF
   NEXT
   IF LEN(aRET)<=0
      AADD(aRET,:aArray[:nCurrent,10])
   ENDIF
END
RETURN(aRET)

Method uiFiltraCte(oOBJ,nORD) Class oCTe_HWgui
/*
   Filtra a lista da CTe
   Mauricio Cruz - 15/07/2013
*/
LOCAL aSQL:={}

IF ::cCte_Filial=NIL .OR. EMPTY(::cCte_Filial)
   ::cCte_Filial:='MATRIZ'
ENDIF

WITH OBJECT oOBJ
   ::oCTe_GERAIS:rgExecuta_Sql('select false, '+;                                                                 // 01
                               '       a.cte_numerodacte, '+;                                                     // 02
                               '       a.cte_dataemissao, '+;                                                     // 03
                               "       case when trim(a.cte_prot_canc)<>'' then 'CANCELADA' "+;
                               "            when trim(a.cte_prot_inut)<>'' then 'INUTILIZADA' "+;
                               "            when trim(a.cte_protocolo)<>'' then 'AUTORIZADA' "+;
                               "            else 'NÃO TRANSMITIDA' "+;
                               '       end::text, '+;                                                             // 04
                               '       a.cte_dataautorizacao, '+;                                                 // 05
                               '       a.cte_serie, '+;                                                           // 06
                               '       a.cte_modelo, '+;                                                          // 07
                               '       case '+;
                               '          when b.'+::tCte_CLIENTE['cliente']+" is null and trim(a.cte_prot_inut)<>'' "+;
                               "          then 'CTE INUTILIZADA ' "+;
                               '          else b.'+::tCte_CLIENTE['cliente']+;
                               '       end::text, '+;                                                             // 08
                               '       a.cte_valortotalmercad, '+;                                                // 09
                               '       a.cte_id '+;                                                               // 10
                               '  from sagi_cte a '+;
                               '  left join '+::tCte_CLIENTE['cag_cli']+' b on a.remetente_id=b.'+::tCte_CLIENTE['codcli']+' '+;
                               '  where '+IF(:oPER:GETVALUE()=1,'a.cte_dataemissao','a.cte_dataautorizacao')+'>='+::oCTe_GERAIS:rgConcat_sql(:oINI:GETVALUE())+;
                               '    and '+IF(:oPER:GETVALUE()=1,'a.cte_dataemissao','a.cte_dataautorizacao')+'<='+::oCTe_GERAIS:rgConcat_sql(:oFIM:GETVALUE())+;
                               '    and '+IF(:oSIT:GETVALUE()<>1,"case when trim(a.cte_prot_canc)<>'' then 'CANCELADA' "+;
                                                                 "     when trim(a.cte_prot_inut)<>'' then 'INUTILIZADA' "+;
                                                                 "     when trim(a.cte_protocolo)<>'' then 'AUTORIZADA' "+;
                                                                 "     else 'NÃO TRANSMITIDA' "+;
                                                                 "end::text="+::oCTe_GERAIS:rgConcat_sql(:oSIT:GETTEXT()),'true')+;
                               '    and empresa='+::oCTe_GERAIS:rgConcat_sql(::cCte_Filial)+;
                               '    and '+IF(!EMPTY(:oDES:VARGET()),"b."+::tCte_CLIENTE['cliente']+" like '%"+ALLTRIM(:oDES:VARGET())+"%'" ,'true')+;
                               '  order by '+ALLTRIM(STR(nORD)),,,@aSQL)

   :oBr1:aArray := aSQL
   CreateArList( :oBr1, aSQL )
   
   :oBr1:aColumns[9]:FOOTING:=TRANSFORM(SOMA_COLUNA(aSQL,9),'@E 999,999,999.99')
   
   :oBr1:REFRESH()
END

RETURN(.T.)


Method uiCartaCorrecao() Class oCTe_HWgui
/*
   gera carta de correcao para a CT
   Mauricio Cruz - 19/08/2013
*/
LOCAL oDlg, oSta
LOCAL oGroup1, oGroup2, oGroup3
LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6, oLabel7
LOCAL oNUM, oMOD, oSER, oEMI, oCOD_REM, oNOM_REM, oCOD_DES, oNOM_DES, oCCP, oOBS
LOCAL oOwnerbutton1
LOCAL oCheck1, oCheck2, oCheck3, oCheck4, oCheck5, oCheck6, oCheck7, oCheck8, oCheck9, oCheck10
LOCAL oCheck11, oCheck12, oCheck13, oCheck14, oCheck15, oCheck16, oCheck17, oCheck18, oCheck19, oCheck20
LOCAL oCheck21, oCheck22, oCheck23, oCheck24, oCheck25, oCheck26, oCheck27, oCheck28, oCheck29, oCheck30
LOCAL oCheck31, oCheck32
LOCAL oButtonex1, oButtonex2
LOCAL nNUM:=0, nCOD_REM:=0, nCOD_DES:=0, mI:=0
LOCAL cMOD:='', cSER:='', cNOM_REM:='', cCCP:='', cOBS:='',  cNOM_DES:=''
LOCAL dEMI:=DATE()
LOCAL lCheck1:=.F., lCheck2:=.F., lCheck3:=.F., lCheck4:=.F., lCheck5:=.F., lCheck6:=.F., lCheck7:=.F., lCheck8:=.F., lCheck9:=.F., lCheck10:=.F. 
LOCAL lCheck11:=.F., lCheck12:=.F., lCheck13:=.F., lCheck14:=.F., lCheck15:=.F., lCheck16:=.F., lCheck17:=.F., lCheck18:=.F., lCheck19:=.F., lCheck20:=.F. 
LOCAL lCheck21:=.F., lCheck22:=.F., lCheck23:=.F., lCheck24:=.F., lCheck25:=.F., lCheck26:=.F., lCheck27:=.F., lCheck28:=.F., lCheck29:=.F., lCheck30:=.F. 
LOCAL lCheck31:=.F., lCheck32:=.F.
LOCAL aMOD:=IF(::lCte_ELETRONICO,{'57','08'},{'08'}), aSQL:={}, aSER:={}
cMOD:=aMOD[1]

::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_SERIES['serie']+;
                            '  from '+::tCte_SERIES['series']+;
                            ' where '+::tCte_SERIES['tipo']+'='+::oCTe_GERAIS:rgConcat_sql(IF(cMOD='57','CT-ELETRONICA','CT-FORMULARIO'))+;
                            '   and '+::tCte_SERIES['empresa']+'='+::oCTe_GERAIS:rgConcat_sql(::cCte_Filial),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não há séries cadastradas. Favor revisar.')
   RETURN(.F.)
ENDIF
FOR mI:=1 TO LEN(aSQL)
   AADD(aSER,ALLTRIM(STR(aSQL[mI,1])))
NEXT
cSER:=aSER[1]

INIT DIALOG oDlg TITLE "Carta de correção do conhecimento de transporte" AT 000,000 SIZE 679,599 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_SYSMENU+WS_SIZEBOX ICON HIcon():AddResource(::nCte_Icont)

oDlg:minHeight := 620
oDlg:minWidth := 689

@ 002,000 GROUPBOX oGroup1 CAPTION "Dados do conhecimento de transporte"  SIZE 674,180 STYLE BS_LEFT COLOR x_BLUE
                   oGroup1:Anchor := 11 


@ 012,019 SAY oLabel1 CAPTION "Número"  SIZE 53,21  
@ 012,040 GET oNUM VAR nNUM SIZE 101,24  PICTURE '9999999999' MAXLENGTH 10;
          VALID{|| IF(nNUM>0,::uiPegaCte(oNUM,oMOD,oSER,oEMI,oCOD_REM,oNOM_REM,oCOD_DES,oNOM_DES),.T.) };
          TOOLTIP ''

@ 116,019 SAY oLabel2 CAPTION "Modelo"  SIZE 46,21
@ 116,040 GET COMBOBOX oMOD VAR cMOD  ITEMS aMOD SIZE 193,24 TEXT;
          TOOLTIP ''
          oMOD:Anchor := 11 

@ 312,019 SAY oLabel3 CAPTION "Série"  SIZE 39,21
              oLabel3:Anchor := 8 

@ 312,040 GET COMBOBOX oSER VAR cSER ITEMS aSER SIZE 66,24 TEXT;
          TOOLTIP ''
          oSER:Anchor := 8 

@ 381,019 SAY oLabel4 CAPTION "Emissão"  SIZE 53,21
              oLabel4:Anchor := 8 

@ 381,040 GET DATEPICKER oEMI VAR dEMI SIZE 93,24 STYLE WS_DISABLED;
          TOOLTIP ''
          oEMI:Anchor := 8 

@ 476,040 OWNERBUTTON oOwnerbutton1  SIZE 24,24 FLAT;
          ON CLICK {|| oNUM:SETTEXT(0), ::uiPegaCte(oNUM,oMOD,oSER,oEMI,oCOD_REM,oNOM_REM,oCOD_DES,oNOM_DES) };
          BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
          TOOLTIP 'Localizar uma CTe'
          oOwnerbutton1:Anchor := 8 

@ 523,019 SAY oLabel7 CAPTION "Carta de correção para"  SIZE 135,21
              oLabel7:Anchor := 8 

@ 523,40 GET COMBOBOX oCCP VAR cCCP  ITEMS {'Remetente','Destinatário'} SIZE 148,24;
         TOOLTIP 'Selecione para quem deve ser a carta de correção'
         oCCP:Anchor := 8 

@ 012,071 SAY oLabel5 CAPTION "Remetente"  SIZE 74,21
@ 012,094 GET oCOD_REM VAR nCOD_REM SIZE 92,24 STYLE WS_DISABLED;
          TOOLTIP ''

@ 106,094 GET oNOM_REM VAR cNOM_REM SIZE 563,24 PICTURE '@!' STYLE WS_DISABLED;
          TOOLTIP ''
          oNOM_REM:Anchor := 11 

@ 012,123 SAY oLabel6 CAPTION "Destinatário"  SIZE 76,21
@ 012,146 GET oCOD_DES VAR nCOD_DES SIZE 92,24 STYLE WS_DISABLED;
          TOOLTIP ''

@ 106,146 GET oNOM_DES VAR cNOM_DES SIZE 563,24 PICTURE '@!' STYLE WS_DISABLED;
          TOOLTIP ''
          oNOM_DES:Anchor := 11 

@ 002,183 GROUPBOX oGroup2 CAPTION "Código da correção"  SIZE 674,264 STYLE BS_LEFT COLOR x_BLUE
                   oGroup2:Anchor := 11 

@ 011,200 GET CHECKBOX oCheck1  VAR lCheck1  CAPTION "01-Razão Social"                   SIZE 127,22  
@ 011,222 GET CHECKBOX oCheck2  VAR lCheck2  CAPTION "02-Endereço"                       SIZE 127,22  
@ 011,244 GET CHECKBOX oCheck3  VAR lCheck3  CAPTION "03-Município"                      SIZE 110,22  
@ 011,266 GET CHECKBOX oCheck4  VAR lCheck4  CAPTION "04-UF (Estado)"                    SIZE 110,22  
@ 011,288 GET CHECKBOX oCheck5  VAR lCheck5  CAPTION "05-Nº de inscrição de CNPJ/CPF"    SIZE 219,22  
@ 011,310 GET CHECKBOX oCheck6  VAR lCheck6  CAPTION "06-Nº de inscrição estadual"       SIZE 186,22  
@ 011,332 GET CHECKBOX oCheck7  VAR lCheck7  CAPTION "07-Natureza de Operação"           SIZE 174,22  
@ 011,354 GET CHECKBOX oCheck8  VAR lCheck8  CAPTION "08-Código fiscal de operação"      SIZE 192,22  
@ 011,376 GET CHECKBOX oCheck9  VAR lCheck9  CAPTION "09-Via transporte"                 SIZE 126,22  
@ 011,398 GET CHECKBOX oCheck10 VAR lCheck10 CAPTION "10-Data emissão"                   SIZE 131,22  
@ 239,200 GET CHECKBOX oCheck11 VAR lCheck11 CAPTION "11-Data saida"                     SIZE 110,22  
@ 239,222 GET CHECKBOX oCheck12 VAR lCheck12 CAPTION "12-Unidade de produto"             SIZE 158,22  
@ 239,244 GET CHECKBOX oCheck13 VAR lCheck13 CAPTION "13-Quantidade de produto"          SIZE 176,22  
@ 239,266 GET CHECKBOX oCheck14 VAR lCheck14 CAPTION "14-Descrição do produto"           SIZE 171,22  
@ 239,288 GET CHECKBOX oCheck15 VAR lCheck15 CAPTION "15-Preço unitário"                 SIZE 129,22  
@ 239,310 GET CHECKBOX oCheck16 VAR lCheck16 CAPTION "16-Valor do Produto"               SIZE 137,22  
@ 239,332 GET CHECKBOX oCheck17 VAR lCheck17 CAPTION "17-Classificação fiscal"           SIZE 165,22  
@ 239,354 GET CHECKBOX oCheck18 VAR lCheck18 CAPTION "18-Aliquota do IPI"                SIZE 132,22  
@ 239,376 GET CHECKBOX oCheck19 VAR lCheck19 CAPTION "19-Valor do IPI"                   SIZE 110,22  
@ 239,398 GET CHECKBOX oCheck20 VAR lCheck20 CAPTION "20-Base de cálculo do IPI"         SIZE 177,22  
@ 442,200 GET CHECKBOX oCheck21 VAR lCheck21 CAPTION "21-Valor total do conhecimento"    SIZE 204,22  
@ 442,222 GET CHECKBOX oCheck22 VAR lCheck22 CAPTION "22-Aliquota do ICMS"               SIZE 146,22  
@ 442,244 GET CHECKBOX oCheck23 VAR lCheck23 CAPTION "23-Valor do ICMS"                  SIZE 127,22  
@ 442,266 GET CHECKBOX oCheck24 VAR lCheck24 CAPTION "24-Base de cálculo do ICMS"        SIZE 188,22  
@ 442,288 GET CHECKBOX oCheck25 VAR lCheck25 CAPTION "25-Nome do transportador"          SIZE 178,22  
@ 442,310 GET CHECKBOX oCheck26 VAR lCheck26 CAPTION "26-Endereço do transportador"      SIZE 200,22
@ 442,332 GET CHECKBOX oCheck27 VAR lCheck27 CAPTION "27-Termo de isenção do IPI"        SIZE 186,22
@ 442,354 GET CHECKBOX oCheck28 VAR lCheck28 CAPTION "28-Termo de isenção do ICMS"       SIZE 200,22
@ 442,376 GET CHECKBOX oCheck29 VAR lCheck29 CAPTION "29-Peso bruto / líquido"           SIZE 158,22
@ 442,398 GET CHECKBOX oCheck30 VAR lCheck30 CAPTION "30-Volumes / Marcas / Quantidades" SIZE 231,22
@ 184,421 GET CHECKBOX oCheck31 VAR lCheck31 CAPTION "31-Rasuras"                        SIZE 110,22
@ 360,421 GET CHECKBOX oCheck32 VAR lCheck32 CAPTION "32-Outras"                         SIZE 092,22

@ 002,451 GROUPBOX oGroup3 CAPTION "Considerações gerais"  SIZE 674,83 STYLE BS_LEFT COLOR x_BLUE
                   oGroup3:Anchor := 15 

@ 007,471 GET oOBS VAR cOBS SIZE 665,54  PICTURE '@!';
          STYLE ES_MULTILINE+ES_AUTOVSCROLL+WS_VSCROLL+ES_WANTRETURN
          oOBS:Anchor := 15 

@ 435,536 BUTTONEX oButtonex1 CAPTION "&Salvar"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
          ON CLICK{|| ::uiSalvaCCCTe(oDlg) }
          oButtonex1:Anchor := 12 

@ 555,536 BUTTONEX oButtonex2 CAPTION "&Fechar"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| oDlg:CLOSE() }
          oButtonex2:Anchor := 12 

ADD STATUS oSta TO oDlg 
ACTIVATE DIALOG oDlg 

RETURN(.T.)


Method uiSalvaCCCTe(oOBJ) Class oCTe_HWgui
/*
   Salva a carta de correca da CT-e
   Mauricio Cruz - 23/08/2013
*/
LOCAL nCTE_ID:=0
LOCAL aSQL:={}

WITH OBJECT oOBJ
   IF :oNUM:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Favor informar uma CT-e para a carta de correção.')
      RETURN(.F.)
   ENDIF
   IF EMPTY(:oMOD:GETTEXT())
      ::oCTe_GERAIS:uiAviso('Favor selecionar o modelo da CT-e para a carta de correção.')
      RETURN(.F.)
   ENDIF

   ::oCTe_GERAIS:rgExecuta_Sql('select cte_protocolo, '+;
                               '       cte_recibo, '+;
                               '       cte_prot_canc, '+;
                               '       cte_prot_inut, '+;
                               '       cte_id '+;
                               '  from sagi_cte '+;
                               ' where cte_numerodacte='+::oCTe_GERAIS:rgConcat_sql(:oNUM:VARGET())+;
                               '   and cte_modelo='+::oCTe_GERAIS:rgConcat_sql(:oMOD:GETTEXT())+;
                               '   and cte_serie='+::oCTe_GERAIS:rgConcat_sql(:oSER:GETTEXT()),,,@aSQL)
   IF LEN(aSQL)<=0
      ::oCTe_GERAIS:uiAviso('Não foi possível localizar a CT-e desejada.')
      RETURN(.F.)
   ENDIF
   
   nCTE_ID:=aSQL[1,5]

   IF ALLTRIM(LEFT(:oMOD:GETTEXT(),2))='57'
      IF EMPTY(aSQL[1,1]) .OR. EMPTY(aSQL[1,2])
         ::oCTe_GERAIS:uiAviso('A CT-e informada ainda não foi autorizada.')
         RETURN(.F.)
      ENDIF
   ENDIF
   
   IF !EMPTY(aSQL[1,3])
      ::oCTe_GERAIS:uiAviso('A CT-e informada encontra-se cancelada e não pode mais ter carta de correção.')
      RETURN(.F.)
   ENDIF
   IF !EMPTY(aSQL[1,4])
      ::oCTe_GERAIS:uiAviso('A CT-e informada encontra-se inutilizada e não pode ter carta de correção.')
      RETURN(.F.)
   ENDIF
   
   ::oCTe_GERAIS:rgExecuta_Sql('select count(*) from sagi_cte_cce where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)
   IF LEN(aSQL)>0 .AND. aSQL[1,1]>0
      IF !::oCTe_GERAIS:uiSN('A Ct-e informada já tem uma carta de correção, esta carta de correção irá substituir a anterior. Confirma esta operação ?')
         RETURN(.F.)
      ENDIF
   ENDIF

   ::oCTe_GERAIS:rgBeginTransaction()   
   IF LEN(aSQL)<=0 .OR. aSQL[1,1]<=0
      ::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_cce(cte_id) values ('+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+')')
   ENDIF
   ::oCTe_GERAIS:rgExecuta_Sql('update sagi_cte_cce set cte_01='+::oCTe_GERAIS:rgConcat_sql(:oCheck1:GETVALUE())+','+;
                                                       'cte_02='+::oCTe_GERAIS:rgConcat_sql(:oCheck2:GETVALUE())+','+;
                                                       'cte_03='+::oCTe_GERAIS:rgConcat_sql(:oCheck3:GETVALUE())+','+;
                                                       'cte_04='+::oCTe_GERAIS:rgConcat_sql(:oCheck4:GETVALUE())+','+;
                                                       'cte_05='+::oCTe_GERAIS:rgConcat_sql(:oCheck5:GETVALUE())+','+;
                                                       'cte_06='+::oCTe_GERAIS:rgConcat_sql(:oCheck6:GETVALUE())+','+;
                                                       'cte_07='+::oCTe_GERAIS:rgConcat_sql(:oCheck7:GETVALUE())+','+;
                                                       'cte_08='+::oCTe_GERAIS:rgConcat_sql(:oCheck8:GETVALUE())+','+;
                                                       'cte_09='+::oCTe_GERAIS:rgConcat_sql(:oCheck9:GETVALUE())+','+;
                                                       'cte_10='+::oCTe_GERAIS:rgConcat_sql(:oCheck10:GETVALUE())+','+;
                                                       'cte_11='+::oCTe_GERAIS:rgConcat_sql(:oCheck11:GETVALUE())+','+;
                                                       'cte_12='+::oCTe_GERAIS:rgConcat_sql(:oCheck12:GETVALUE())+','+;
                                                       'cte_13='+::oCTe_GERAIS:rgConcat_sql(:oCheck13:GETVALUE())+','+;
                                                       'cte_14='+::oCTe_GERAIS:rgConcat_sql(:oCheck14:GETVALUE())+','+;
                                                       'cte_15='+::oCTe_GERAIS:rgConcat_sql(:oCheck15:GETVALUE())+','+;
                                                       'cte_16='+::oCTe_GERAIS:rgConcat_sql(:oCheck16:GETVALUE())+','+;
                                                       'cte_17='+::oCTe_GERAIS:rgConcat_sql(:oCheck17:GETVALUE())+','+;
                                                       'cte_18='+::oCTe_GERAIS:rgConcat_sql(:oCheck18:GETVALUE())+','+;
                                                       'cte_19='+::oCTe_GERAIS:rgConcat_sql(:oCheck19:GETVALUE())+','+;
                                                       'cte_20='+::oCTe_GERAIS:rgConcat_sql(:oCheck20:GETVALUE())+','+;
                                                       'cte_21='+::oCTe_GERAIS:rgConcat_sql(:oCheck21:GETVALUE())+','+;
                                                       'cte_22='+::oCTe_GERAIS:rgConcat_sql(:oCheck22:GETVALUE())+','+;
                                                       'cte_23='+::oCTe_GERAIS:rgConcat_sql(:oCheck23:GETVALUE())+','+;
                                                       'cte_24='+::oCTe_GERAIS:rgConcat_sql(:oCheck24:GETVALUE())+','+;
                                                       'cte_25='+::oCTe_GERAIS:rgConcat_sql(:oCheck25:GETVALUE())+','+;
                                                       'cte_26='+::oCTe_GERAIS:rgConcat_sql(:oCheck26:GETVALUE())+','+;
                                                       'cte_27='+::oCTe_GERAIS:rgConcat_sql(:oCheck27:GETVALUE())+','+;
                                                       'cte_28='+::oCTe_GERAIS:rgConcat_sql(:oCheck28:GETVALUE())+','+;
                                                       'cte_29='+::oCTe_GERAIS:rgConcat_sql(:oCheck29:GETVALUE())+','+;
                                                       'cte_30='+::oCTe_GERAIS:rgConcat_sql(:oCheck30:GETVALUE())+','+;
                                                       'cte_31='+::oCTe_GERAIS:rgConcat_sql(:oCheck31:GETVALUE())+','+;
                                                       'cte_32='+::oCTe_GERAIS:rgConcat_sql(:oCheck32:GETVALUE())+','+;
                                                       'cte_obs='+::oCTe_GERAIS:rgConcat_sql(:oOBS:VARGET())+;
                               ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID))
   ::oCTe_GERAIS:rgEndTransaction()   
   

   // QQQ CRIAR AQUI ROTINAS DE CARTA DE CORRECAO ELETRONICA
   
   
   ::oCTe_GERAIS:rgExecuta_Sql('select cliente, '+;
                               '       ende, '+;
                               '       cidade, '+;
                               '       uf, '+;
                               '       cep '+;
                               '  from cag_cli '+;
                               ' where codcli='+::oCTe_GERAIS:rgConcat_sql( IF(:oCCP:GETTEXT()='Rementente',:oCOD_REM:VARGET(),:oCOD_DES:VARGET())),,,@aSQL)
   IF LEN(aSQL)<=0
      ::oCTe_GERAIS:uiAviso('Não foi possível localizar o '+ALLTRIM(:oCCP:GETTEXT())+'.')
      RETURN(.F.)
   ENDIF

   ::oCTe_GERAIS:rgChamaFastReport('S',NIL,PEGA_ARQUIVO_SAGI(233),NIL,NIL,{:oNUM:VARGET(),;       // 01
                                                                               :oMOD:GETTEXT(),;      // 02
                                                                               :oSER:VARGET(),;       // 03
                                                                               :oEMI:GETVALUE(),;     // 04
                                                                               aSQL[1,1],;            // 05
                                                                               aSQL[1,2],;            // 06
                                                                               aSQL[1,3],;            // 07
                                                                               aSQL[1,4],;            // 08
                                                                               aSQL[1,5],;            // 09
                                                                               :oCheck1:GETVALUE(),;  // 10
                                                                               :oCheck2:GETVALUE(),;  // 11
                                                                               :oCheck3:GETVALUE(),;  // 12
                                                                               :oCheck4:GETVALUE(),;  // 13
                                                                               :oCheck5:GETVALUE(),;  // 14
                                                                               :oCheck6:GETVALUE(),;  // 15
                                                                               :oCheck7:GETVALUE(),;  // 16
                                                                               :oCheck8:GETVALUE(),;  // 17
                                                                               :oCheck9:GETVALUE(),;  // 18
                                                                               :oCheck10:GETVALUE(),; // 19
                                                                               :oCheck11:GETVALUE(),; // 20
                                                                               :oCheck12:GETVALUE(),; // 21
                                                                               :oCheck13:GETVALUE(),; // 22
                                                                               :oCheck14:GETVALUE(),; // 23
                                                                               :oCheck15:GETVALUE(),; // 24
                                                                               :oCheck16:GETVALUE(),; // 25
                                                                               :oCheck17:GETVALUE(),; // 26
                                                                               :oCheck18:GETVALUE(),; // 27
                                                                               :oCheck19:GETVALUE(),; // 28
                                                                               :oCheck20:GETVALUE(),; // 29
                                                                               :oCheck21:GETVALUE(),; // 30
                                                                               :oCheck22:GETVALUE(),; // 31
                                                                               :oCheck23:GETVALUE(),; // 32
                                                                               :oCheck24:GETVALUE(),; // 33
                                                                               :oCheck25:GETVALUE(),; // 34
                                                                               :oCheck26:GETVALUE(),; // 35
                                                                               :oCheck27:GETVALUE(),; // 36
                                                                               :oCheck28:GETVALUE(),; // 37
                                                                               :oCheck29:GETVALUE(),; // 38
                                                                               :oCheck30:GETVALUE(),; // 39
                                                                               :oCheck31:GETVALUE(),; // 40
                                                                               :oCheck32:GETVALUE(),; // 41
                                                                               :oOBS:VARGET(),;       // 42
                                                                               ::cCte_Cidade})        // 43

END

RETURN(.T.)

Method uiPegaCte(oNUM,oMOD,oSER,oEMI,oCOD_REM,oNOM_REM,oCOD_DES,oNOM_DES) Class oCTe_HWgui
/*
   Busca de Cte
   Mauricio Cruz - 23/08/2013
*/
LOCAL nCTE_ID:=0
LOCAL aCTE:={}, aSQL:={}

IF oNUM=NIL .OR. oMOD=NIL .OR. oSER=NIL
   RETURN(.F.)
ENDIF

IF oNUM:VARGET()<=0 .OR. EMPTY(oMOD:GETTEXT()) .OR. EMPTY(oSER:GETTEXT())
   aCTE:=::uiListaCte('PESQ')
   IF LEN(aCTE)<=0
      RETURN(.F.)
   ENDIF
   nCTE_ID:=aCTE[1]
ELSE
   ::oCTe_GERAIS:rgExecuta_Sql('select cte_id '+;
                               '  from sagi_cte '+;
                               ' where cte_numerodacte='+::oCTe_GERAIS:rgConcat_sql(oNUM:VARGET())+;
                               '   and cte_modelo='+::oCTe_GERAIS:rgConcat_sql(oMOD:GETTEXT())+;
                               '   and cte_serie='+::oCTe_GERAIS:rgConcat_sql(oSER:GETTEXT()),,,@aSQL)
   IF LEN(aSQL)<=0
      aCTE:=::uiListaCte('PESQ')
      IF LEN(aCTE)<=0
         RETURN(.F.)
      ENDIF
      nCTE_ID:=aCTE[1]
   ELSE
      nCTE_ID:=aSQL[1,1]
   ENDIF
ENDIF
::oCTe_GERAIS:rgExecuta_Sql('select a.cte_numerodacte, '+;
                            '       a.cte_serie, '+;
                            '       a.cte_modelo, '+;
                            '       a.cte_dataemissao, '+;
                            '       a.remetente_id, '+;
                            '       b.'+::tCte_CLIENTE['cliente']+', '+;
                            '       a.destinatario_id, '+;
                            '       c.'+::tCte_CLIENTE['cliente']+' '+;
                            '  from sagi_cte a '+;
                            '  left join '+::tCte_CLIENTE['cag_cli']+' b on b.'+::tCte_CLIENTE['codcli']+'=a.remetente_id '+;
                            '  left join '+::tCte_CLIENTE['cag_cli']+' c on c.'+::tCte_CLIENTE['codcli']+'=a.destinatario_id '+;
                            ' where a.cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)

oNUM:SETTEXT(aSQL[1,1])
oNUM:REFRESH()

oSER:Setitem(ASCAN(oSER:aItems,ALLTRIM(STR(aSQL[1,2]))))
oSER:SETTEXT(ALLTRIM(STR(aSQL[1,3])))
oSER:REFRESH()

oMOD:Setitem(ASCAN(oMOD:aItems,ALLTRIM(STRZERO(aSQL[1,3],2))))
oMOD:SETTEXT(ALLTRIM(STR(aSQL[1,3])))
oMOD:REFRESH()

IF oEMI<>NIL
   oEMI:SETVALUE(aSQL[1,4])
   oEMI:REFRESH()
ENDIF
IF oCOD_REM<>NIL
   oCOD_REM:SETTEXT(aSQL[1,5])
   oCOD_REM:REFRESH()
ENDIF
IF oNOM_REM<>NIL
   oNOM_REM:SETTEXT(aSQL[1,6])
   oNOM_REM:REFRESH()
ENDIF
IF oCOD_DES<>NIL
   oCOD_DES:SETTEXT(aSQL[1,7])
   oCOD_DES:REFRESH()
ENDIF
IF oNOM_DES<>NIL
   oNOM_DES:SETTEXT(aSQL[1,8])
   oNOM_DES:REFRESH()
ENDIF

RETURN(.T.)


Method uiExportaArquivos(oOBJ) Class oCTe_HWgui
/*
   Exporta os arquivos XML das CT-e
   Mauricio Cruz - 19/08/2013
*/
LOCAL cARQxml:=''
LOCAL mI:=0, cI:=0
LOCAL aCTE:={}, aSQL:={}, aARQzip:={}
WITH OBJECT oOBJ:oBr1
   IF LEN(:aArray)<=0
      RETURN(.F.)
   ENDIF
   FOR mI:=1 TO LEN(:aArray)
      IF :aArray[mI,1]
         AADD(aCTE,:aArray[mI,10])
      ENDIF
   NEXT
   IF LEN(aCTE)<=0
      AADD(aCTE,:aArray[:nCurrent,10])
   ENDIF
END
IF LEN(aCTE)<=0
   RETURN(.F.)
ENDIF
FOR mI:=1 TO LEN(aCTE)
   ::oCTe_GERAIS:rgExecuta_Sql('select b.cte_numerodacte, '+;
                               '       b.cte_serie, '+;
                               '       b.cte_modelo, '+;
                               '       a.anexo_nome, '+;
                               '       a.anexo_arquivo, '+;
                               '       c.'+::tCte_CLIENTE['email']+', '+;
                               '       a.anexo_tipo '+;
                               '  from sagi_cte_anexo a '+;
                               '  left join sagi_cte b on b.cte_id=anexo_id_cte '+;
                               '  left join '+::tCte_CLIENTE['cag_cli']+' c on c.'+::tCte_CLIENTE['codcli']+'=b.destinatario_id '+;
                               ' where a.anexo_id_cte='+::oCTe_GERAIS:rgConcat_sql(aCTE[mI])+;
                               "   and lower(right(a.anexo_nome,3))='xml'",,,@aSQL)
   FOR cI:=1 TO LEN(aSQL)
      cARQxml:=::cPastaEnvRes+'\'+ALLTRIM(aSQL[cI,7])+'_'+ALLTRIM(aSQL[cI,4])
      IF FILE(cARQxml)
         FERASE(cARQxml)
      ENDIF
      
      IF !MEMOWRIT(cARQxml,aSQL[cI,5],.F.) 
         ::oCTe_GERAIS:uiAviso('Não foi possível gravar o arquivo XML de envio de CT-e.')
         LOOP
      ENDIF
   
      AADD(aARQzip,cARQxml)
   NEXT
NEXT

cARQzip := SAVEFILE('CTe.ZIP','*.zip','Arquivo compactado (*.zip)')
IF cARQzip=NIL .OR. EMPTY(cARQzip)
   RETURN(.F.)
ENDIF

hb_zipfile( cARQzip,aARQzip, 9,{|cFile,nPos| HW_Atualiza_Dialogo2( 'Compactando arquivos...' + cFile ) },.T.,,.F.,.F., )

::oCTe_GERAIS:uiAviso('Arquivos exportados com sucesso.')

RETURN(.T.)

Method uiEnviarPorEmail(oOBJ,nCTE_ID) Class oCTe_HWgui
/*
   Enviar a CT-e por email
   Mauricio Cruz - 19/08/2013
*/
LOCAL cARQxml:='', cARQpdf:='', cARQzip:='', cEMAIL:=''
LOCAL mI:=0, cI:=0, nNUM:=0, nSER:=0, nMOD:=0
LOCAL aCTE:={}, aSQL:={}, aARQzip:={}
LOCAL aRET:=HASH()
// Ana Brock - Mantis 2802 - 25/04/2014
LOCAL cNUM:='',cSER:='',cMOD:='',lPDF:=.F.

IF oOBJ<>NIL
   WITH OBJECT oOBJ:oBr1
      IF LEN(:aArray)<=0
         RETURN(.F.)
      ENDIF
      FOR mI:=1 TO LEN(:aArray)
         IF :aArray[mI,1]
            AADD(aCTE,{:aArray[mI,10],:aArray[mI,7],:aArray[mI,6],:aArray[mI,2]})
         ENDIF
      NEXT
      IF LEN(aCTE)<=0
         AADD(aCTE,{:aArray[:nCurrent,10],:aArray[:nCurrent,7],:aArray[:nCurrent,6],:aArray[:nCurrent,2]})
      ENDIF
   END
ELSEIF nCTE_ID<>NIL
   ::oCTe_GERAIS:rgExecuta_Sql('select cte_modelo, '+;
                               '       cte_serie, '+;
                               '       cte_numerodacte '+;
                               '  from sagi_cte '+;
                               ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)
   IF LEN(aSQL)<=0
      ::oCTe_GERAIS:uiAviso('Não foi possível localizar a CT-e desejada.')
      RETURN(.F.)
   ENDIF
   AADD(aCTE,{nCTE_ID,aSQL[1,1],aSQL[1,2],aSQL[1,3]})
ENDIF   

IF LEN(aCTE)<=0
   RETURN(.F.)
ENDIF

IF MsgYesNo('Deseja enviar o PDF de cada nota junto ?')
   lPDF:=.T.
ENDIF

// Ana Brock - Mantis 2802 - 25/04/2014
FOR mI:=1 TO LEN(aCTE)
   IF aCTE[mI,2]=8
      cARQpdf:=::cPastaEnvRes+'\CT_'+STRZERO(aCTE[mI,4],10)+'_'+ALLTRIM(STR(aCTE[mI,3]))+'_'+ALLTRIM(STR(aCTE[mI,2]))+'.pdf'
      AADD(aARQzip,{cARQpdf})
      ::oCTe_GERAIS:rgImprimeCTPapel(aCTE[mI,1],NIL,cARQzip)
   ELSE
      ::oCTe_GERAIS:rgExecuta_Sql('select b.cte_numerodacte, '+;
                                  '       b.cte_serie, '+;
                                  '       b.cte_modelo, '+;
                                  '       a.anexo_nome, '+;
                                  '       a.anexo_arquivo, '+;
                                  '       c.'+::tCte_CLIENTE['email']+', '+;
                                  '       a.anexo_tipo '+;
                                  '  from sagi_cte_anexo a '+;
                                  '  left join sagi_cte b on b.cte_id=anexo_id_cte '+;
                                  '  left join '+::tCte_CLIENTE['cag_cli']+' c on c.'+::tCte_CLIENTE['codcli']+'=b.destinatario_id '+;
                                  ' where a.anexo_id_cte='+::oCTe_GERAIS:rgConcat_sql(aCTE[mI,1]),,,@aSQL)
      FOR cI:=1 TO LEN(aSQL)
         cARQxml:=::cPastaEnvRes+'\'+ALLTRIM(aSQL[cI,7])+'_'+ALLTRIM(aSQL[cI,4])
         IF FILE(cARQxml)
            FERASE(cARQxml)
         ENDIF
         
         IF !MEMOWRIT(cARQxml,aSQL[cI,5],.F.) 
            ::oCTe_GERAIS:uiAviso('Não foi possível gravar o arquivo XML de envio de CT-e.')
            RETURN(.F.)
         ENDIF
         AADD(aARQzip,{cARQxml})

         If lPDF = .T.
            cARQpdf:=::cPastaEnvRes+'\'+STRTRAN(LOWER(ALLTRIM(aSQL[cI,4])),'.xml','.pdf')
            IF aSQL[cI,7]='CTE' 
               IF FILE(cARQpdf)
                  FERASE(cARQpdf)
               ENDIF
               // Aqui da ERRO na primeira EXECUÇÃO, mas não impede de executar e nem deixa de criar o PDF
               aRET:=::oCTe_SEFAZ:ctImprimeFastReport(cARQxml,.F.,cARQpdf)

               IF !aRET['STATUS']
                  ::oCTe_GERAIS:uiAviso(aRET['MSG'])
                  RETURN(.F.)
               ENDIF
               AADD(aARQzip,{cARQpdf})
            ENDIF

         Endif

         cARQzip:=::cPastaEnvRes+'\'+STRZERO(aSQL[cI,1],10)+'_'+ALLTRIM(STR(aSQL[cI,2]))+'_'+ALLTRIM(STR(aSQL[cI,3]))+'.zip'
         
         // c.'+::tCte_CLIENTE['email']+'
         If !Alltrim(cEMAIL) $ Alltrim(aSQL[cI,6])
            If Empty(Alltrim(cEMAIL))
               cEMAIL := Alltrim(aSQL[cI,6])
            Else
               cEMAIL += ';'+Alltrim(aSQL[cI,6])
            Endif
         Endif
         // b.cte_numerodacte
         If !Alltrim(cNUM) $ Alltrim(Str(aSQL[cI,1],10))
            If Empty(Alltrim(cNUM))
               cNUM := Alltrim(Str(aSQL[cI,1],10))
            Else
               cNUM += ','+Alltrim(Str(aSQL[cI,1],10))
            Endif
         Endif
         // b.cte_serie
         If !Alltrim(cSER) $ Alltrim(Str(aSQL[cI,2],3))
            If Empty(Alltrim(cSER))
               cSER := Alltrim(Str(aSQL[cI,2],3))
            Else
               cSER += ','+Alltrim(Str(aSQL[cI,2],3))
            Endif
         Endif
         // b.cte_modelo
         If !Alltrim(cMOD) $ Alltrim(Str(aSQL[cI,3],2))
            If Empty(Alltrim(cMOD))
               cMOD := Alltrim(Str(aSQL[cI,3],2))
            Else
               cMOD += ','+Alltrim(Str(aSQL[cI,3],2))
            Endif
         Endif

      NEXT
      //hb_zipfile( cARQzip,aARQzip, 9,{|cFile,nPos| HW_Atualiza_Dialogo2( 'Compactando arquivos para envio...' + cFile ) },.T.,,.F.,.F., )
   ENDIF

Next

VAIEMAIL(NIL,NIL,NIL,cEMAIL,'Arquivos da CT-e Nº '+cNUM+;
                            ' série '+cSER+;
                            ' de '+::cCte_RAZAO,;
                            'Segue em anexo os arquivo da transmissão da CT-e Nº '+cNUM+;
                            ' série '+cSER+;
                            ' de '+::cCte_RAZAO,.T.,aARQzip)

RETURN(.T.)

Method uiExluiCTe(oOBJ) Class oCTe_HWgui
/*
   Exclui uma CT-e ainda não transmitida
   Mauricio Cruz - 19/08/2013
*/
LOCAL aRET:=HASH()

WITH OBJECT oOBJ:oBr1
   IF LEN(:aArray)<=0
      RETURN(.F.)
   ENDIF
   
   IF :aArray[:nCurrent,7]=8
      ::oCTe_GERAIS:uiAviso('A CT selecionada não é eletrônica e não pode ser excluida. Favor cancelar esta CT.')
      RETURN(.F.)
   ENDIF
   
   IF UPPER(ALLTRIM(:aArray[:nCurrent,4]))<>'NÃO TRANSMITIDA'
      ::oCTe_GERAIS:uiAviso('Esta CT-e encontra-se '+:aArray[:nCurrent,4]+' e não pode ser excluída.')
      RETURN(.F.)
   ENDIF
   
   IF !::oCTe_GERAIS:uiSN('Confirma a exclusão da CT-e selecionada ?')
      RETURN(.F.)
   ENDIF
   
   IF !::uiCarregaDados(:aArray[:nCurrent,10])
      RETURN(.F.)
   ENDIF

   aRET:=::oCTe_SEFAZ:ctXMLGeral()
   IF !aRET['STATUS']
      ::oCTe_GERAIS:uiAviso(aRET['MSG'])
      RETURN(.F.)
   ENDIF
   
   aRET:=::oCTe_SEFAZ:ctConsultaProtocolo()
   IF !aRET['STATUS']
      ::oCTe_GERAIS:uiAviso(aRET['MSG'])
      RETURN(.F.)
   ENDIF

   TRY
      IF aRET['cStat']<>'217'
      ENDIF
   CATCH
      ::oCTe_GERAIS:uiAviso('Esta CT-e não pode ser excluída '+HB_OsNewLine()+;
                            'Não há resposta do SEFAZ')
      RETURN(.F.)
   END
   
   IF aRET['cStat']<>'217'
      ::oCTe_GERAIS:uiAviso('Esta CT-e não pode ser excluída '+HB_OsNewLine()+;
                'Motivo: '+aRET['xMotivo'])
      RETURN(.F.)
   ENDIF

   IF !SN('Confirma a exclusão da CT-e selecionada ?')
      RETURN(.F.)
   ENDIF
   
   ::oCTe_GERAIS:rgBeginTransaction()   
   ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte_prestacao_servico where prest_id_cte='+::oCTe_GERAIS:rgConcat_sql(:aArray[:nCurrent,10]))
   ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte_docs where docs_id_cte='+::oCTe_GERAIS:rgConcat_sql(:aArray[:nCurrent,10]))
   ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte_anexo where cte_anexo_id='+::oCTe_GERAIS:rgConcat_sql(:aArray[:nCurrent,10]))
   ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte where cte_id='+::oCTe_GERAIS:rgConcat_sql(:aArray[:nCurrent,10]))
   ::oCTe_GERAIS:rgDeletaCtaRec(:aArray[:nCurrent,10]) // exclui o contas a receber
   ::oCTe_GERAIS:rgEndTransaction()

END

::oCTe_GERAIS:uiAviso('CT-e excluída com sucesso.')

RETURN(.T.)

Method uiCadastraCTe(oOBJ,cLAN,nCTE_ID,lCCe) Class oCTe_HWgui
/*
   Cadastro / alteracao de CT
   Mauricio Cruz - 16/07/2013
*/
LOCAL oDlg, oPage1, oPage2, oPage3, oSta, oContainer1
LOCAL oGroup1, oGroup3   //oGroup2
LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6, oLabel7, oLabel8, oLabel9, oLabel10, oLabel11, oLabel12, oLabel13, oLabel14, oLabel15
LOCAL oLabel16, oLabel17, oLabel18, oLabel19, oLabel20, oLabel21, oLabel22, oLabel23, oLabel24, oLabel25, oLabel26, oLabel27, oLabel28, oLabel29, oLabel30
LOCAL oLabel31, oLabel32, oLabel33, oLabel34, oLabel35, oLabel36, oLabel37, oLabel38, oLabel39, oLabel40, oLabel41, oLabel42, oLabel43
LOCAL oMODALIDADE, oMODELO, oSERIE, oTIPO_CT, oNUMCTE, oTIP_SERVICO, oCFOP, oDES_CFOP, oCIDADE_ORIGEM, oTOMADOR, oUF_ORIGEM, oUF_DESTINO, oCIDADE_DESTINO, oCOD_CLIENTE, oNOM_CLIENTE
LOCAL oCOD_DESTINATARIO, oNOM_DESTINATARIO, oCODPRO, oSUBCOD, oPRODUTO, oVAL_MERCADORIA, oPESO_BASE_CALC, oPESO_AFERIDO, oVAL_AVERBACAO, oVOLUMES, oRESPONSAVEL, oPESO_BRUTO, oCUBAGEM
LOCAL oAPOLICE, oAVERBACAO, oNOM_SEGURADORA, oOUT_CARACTERISTICAS, oBr1, oTIP_TRIBUTACAO, oBASE_CALCULO, oPER_ALIQ_ICMS, oVAL_ICMS, oPER_RED_BC, oVAL_BC_ST_RET, oVAL_ICMS_ST_RET, oTOT_ITENS
LOCAL oPER_ALI_BC_ST_RET, oVAL_CRE_OUT, oPER_RED_BC_OUT_UF, oVAL_BC_ICMS_OUT_UF, oPER_ALI_ICMS_OUT_UF, oVAL_ICMS_DEV_OUT_UF, oBr2, oOBS, oRNTRC, oENTREGa, oTOTAL, oTOT_SERVICO, oFOR_PGT
LOCAL oESPECIE, oPLACA, oVAL_FRETE, oVAL_OUTROS, oCOD_PRAZO, oDES_PRAZO, oFRT_CONTA, oCOD_EXPEDIDOR, oNOM_EXPEDIDOR, oCOD_RECEBEDOR, oNOM_RECEBEDOR
LOCAL oBr3, oUNI, oTIPmed, oCTE_COMPLE, oBr4, oBr5
LOCAL oOwnerbutton1, oOwnerbutton2, oOwnerbutton3, oOwnerbutton4, oOwnerbutton5, oOwnerbutton6, oOwnerbutton7
LOCAL oButtonex1, oButtonex2, oButtonex3, oButtonex4, oButtonex5, oButtonex6, oButtonex7, oButtonex8, oButtonex9, oButtonex10, oButtonex11, oButtonex12, oButtonex13
LOCAL oButtonex14, oButtonex15, oButtonex16, oButtonex17, oButtonex18, oButtonex19
LOCAL nNUMCTE:=0, nCFOP:=0, nCOD_CLIENTE:=0, nCOD_DESTINATARIO:=0, nVAL_MERCADORIA:=0, nCOD_PRAZO:=0, nCOD_EXPEDIDOR:=0, nCOD_RECEBEDOR:=0
LOCAL nPESO_BASE_CALC:=0, nPESO_AFERIDO:=0, nVAL_AVERBACAO:=0, nVOLUMES:=0, nPESO_BRUTO:=0, nCUBAGEM:=0, nAPOLICE:=0, nBASE_CALCULO:=0  //, nVAL_PEDAGIO:=0
LOCAL nPER_ALIQ_ICMS:=0, nVAL_ICMS:=0, nPER_RED_BC:=0, nVAL_BC_ST_RET:=0, nVAL_ICMS_ST_RET:=0, nPER_ALI_BC_ST_RET:=0, nVAL_CRE_OUT:=0, nPER_RED_BC_OUT_UF:=0
LOCAL nVAL_BC_ICMS_OUT_UF:=0, nPER_ALI_ICMS_OUT_UF:=0, nVAL_ICMS_DEV_OUT_UF:=0, nTOT_SERVICO:=0, nTOTAL:=0, nTOT_ITENS:=0, mI:=0, nVAL_FRETE:=0, nVAL_OUTROS:=0
LOCAL cDES_CFOP:='', cCIDADE_ORIGEM:=::cCte_Cidade, cUF_ORIGEM:=::cCte_Estado, cUF_DESTINO:=::cCte_Estado, cCIDADE_DESTINO:=::cCte_Cidade, cNOM_CLIENTE:='', cNOM_DESTINATARIO:='', cTOMADOR:='0', cTIP_TRIBUTACAO:='00', cAVERBACAO:=''
LOCAL cCODPRO:='', cSUBCOD:='', cPRODUTO:='', cOUT_CARACTERISTICAS:='TRANSPORTE', cRESPONSAVEL:='', cNOM_SEGURADORA:=LEFT(eNOME_EMPRESA,30), cOBS:='', cSERIE:='1', cMODELO:='', cTIPO_CT:='0', cMODALIDADE:='0', cTIP_SERVICO:='0', cFOR_PGT:='1', cRNTRC:=''
LOCAL cESPECIE:='', cPLACA:='', cDES_PRAZO:='', cFRT_CONTA:='', cNOM_EXPEDIDOR:='', cNOM_RECEBEDOR:='', cCTE_COMPLE:=''
LOCAL cUNI:='01-KG', cTIPmed:='PESO DECLARADO'
LOCAL dENTREGa:=DATE()
LOCAL aSQL:={}, aSERIE:={}, aCIDADE_ORIGEM:=::oCTe_GERAIS:rgRecarrega_combo_uf(cUF_ORIGEM,NIL,aCIDADE_ORIGEM), aCIDADE_DESTINO:=::oCTe_GERAIS:rgRecarrega_combo_uf(cUF_DESTINO,NIL,aCIDADE_DESTINO)
LOCAL aMODELO:=IF(::lCte_ELETRONICO,{'57','08'},{'08'})  , aITN_SERV:={{0,'DELETA',0,0}}, aDOCS:={{'DELETA','DELETA','DELETA','DELETA',DATE(),0,0,0,0,0,0,0,'DELETA',0,'DELETA','DELETA'}}
LOCAL aUfCid:={}, aLotacao := {{'','DELETA','',0,0,0,'',0,0,0,''}}, aPEDAGIO:={{0,'DELETA','DELETA',0,'DELETA',0,'DELETA','DELETA'}}


IF nCTE_ID=NIL
   nCTE_ID:=0
ENDIF
IF lCCe=NIL
   lCCe:=.F.
ENDIF

IF cLAN='C'
   cMODELO:=aMODELO[1]
   nNUMCTE:=::oCTe_GERAIS:rgSequencia('CT-E'+::cCte_Filial+cMODELO+cSERIE,.F.)
   nCFOP:=GET_PARAMETRO("CFOP_CTE",.T.)
   cDES_CFOP:=::oCTe_GERAIS:rgDesccfop(nCFOP)
ELSE
   WITH OBJECT oOBJ:oBr1
      IF nCTE_ID<=0
         IF LEN(:aArray)<=0
            RETURN(.F.)
         ENDIF
         nCTE_ID:=:aArray[:nCurrent,10]
      ENDIF
   END

   ::oCTe_GERAIS:rgExecuta_Sql('select a.cte_modelo, '+;                        // 01
                               '           a.cte_serie, '+;                     // 02
                               '           a.cte_modalidade, '+;                // 03
                               '           a.cte_tipo, '+;                      // 04
                               '           a.cte_tiposervico, '+;               // 05 
                               '           a.cte_tomadorservico, '+;            // 06
                               '           a.cfop_id, '+;                       // 07
                               '           a.cte_ibgeorigemprestacao, '+;       // 08
                               '           a.cte_ibgedestinoprestacao, '+;      // 09
                               '           a.remetente_id, '+;                  // 10
                               '           a.destinatario_id, '+;               // 11
                               '           a.cte_descricaopredominante, '+;     // 12
                               '           a.cte_responsavel_seguro, '+;        // 13
                               '           a.cte_volumes, '+;                   // 14
                               '           a.cte_valorcarga_averbacao, '+;      // 15
                               '           a.cte_valortotalmercad, '+;          // 16
                               '           a.cte_pesobruto, '+;                 // 17
                               '           a.cte_pesobasecalc, '+;              // 18
                               '           a.cte_pesoaferido, '+;               // 19
                               '           a.cte_cubagem, '+;                   // 20
                               '           a.cte_apolice_seguro, '+;            // 21
                               '           a.cte_averbacao_seguro, '+;          // 22
                               '           a.seguradora, '+;                    // 23
                               '           a.cte_outrascaracter, '+;            // 24
                               '           a.cte_imposto, '+;                   // 25
                               '           a.cte_icmsbasecalc, '+;              // 26
                               '           a.cte_icmsaliq, '+;                  // 27
                               '           a.cte_icmsvalor, '+;                 // 28
                               '           a.cte_icmsreducaobc, '+;             // 29
                               '           a.cte_vbcstret, '+;                  // 30
                               '           a.cte_vicmsstret, '+;                // 31
                               '           a.cte_picmsstret, '+;                // 32
                               '           a.cte_vcred, '+;                     // 33
                               '           a.cte_predbcoutrauf, '+;             // 34
                               '           a.cte_vbcoutrauf, '+;                // 35
                               '           a.cte_picmsoutrauf, '+;              // 36
                               '           a.cte_vicmsoutrauf, '+;              // 37
                               '           a.cte_rntrc, '+;                     // 38
                               '           a.cte_lotacao, '+;                   // 39
                               '           a.cte_dataprevistaentrega, '+;       // 40
                               '           a.cte_formapagamento, '+;            // 41
                               '           a.cte_observacao, '+;                // 42
                               '           a.cte_especie, '+;                   // 43
                               '           a.cte_placa, '+;                     // 44
                               '           a.cte_valfrete, '+;                  // 45
                               '           a.cte_valpedagio, '+;                // 46
                               '           a.cte_outros, '+;                    // 47
                               '           a.cte_cod_prazo, '+;                 // 48
                               '           b.'+::tCte_PRAZO['descricao']+', '+; // 49
                               '           a.cte_frete_responsa, '+;            // 50
                               '           a.expedidor_id, '+;                  // 51
                               '           a.recebedor_id, '+;                  // 52
                               '           a.cte_numerodacte, '+;               // 53
                               '           a.cte_unidade, '+;                   // 54
                               '           a.cte_tipo_medida, '+;               // 55
                               '           a.cte_chave_completa '+;             // 56
                               '  from sagi_cte a'+;
                               '  left join '+::tCte_PRAZO['prazo']+' b on b.'+::tCte_PRAZO['codigo']+'=a.cte_cod_prazo '+;
                               ' where a.cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)

   IF LEN(aSQL)<=0
      ::oCTe_GERAIS:uiAviso('Não foi possível localizar a CT desejada.')
      RETURN(.F.)
   ENDIF

   nNUMCTE:=aSQL[1,53]
   cMODELO:=STRZERO(aSQL[1,1],2)
   cSERIE:=ALLTRIM(STR(aSQL[1,2]))
   cMODALIDADE:=ALLTRIM(STRZERO(aSQL[1,3],2))
   cTIPO_CT:=ALLTRIM(STR(aSQL[1,4]))
   cTIP_SERVICO:=ALLTRIM(STR(aSQL[1,5]))
   cTOMADOR:=ALLTRIM(STR(aSQL[1,6]))
   nCFOP:=aSQL[1,7]
   cDES_CFOP:=::oCTe_GERAIS:rgDesccfop(nCFOP)
   cUF_ORIGEM:=::oCTe_GERAIS:rgRetorna_uf( VAL(LEFT(ALLTRIM(STR(aSQL[1,8])),2)),1)
   cUF_DESTINO:=::oCTe_GERAIS:rgRetorna_uf( VAL(LEFT(ALLTRIM(STR(aSQL[1,9])),2)),1)
   cCIDADE_ORIGEM:=::oCTe_GERAIS:rgRetorna_municipio(aSQL[1,8],1)
   cCIDADE_DESTINO:=::oCTe_GERAIS:rgRetorna_municipio(aSQL[1,9],1)
   ::oCTe_GERAIS:rgRecarrega_combo_uf(cUF_ORIGEM,,@aCIDADE_ORIGEM)
   ::oCTe_GERAIS:rgRecarrega_combo_uf(cUF_DESTINO,,@aCIDADE_DESTINO)
   nCOD_CLIENTE:=aSQL[1,10]
   cNOM_CLIENTE:=::oCTe_GERAIS:rgDesccli(aSQL[1,10])
   nCOD_DESTINATARIO:=aSQL[1,11]
   cNOM_DESTINATARIO:=::oCTe_GERAIS:rgDesccli(aSQL[1,11])
   nCOD_EXPEDIDOR := aSQL[1,51]
   cNOM_EXPEDIDOR := ::oCTe_GERAIS:rgDescTrp(aSQL[1,51])
   nCOD_RECEBEDOR := aSQL[1,52]
   cNOM_RECEBEDOR := ::oCTe_GERAIS:rgDesccli(aSQL[1,52])
   cPRODUTO:=aSQL[1,12]
   cRESPONSAVEL:=ALLTRIM(STR(aSQL[1,13]))
   nVOLUMES:=aSQL[1,14]
   nVAL_AVERBACAO:=aSQL[1,15]
   nVAL_MERCADORIA:=aSQL[1,16]
   nPESO_BRUTO:=aSQL[1,17]
   nPESO_BASE_CALC:=aSQL[1,18]
   nPESO_AFERIDO:=aSQL[1,19]
   nCUBAGEM:=aSQL[1,20]
   nAPOLICE:=aSQL[1,21]
   cAVERBACAO:=aSQL[1,22]
   cNOM_SEGURADORA:=aSQL[1,23]
   cOUT_CARACTERISTICAS:=aSQL[1,24]
   cTIP_TRIBUTACAO:=STRZERO(aSQL[1,25],2)
   nBASE_CALCULO:=aSQL[1,26]
   nPER_ALIQ_ICMS:=aSQL[1,27]
   nVAL_ICMS:=aSQL[1,28]
   nPER_RED_BC:=aSQL[1,29]
   nVAL_BC_ST_RET:=aSQL[1,30]
   nVAL_ICMS_ST_RET:=aSQL[1,31]
   nPER_ALI_BC_ST_RET:=aSQL[1,32]
   nVAL_CRE_OUT:=aSQL[1,33]
   nPER_RED_BC_OUT_UF:=aSQL[1,34]
   nVAL_BC_ICMS_OUT_UF:=aSQL[1,35]
   nPER_ALI_ICMS_OUT_UF:=aSQL[1,36]
   nVAL_ICMS_DEV_OUT_UF:=aSQL[1,37]
   cRNTRC:=aSQL[1,38]
   //lLOTACAO:=aSQL[1,39]
   dENTREGa:=aSQL[1,40]
   cFOR_PGT:=ALLTRIM(STR(aSQL[1,41]))
   cOBS:=aSQL[1,42]
   cESPECIE:=aSQL[1,43]
   cPLACA:=aSQL[1,44]
   nVAL_FRETE:=aSQL[1,45]
   //nVAL_PEDAGIO:=aSQL[1,46]
   nVAL_OUTROS:=aSQL[1,47]
   nCOD_PRAZO:=aSQL[1,48]
   cDES_PRAZO:=aSQL[1,49]
   cFRT_CONTA:=aSQL[1,50]
   cUNI := aSQL[1,54]
   cTIPmed := aSQL[1,55]
   cCTE_COMPLE := aSQL[1,56]

   ::oCTe_GERAIS:rgExecuta_Sql('select a.prest_id_cte_cad_servico, '+;
                               '       b.'+::tCte_SERVICO['servico']+', '+;
                               '       a.prest_quant, '+;
                               '       a.prest_valor '+;
                               '  from sagi_cte_prestacao_servico a '+;
                               '  left join '+::tCte_SERVICO['tipserv']+' b on b.'+::tCte_SERVICO['codserv']+'=a.prest_id_cte_cad_servico '+;
                               ' where prest_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aITN_SERV)
   IF LEN(aITN_SERV)<=0
       aITN_SERV:={{0,'DELETA',0,0}}
   ENDIF
   
   ::oCTe_GERAIS:rgExecuta_Sql('select a.docs_tipo, '+;
                               '       a.docs_mod,  '+;
                               '       a.docs_serie, '+;
                               '       a.docs_ndoc, '+;
                               '       a.docs_demi, '+;
                               '       a.docs_vbc, '+;
                               '       a.docs_vicms, '+;
                               '       a.docs_vbcst, '+;
                               '       a.docs_vst, '+;
                               '       a.docs_vprod, '+;
                               '       a.docs_vnf, '+;
                               '       a.docs_ncfop, '+;
                               '       b.'+::tCte_CFOP['natureza']+', '+;
                               '       a.docs_npeso, '+;
                               '       a.docs_chavenfe, '+;
                               '       a.docs_descricaooutros '+;
                               '  from sagi_cte_docs a '+;
                               '  left join '+::tCte_CFOP['cfop']+' b on b.'+::tCte_CFOP['cfop']+'=a.docs_ncfop '+;
                               ' where a.docs_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aDOCS)
   IF LEN(aDOCS)<=0
      aDOCS:={{'DELETA',0,'DELETA','DELETA',DATE(),0,0,0,0,0,0,0,'DELETA',0,'DELETA','DELETA'}}
   ENDIF

   FOR mI:=1 TO LEN(aDOCS)
      aDOCS[mI,2]:=STRZERO(aDOCS[mI,2],2)
   NEXT
   
   cSQL := 'Select VEIC_CODIGO, VEIC_RENAVAM, VEIC_PLACA, VEIC_TARA, VEIC_CAPAC_KG, VEIC_CAPAC_M3, VEIC_TP_PROPR, VEIC_TP_VEICULO, VEIC_TP_RODADO, VEIC_TP_CARROC, VEIC_UF_LICENC '
   cSQL +=   'From SAGI_CTE_VEICULOS '
   cSQL +=  'Where CTE_ID = '+Concat_Sql(nCTE_ID)
   Executa_SQL(cSQL,,,@aSQL)
   If Len(aSql) > 0
      IF LEN(aLotacao)=1 .AND. aLotacao[1,2]='DELETA'
         ADEL(aLotacao,1,.T.)
      Endif
   Endif
   For nLoop := 1 to Len(aSQL)
      aAdd(aLotacao, {aSQL[nLoop,01],aSQL[nLoop,02],aSQL[nLoop,03],aSQL[nLoop,04],aSQL[nLoop,05],aSQL[nLoop,06],aSQL[nLoop,07],aSQL[nLoop,08],aSQL[nLoop,09],aSQL[nLoop,10],aSQL[nLoop,11]  }  )
   Next

   
   ::oCTe_GERAIS:rgExecuta_Sql('select a.pedagio_fornecedor, '+;
                               '       b.fornecedor, '+;
                               '       a.pedagio_comprovante, '+;
                               '       a.pedagio_responsavel, '+;
                               '       c.cliente, '+;
                               '       a.pedagio_valor, '+;
                               '       a.pedagio_cnpj_for, '+;
                               '       a.pedagio_cnpj_res '+;
                               '  from sagi_cte_pedagio a '+;
                               '  left join cag_for b on b.codfor=a.pedagio_fornecedor '+;
                               '  left join cag_cli c on c.codcli=a.pedagio_responsavel '+;
                               ' where a.cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aPEDAGIO)
   IF LEN(aPEDAGIO)<=0
      aPEDAGIO:={{0,'DELETA','DELETA',0,'DELETA',0,'DELETA','DELETA'}}
   ENDIF
ENDIF   

::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_SERIES['serie']+;
                            '  from '+::tCte_SERIES['series']+;
                            ' where '+::tCte_SERIES['tipo']+'='+::oCTe_GERAIS:rgConcat_sql(IF(cMODELO='57','CT-ELETRONICA','CT-FORMULARIO'))+;
                            '   and '+::tCte_SERIES['empresa']+'='+::oCTe_GERAIS:rgConcat_sql(::cCte_Filial),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não há séries cadastradas. Favor revisar.')
   RETURN(.F.)
ENDIF
FOR mI:=1 TO LEN(aSQL)
   AADD(aSERIE,ALLTRIM(STR(aSQL[mI,1])))
NEXT

INIT DIALOG oDlg TITLE IF(lCCe,'Carta de Correção de Conhecimento de Transporte - ','Cadastro de Conhecimento de Transporte - ')+IF(::tpAmb='1','Produção','Homologação')+' - Versão: '+::cVersao_CTe    AT 0, 0 SIZE 1020,684 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     ON INIT{||  ::uiVerificaSit_CTe(oDlg,nCTE_ID,lCCe), IF(::nCOD_SRV_PADRAO<>NIL .AND. cLAN='C',(::uiCad_prest_servico(oDlg,'C',::nCOD_SRV_PADRAO),::uiCalcula_totais(oDlg)),.T.) };
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_SYSMENU ICON HIcon():AddResource(::nCte_Icont)
   
@ 000,000 TAB oPage1 ITEMS {} SIZE 1019,621
BEGIN PAGE 'Cadastro de Conhecimento de Transporte' OF oPage1
   
   @ 002,027 GROUPBOX oGroup1 CAPTION "Informações do CT"  TRANSPARENT SIZE 1013,117 STYLE BS_LEFT COLOR x_BLUE 

   @ 007,041 SAY oLabel5 CAPTION "Número"  TRANSPARENT SIZE 52,21
   @ 007,061 GET oNUMCTE VAR nNUMCTE SIZE 96,24 STYLE WS_DISABLED

   @ 107,041 SAY oLabel2 CAPTION "Modelo"  TRANSPARENT SIZE 50,21 
   @ 107,061 GET COMBOBOX oMODELO VAR cMODELO  ITEMS aMODELO SIZE 191,24 TEXT STYLE IF(cLAN='A',WS_DISABLED,0); 
             TOOLTIP 'Selecione o modelo'

   @ 302,041 SAY oLabel3 CAPTION "Série"  TRANSPARENT SIZE 38,21
   @ 302,061 GET COMBOBOX oSERIE VAR cSERIE  ITEMS aSERIE SIZE 54,24 TEXT STYLE IF(cLAN='A',WS_DISABLED,0); 
             TOOLTIP 'Selecione a série'

   @ 360,041 SAY oLabel1 CAPTION "Modalidade"  TRANSPARENT SIZE 72,21 
   @ 360,061 GET COMBOBOX oMODALIDADE VAR cMODALIDADE  ITEMS {"01-Rodoviário"} SIZE 172,24 TEXT; 
             TOOLTIP 'Selecionar a modalidade'

   @ 535,041 SAY oLabel4 CAPTION "Tipo CT"  TRANSPARENT SIZE 51,21  
   @ 535,061 GET COMBOBOX oTIPO_CT VAR cTIPO_CT ITEMS {'0-CT-e normal','1-CT-e de Complemento de Valores'} SIZE 138,24 TEXT;   //,'2-CT-e de Anulação','3-CT-e Substituto'
             TOOLTIP 'Selecione o tipo de CT'

   @ 676,041 SAY oLabel6 CAPTION "Tipo de Serviço"  TRANSPARENT SIZE 94,21
   @ 676,061 GET COMBOBOX oTIP_SERVICO VAR cTIP_SERVICO  ITEMS {'0-Normal','1-Subcontratação','2-Redespacho','3-Redespacho Intermediario'} SIZE 148,24 TEXT;
             TOOLTIP 'Selecione o tipo de serviço'  // implementar o: tpServ

   @ 827,040 SAY oLabel7 CAPTION "Tomador do Serviço"  TRANSPARENT SIZE 121,21  
   @ 827,061 GET COMBOBOX oTOMADOR VAR cTOMADOR  ITEMS {'0-Remetente','1-Expedidor','2-Recebedor','3-Destinatário'} SIZE 184,24 TEXT; 
             TOOLTIP 'Selecione o tomador do serviço'

   @ 007,091 SAY oLabel8 CAPTION "CFOP"  TRANSPARENT SIZE 46,21
   @ 007,112 GET oCFOP VAR nCFOP SIZE 69,24  PICTURE '9999' MAXLENGTH 4; 
             VALID{|| IF(nCFOP>0, ::uiPega_Cfop(@nCFOP,@cDES_CFOP,oCFOP,oDES_CFOP),.T.) };
             TOOLTIP 'Informe o CFOP'

   @ 076,112 GET oDES_CFOP VAR cDES_CFOP SIZE 283,24  PICTURE '@!' STYLE WS_DISABLED

   @ 360,112 OWNERBUTTON oOwnerbutton1  SIZE 24,24 FLAT;
             ON CLICK {|| nCFOP:=0, cDES_CFOP:='', ::uiPega_Cfop(@nCFOP,@cDES_CFOP,oCFOP,oDES_CFOP) };
             BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
             TOOLTIP 'Localizar um CFOP'

   @ 387,091 SAY oLabel9 CAPTION "Origem da Prestação"  TRANSPARENT SIZE 126,21
   @ 387,112 GET COMBOBOX oUF_ORIGEM VAR cUF_ORIGEM  ITEMS aLISTA_UF SIZE 56,24 DISPLAYCOUNT 20 TEXT; 
             ON CHANGE {|| ::oCTe_GERAIS:rgRecarrega_combo_uf(cUF_ORIGEM,oCIDADE_ORIGEM,aCIDADE_ORIGEM),.T. };
             STYLE WS_DISABLED;
             TOOLTIP 'Selecione a UF de origem'

   @ 444,112 GET COMBOBOX oCIDADE_ORIGEM VAR cCIDADE_ORIGEM ITEMS aCIDADE_ORIGEM SIZE 253,24 DISPLAYCOUNT 20 TEXT; 
             STYLE WS_DISABLED;
             TOOLTIP 'Selecione a cidade de origem'

   @ 701,091 SAY oLabel10 CAPTION "Destino da Prestação"  TRANSPARENT SIZE 128,21
   @ 701,112 GET COMBOBOX oUF_DESTINO VAR cUF_DESTINO  ITEMS aLISTA_UF SIZE 56,24 DISPLAYCOUNT 20 TEXT; 
             ON CHANGE {|| ::oCTe_GERAIS:rgRecarrega_combo_uf(cUF_DESTINO,oCIDADE_DESTINO,aCIDADE_DESTINO),.T. };
             STYLE WS_DISABLED;
             TOOLTIP 'Selecione a UF de destino'

   @ 758,112 GET COMBOBOX oCIDADE_DESTINO VAR cCIDADE_DESTINO  ITEMS aCIDADE_DESTINO SIZE 253,24 DISPLAYCOUNT 20 TEXT;
             STYLE WS_DISABLED;
             TOOLTIP 'Selecione a cidade de destino'

***

   @ 002,145 TAB oPage3 ITEMS {} SIZE 1013,75
   BEGIN PAGE 'Remetente' OF oPage3
      @ 007,033 GET oCOD_CLIENTE VAR nCOD_CLIENTE SIZE 80,24  PICTURE '999999' MAXLENGTH 10 STYLE IF(lCCe,WS_DISABLED,0);
                VALID{|| IF(nCOD_CLIENTE>0,::uiPegaCli(@nCOD_CLIENTE,@cNOM_CLIENTE,oCOD_CLIENTE,oNOM_CLIENTE),.T.),::uiAtualiza_estado_municipio(oDlg) };  
                TOOLTIP 'Informe o código do cliente ou deixe vazio para informar o nome'
                
      @ 089,033 GET oNOM_CLIENTE VAR cNOM_CLIENTE SIZE 893,24  PICTURE '@!' MAXLENGTH 150  STYLE IF(lCCe,WS_DISABLED,0); 
                VALID{|| IF(nCOD_CLIENTE<=0,::uiPegaCli(@nCOD_CLIENTE,@cNOM_CLIENTE,oCOD_CLIENTE,oNOM_CLIENTE),.T.),::uiAtualiza_estado_municipio(oDlg)  };
                TOOLTIP 'Informe o nome do cliente, parte do nome ou deixe vazio para a lista'

      @ 983,033 OWNERBUTTON oOwnerbutton2  SIZE 24,24 FLAT STYLE IF(lCCe,WS_DISABLED,0);
                ON CLICK {|| nCOD_CLIENTE:=0, cNOM_CLIENTE:='', ::uiPegaCli(@nCOD_CLIENTE,@cNOM_CLIENTE,oCOD_CLIENTE,oNOM_CLIENTE), ::uiAtualiza_estado_municipio(oDlg) };
                BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
                TOOLTIP 'Localizar um Remetente'
   END PAGE OF oPage3
   BEGIN PAGE 'Destinatário' OF oPage3
      @ 007,033 GET oCOD_DESTINATARIO VAR nCOD_DESTINATARIO SIZE 80,24  PICTURE '999999' MAXLENGTH 10 STYLE IF(lCCe,WS_DISABLED,0); 
                VALID{|| IF(nCOD_DESTINATARIO>0,::uiPegaCli(@nCOD_DESTINATARIO,@cNOM_DESTINATARIO,oCOD_DESTINATARIO,oNOM_DESTINATARIO),.T.),::uiAtualiza_estado_municipio(oDlg) };  
                TOOLTIP 'Informe o código do cliente ou deixe vazio para informar o nome'

      @ 089,033 GET oNOM_DESTINATARIO VAR cNOM_DESTINATARIO SIZE 893,24  PICTURE '@!' MAXLENGTH 150 STYLE IF(lCCe,WS_DISABLED,0); 
                VALID{|| IF(nCOD_DESTINATARIO<=0,::uiPegaCli(@nCOD_DESTINATARIO,@cNOM_DESTINATARIO,oCOD_DESTINATARIO,oNOM_DESTINATARIO),.T.),::uiAtualiza_estado_municipio(oDlg) };
                TOOLTIP 'Informe o nome do destinatário, parte do nome ou deixe vazio para a lista'

      @ 983,033 OWNERBUTTON oOwnerbutton3  SIZE 24,24 FLAT STYLE IF(lCCe,WS_DISABLED,0);
                ON CLICK {|| nCOD_DESTINATARIO:=0, cNOM_DESTINATARIO:='', ::uiPegaCli(@nCOD_DESTINATARIO,@cNOM_DESTINATARIO,oCOD_DESTINATARIO,oNOM_DESTINATARIO),::uiAtualiza_estado_municipio(oDlg) };
                BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
                TOOLTIP 'Localizar um Destinatário'
   END PAGE OF oPage3
   BEGIN PAGE 'Expedidor' OF oPage3
      @ 007,033 GET oCOD_EXPEDIDOR VAR nCOD_EXPEDIDOR SIZE 80,24  PICTURE '999999' MAXLENGTH 10 STYLE IF(lCCe,WS_DISABLED,0); 
                VALID{|| IF(nCOD_EXPEDIDOR>=0,::uiPegaTrp(@nCOD_EXPEDIDOR,@cNOM_EXPEDIDOR,oNOM_EXPEDIDOR,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oCOD_EXPEDIDOR),.T.)  };
                TOOLTIP 'Informe o código do cliente ou deixe vazio para informar o nome'

      @ 089,033 GET oNOM_EXPEDIDOR VAR cNOM_EXPEDIDOR SIZE 893,24  PICTURE '@!' MAXLENGTH 150 STYLE IF(lCCe,WS_DISABLED,0); 
                VALID{|| IF(nCOD_EXPEDIDOR>=0,::uiPegaTrp(@nCOD_EXPEDIDOR,@cNOM_EXPEDIDOR,oNOM_EXPEDIDOR,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oCOD_EXPEDIDOR),.T.) };
                TOOLTIP 'Informe o nome do expedidor, parte do nome ou deixe vazio para a lista'

      @ 983,033 OWNERBUTTON oOwnerbutton6  SIZE 24,24 FLAT STYLE IF(lCCe,WS_DISABLED,0);
                ON CLICK {|| nCOD_EXPEDIDOR:=0, cNOM_EXPEDIDOR:='', ::uiPegaTrp(@nCOD_EXPEDIDOR,@cNOM_EXPEDIDOR,oNOM_EXPEDIDOR,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oCOD_EXPEDIDOR) };
                BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
                TOOLTIP 'Localizar um expedidor'
   END PAGE OF oPage3
   BEGIN PAGE 'Recebedor' OF oPage3
      @ 007,033 GET oCOD_RECEBEDOR VAR nCOD_RECEBEDOR SIZE 80,24  PICTURE '999999' MAXLENGTH 10 STYLE IF(lCCe,WS_DISABLED,0); 
                VALID{|| IF(nCOD_RECEBEDOR<=0,::uiPegaCli(@nCOD_RECEBEDOR,@cNOM_RECEBEDOR,oCOD_RECEBEDOR,oNOM_RECEBEDOR),.T.)  };
                TOOLTIP 'Informe o código do cliente ou deixe vazio para informar o nome'

      @ 089,033 GET oNOM_RECEBEDOR VAR cNOM_RECEBEDOR SIZE 893,24  PICTURE '@!' MAXLENGTH 150 STYLE IF(lCCe,WS_DISABLED,0);
                VALID{|| IF(nCOD_RECEBEDOR<=0,::uiPegaCli(@nCOD_RECEBEDOR,@cNOM_RECEBEDOR,oCOD_RECEBEDOR,oNOM_RECEBEDOR),.T.) };
                TOOLTIP 'Informe o nome do recebedor, parte do nome ou deixe vazio para a lista'

      @ 983,033 OWNERBUTTON oOwnerbutton7  SIZE 24,24 FLAT STYLE IF(lCCe,WS_DISABLED,0);
                ON CLICK {|| nCOD_RECEBEDOR:=0, cNOM_RECEBEDOR:='', ::uiPegaCli(@nCOD_RECEBEDOR,@cNOM_RECEBEDOR,oCOD_RECEBEDOR,oNOM_RECEBEDOR) };
                BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
                TOOLTIP 'Localizar um recebedor'
   END PAGE OF oPage3
   
   @ 875,144 BUTTONEX oButtonex9 CAPTION 'Importar de nota fiscal' SIZE 140,24 STYLE BS_CENTER+WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
             ON CLICK{|| ::uiImporta_NF(oDlg,lCCe),;
                         ::uiAtualiza_estado_municipio(oDlg) }

   @ 007,236 SAY oLabel13 CAPTION "Produto"  TRANSPARENT SIZE 50,21
   @ 007,256 GET oCODPRO VAR cCODPRO SIZE 80,24  PICTURE '@!' MAXLENGTH 6;
             TOOLTIP 'Informe o código do produto ou deixe vazio para informar a descrição'

   @ 088,256 GET oSUBCOD VAR cSUBCOD SIZE 31,24  PICTURE '@!' MAXLENGTH 1  ; 
             TOOLTIP 'Informe o subcodigo do produto ou deixe vazio para informar a descrição'

   @ 121,256 GET oPRODUTO VAR cPRODUTO SIZE 353,24  PICTURE '@!' MAXLENGTH 40  ;
             TOOLTIP 'Informe a descrição do produto'

   @ 475,256 OWNERBUTTON oOwnerbutton4  SIZE 24,24 FLAT;
             ON CLICK {|| cCODPRO:='', cSUBCOD:='', ::uiPega_Produto(@cCODPRO,@cSUBCOD,LEFT(@cPRODUTO,40),oCODPRO,oSUBCOD,oPRODUTO,NIL,NIL,'not coalesce(diverso,false)') };
             BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
             TOOLTIP 'Localizar um produto'
   
   
   @ 503,236 SAY oLabel17 CAPTION "Responsável"  TRANSPARENT SIZE 80,21  
   @ 503,256 GET COMBOBOX oRESPONSAVEL VAR cRESPONSAVEL  ITEMS {'0-Remetente','1-Expedidor','2-Recebedor','3-Destinatário','4-Emitente CT','5-Tomador do serviço'} SIZE 134,24 TEXT; 
             TOOLTIP 'Selecione o responsável'
             
***             

   @ 002,218 GROUPBOX oGroup3 CAPTION "Características e Seguro"  TRANSPARENT SIZE 1013,169 STYLE BS_LEFT COLOR x_BLUE

   @ 643,236 SAY oLabel16 CAPTION "Volumes (Und)"  TRANSPARENT SIZE 90,21  
   @ 643,256 GET oVOLUMES VAR nVOLUMES SIZE 120,24  PICTURE '@E 999,999.999' MAXLENGTH 9  ; 
             TOOLTIP 'Inform os volumes em unidades'

   @ 766,236 SAY oLabel14 CAPTION "Valor Averbação R$"  TRANSPARENT SIZE 117,21  
   @ 766,256 GET oVAL_AVERBACAO VAR nVAL_AVERBACAO SIZE 120,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12  ; 
             TOOLTIP 'Informe o valor da averbação'

   @ 890,236 SAY oLabel15 CAPTION "Valor Mercadoria R$"  TRANSPARENT SIZE 121,21  
   @ 890,256 GET oVAL_MERCADORIA VAR nVAL_MERCADORIA SIZE 120,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12  ; 
             TOOLTIP 'Informe o valor da mercadoria'

   @ 007,286 SAY oLabel18 CAPTION "Peso"  TRANSPARENT SIZE 99,21  
   @ 007,306 GET oPESO_BRUTO VAR nPESO_BRUTO SIZE 133,24  PICTURE '@E 999,999.999' MAXLENGTH 9 STYLE IF(lCCe,WS_DISABLED,0); 
             TOOLTIP 'Informe o peso bruto em kilos'
   
   @ 146,286 SAY oLabel19 CAPTION "Unidade"  TRANSPARENT SIZE 80,21  
   @ 146,306 GET COMBOBOX oUNI VAR cUNI  ITEMS {'00-M3', '01-KG','02-TON','03-UNIDADE','04-LITROS','05-MMBTU'} SIZE 100,24 TEXT STYLE IF(lCCe,WS_DISABLED,0);
                 TOOLTIP 'Selecione o código da unidade de medida'

   @ 250,286 SAY oLabel20 CAPTION "Tipo de Medida"  TRANSPARENT SIZE 100,21  
   @ 250,306 GET COMBOBOX oTIPmed VAR cTIPmed  ITEMS {'PESO BRUTO','PESO DECLARADO','PESO CUBADO','PESO AFORADO','PESO AFERIDO','PESO BASE DE CÁLCULO','LITRAGEM','CAIXAS'} SIZE 318,24 TEXT STYLE IF(lCCe,WS_DISABLED,0);
                 TOOLTIP 'Selecione o tipo de medida'

/*
   @ 146,286 SAY oLabel19 CAPTION "Peso Base Calc. (KG)"  TRANSPARENT SIZE 132,21  
   @ 146,306 GET oPESO_BASE_CALC VAR nPESO_BASE_CALC SIZE 133,24  PICTURE '@E 999,999.999' STYLE IF(lCCe,WS_DISABLED,0); 
             TOOLTIP 'Informe o peso da base de calculo'

   @ 285,285 SAY oLabel20 CAPTION "Peso Aferido (KG)"  TRANSPARENT SIZE 108,21  
   @ 285,306 GET oPESO_AFERIDO VAR nPESO_AFERIDO SIZE 133,24  PICTURE '@E 999,999.999' MAXLENGTH 9 STYLE IF(lCCe,WS_DISABLED,0); 
             TOOLTIP 'Informe o peso aferido'

   @ 423,285 SAY oLabel21 CAPTION "Cubagem (M³)"  TRANSPARENT SIZE 85,21  
   @ 423,306 GET oCUBAGEM VAR nCUBAGEM SIZE 133,24  PICTURE '@E 999,999.999' MAXLENGTH 9 STYLE IF(lCCe,WS_DISABLED,0); 
             TOOLTIP 'Informe a cubagem'
*/
   @ 575,285 SAY oLabel22 CAPTION "Apólice Nº"  TRANSPARENT SIZE 80,21  
   @ 575,306 GET oAPOLICE VAR nAPOLICE SIZE 214,24  PICTURE '@!' MAXLENGTH 20  ; 
             TOOLTIP 'Informe o número da apólice'

   @ 796,285 SAY oLabel23 CAPTION "Nº Averbação"  TRANSPARENT SIZE 80,21  
   @ 796,306 GET oAVERBACAO VAR cAVERBACAO SIZE 214,24  PICTURE '@!' MAXLENGTH 20  ; 
             TOOLTIP 'Informe o número da averbação'

   @ 007,336 SAY oLabel24 CAPTION "Nome da Seguradora"  TRANSPARENT SIZE 125,21  
   @ 007,356 GET oNOM_SEGURADORA VAR cNOM_SEGURADORA SIZE 450,24  PICTURE '@!' MAXLENGTH 30  ; 
             TOOLTIP 'Informe o nome da seguradora'

   @ 464,336 SAY oLabel25 CAPTION "Outras Caracteristicas"  TRANSPARENT SIZE 133,21  
   @ 464,356 GET oOUT_CARACTERISTICAS VAR cOUT_CARACTERISTICAS SIZE 546,24  PICTURE '@!' MAXLENGTH 40  ; 
             TOOLTIP 'Informe outras caracteristicas'

   
   @ 002,388 TAB oPage2 ITEMS {} SIZE 1013,194
   BEGIN PAGE 'Prestação de Serviço' OF oPage2 
      @ 004,30 BROWSE oBr1 ARRAY SIZE 1005,129 STYLE WS_TABSTOP;
               ON INIT{|| IF(LEN(oBr1:aArray)=1 .AND. oBr1:aArray[1,2]='DELETA',ADEL(oBr1:aArray,1,.T.),.T.), ::uiCalcula_totais(oDlg) };
               ON CLICK{|| ::uiCad_prest_servico(oDlg,'A'), ::uiCalcula_totais(oDlg)  }
                      oBr1:lESC := .T.
                      oBr1:aArray := aITN_SERV
                      CreateArList( oBr1, aITN_SERV )

                      oBr1:aColumns[1]:heading := 'Código'
                      oBr1:aColumns[2]:heading := 'Descrição'
                      oBr1:aColumns[3]:heading := 'Quantidade'
                      oBr1:aColumns[4]:heading := 'Valor'
                      
                      oBr1:aColumns[1]:length := 10
                      oBr1:aColumns[2]:length := 60
                      oBr1:aColumns[3]:length := 15
                      oBr1:aColumns[4]:length := 15
                      
                      oBr1:aColumns[1]:picture:='@!'
                      oBr1:aColumns[2]:picture:='@!'
                      oBr1:aColumns[3]:picture:='@E 999,999.999'
                      oBr1:aColumns[4]:picture:='@E 999,999,999.99'

      @ 004,160 BUTTONEX oButtonex3 CAPTION "&Incluir"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{|| ::uiCad_prest_servico(oDlg,'C'), ::uiCalcula_totais(oDlg)  }

      @ 101,160 BUTTONEX oButtonex4 CAPTION "&Alterar"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP;
                ON CLICK{|| ::uiCad_prest_servico(oDlg,'A'), ::uiCalcula_totais(oDlg)  }
                
      @ 198,160 BUTTONEX oButtonex5 CAPTION "&Remover"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{|| ::uiDel_prest_servico(oDlg), ::uiCalcula_totais(oDlg)  }
   END PAGE OF oPage2
   BEGIN PAGE 'Impostos' OF oPage2 
      @ 005,037 SAY oLabel26 CAPTION "Tipo da Tributação:"  TRANSPARENT SIZE 113,21  
      @ 120,034 GET COMBOBOX oTIP_TRIBUTACAO VAR cTIP_TRIBUTACAO  ITEMS {'00-ICMS Normal', '20-Reduçao de BC','40-ICMS Isenção','45-Isento, não tributado ou diferido','51-ICMS diferido','60-Cobrado por substituição tributária', '90-Outros', '90-Outras UF','99-Simples Nascional'} SIZE 229,24 TEXT STYLE IF(lCCe,WS_DISABLED,0);
                TOOLTIP 'Selecione o tipo de tributação'

      @ 005,070 SAY oLabel27 CAPTION "Base de Cálculo:"  TRANSPARENT SIZE 102,21  
      @ 120,067 GET oBASE_CALCULO VAR nBASE_CALCULO SIZE 145,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o valor da base de cálculo'

      @ 005,100 SAY oLabel28 CAPTION "% Aliquota ICMS:"  TRANSPARENT SIZE 106,21  
      @ 120,097 GET oPER_ALIQ_ICMS VAR nPER_ALIQ_ICMS SIZE 145,24  PICTURE '@E 999.99' MAXLENGTH 5 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o percentual da aliquota de ICMS'

      @ 005,131 SAY oLabel29 CAPTION "Valor ICMS:"  TRANSPARENT SIZE 80,21  
      @ 120,128 GET oVAL_ICMS VAR nVAL_ICMS SIZE 145,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o valor do ICMS'

      @ 005,162 SAY oLabel30 CAPTION "% Redução BC:"  TRANSPARENT SIZE 98,21  
      @ 120,159 GET oPER_RED_BC VAR nPER_RED_BC SIZE 145,24  PICTURE '@E 999.99' MAXLENGTH 5 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o percentual da redução da base de calculo'

      @ 355,070 SAY oLabel31 CAPTION "Valor BC ST Retida:"  TRANSPARENT SIZE 120,21  
      @ 477,067 GET oVAL_BC_ST_RET VAR nVAL_BC_ST_RET SIZE 145,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o valor da base de calculo de substituição tributária retida'

      @ 341,100 SAY oLabel32 CAPTION "Valor ICMS ST Retida:"  TRANSPARENT SIZE 134,21  
      @ 477,097 GET oVAL_ICMS_ST_RET VAR nVAL_ICMS_ST_RET SIZE 145,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o valor do icms da substituição tributária retida'

      @ 307,131 SAY oLabel33 CAPTION "% Aliq. ICMS BC ST Retida:"  TRANSPARENT SIZE 168,21  
      @ 476,128 GET oPER_ALI_BC_ST_RET VAR nPER_ALI_BC_ST_RET SIZE 145,24  PICTURE '@E 999.99' MAXLENGTH 5 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o percentual de icms da base de calculo de substituição tributária retida'

      @ 270,162 SAY oLabel34 CAPTION "Valor crédito outorgado/presumido:"  TRANSPARENT SIZE 205,21  
      @ 476,159 GET oVAL_CRE_OUT VAR nVAL_CRE_OUT SIZE 145,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o valor de credito outorgado / presumido'

      @ 632,070 SAY oLabel35 CAPTION "% Aliquota de redução BC Outras UF:"  TRANSPARENT SIZE 224,21  
      @ 859,067 GET oPER_RED_BC_OUT_UF VAR nPER_RED_BC_OUT_UF SIZE 145,24  PICTURE '@E 999.99' MAXLENGTH 5 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o percentual da redução de base de calculo de outras UFs'

      @ 689,100 SAY oLabel36 CAPTION "Valor da BC ICMS outra UF:"  TRANSPARENT SIZE 167,21  
      @ 859,097 GET oVAL_BC_ICMS_OUT_UF VAR nVAL_BC_ICMS_OUT_UF SIZE 145,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o valor da base de calculo de ICMS para outras UFs'

      @ 678,131 SAY oLabel37 CAPTION "% Aliquota do ICMS outra UF:"  TRANSPARENT SIZE 178,21  
      @ 859,128 GET oPER_ALI_ICMS_OUT_UF VAR nPER_ALI_ICMS_OUT_UF SIZE 145,24  PICTURE '@E 999.99' MAXLENGTH 5 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o percentual da aliquota de ICMS para outroas UFs'

      @ 671,162 SAY oLabel38 CAPTION "Valor do ICMS devido outra UF:"  TRANSPARENT SIZE 185,21  
      @ 859,159 GET oVAL_ICMS_DEV_OUT_UF VAR nVAL_ICMS_DEV_OUT_UF SIZE 145,24  PICTURE '@E 999,999,999.99' MAXLENGTH 12 STYLE IF(lCCe,WS_DISABLED,0); 
                TOOLTIP 'Informe o valor do ICMS devido de outras UFs'
   END PAGE OF oPage2
   BEGIN PAGE 'Documentos Originários' OF oPage2 
      @ 004,030 BROWSE oBr2 ARRAY SIZE 1005,129 STYLE WS_TABSTOP FONT HFont():Add( '',0,-11,400,,,);
                ON INIT{|| IF(LEN(oBr2:aArray)=1 .AND. oBr2:aArray[1,1]='DELETA',ADEL(oBr2:aArray,1,.T.),.T.) };
                ON CLICK{||  ::uiCad_doc_orig(oDlg,'A',NIL,lCCe) }
                       oBr2:lESC := .T.
                       oBr2:aArray := aDOCS
                       CreateArList( oBr2, aDOCS )
      
                       oBr2:aColumns[01]:heading := 'Tipo'
                       oBr2:aColumns[02]:heading := 'Modelo'
                       oBr2:aColumns[03]:heading := 'Série'
                       oBr2:aColumns[04]:heading := 'Número'
                       oBr2:aColumns[05]:heading := 'Emissão'
                       oBr2:aColumns[06]:heading := 'R$ BC'
                       oBr2:aColumns[07]:heading := 'R$ ICMS'
                       oBr2:aColumns[08]:heading := 'R$ BC. ST.'
                       oBr2:aColumns[09]:heading := 'R$ ST.'
                       oBr2:aColumns[10]:heading := 'R$ Produtos'
                       oBr2:aColumns[11]:heading := 'R$ Documento'
                       oBr2:aColumns[12]:heading := 'CFOP'
                       oBr2:aColumns[13]:heading := 'CFOP'
                       oBr2:aColumns[14]:heading := 'Peso (kg)'
                       oBr2:aColumns[15]:heading := 'Chave NF-e'
                       oBr2:aColumns[16]:heading := 'Outros'
                       
                       oBr2:aColumns[01]:length := 06
                       oBr2:aColumns[02]:length := 10
                       oBr2:aColumns[03]:length := 03
                       oBr2:aColumns[04]:length := 10
                       oBr2:aColumns[05]:length := 10
                       oBr2:aColumns[06]:length := 12
                       oBr2:aColumns[07]:length := 12
                       oBr2:aColumns[08]:length := 12
                       oBr2:aColumns[09]:length := 12
                       oBr2:aColumns[10]:length := 12
                       oBr2:aColumns[11]:length := 12
                       oBr2:aColumns[12]:length := 04
                       oBr2:aColumns[13]:length := 10
                       oBr2:aColumns[14]:length := 12
                       oBr2:aColumns[15]:length := 44
                       oBr2:aColumns[16]:length := 60
                       
                       oBr2:aColumns[01]:picture:='@!'
                       oBr2:aColumns[02]:picture:='@!'
                       oBr2:aColumns[03]:picture:='@!'
                       oBr2:aColumns[04]:picture:='9999999999'
                       oBr2:aColumns[05]:picture:='@D'
                       oBr2:aColumns[06]:picture:='@E 999,999,999.99'
                       oBr2:aColumns[07]:picture:='@E 999,999,999.99'
                       oBr2:aColumns[08]:picture:='@E 999,999,999.99'
                       oBr2:aColumns[09]:picture:='@E 999,999,999.99'
                       oBr2:aColumns[10]:picture:='@E 999,999,999.99'
                       oBr2:aColumns[11]:picture:='@E 999,999,999.99'
                       oBr2:aColumns[12]:picture:='@E 999,999,999.99'
                       oBr2:aColumns[13]:picture:='9999'
                       oBr2:aColumns[14]:picture:='@!'
                       oBr2:aColumns[15]:picture:='@R 9999.9999.9999.9999.9999.9999.9999.9999.9999.9999.9999'
                       oBr2:aColumns[16]:picture:='@!'

      @ 004,160 BUTTONEX oButtonex6 CAPTION "&Incluir"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{||  ::uiCad_doc_orig(oDlg,'C',NIL,lCCe) }
                
      @ 101,160 BUTTONEX oButtonex7 CAPTION "&Alterar"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP;
                ON CLICK{||  ::uiCad_doc_orig(oDlg,'A',NIL,lCCe) }
                
      @ 198,160 BUTTONEX oButtonex8 CAPTION "&Remover"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{||  ::uiDel_doc_orig(oDlg) }

   END PAGE OF oPage2
   BEGIN PAGE 'Carga' OF oPage2
      @ 005,039 SAY oLabel39 CAPTION "RNTRC/ANTT da Empresa:"  TRANSPARENT SIZE 160,21  
      @ 165,036 GET oRNTRC VAR cRNTRC SIZE 166,24  PICTURE '@!' MAXLENGTH 10  ; 
                TOOLTIP 'Informe o RNTRC da empresa'

      // Marco Barcelos, 14/03/2014
      *@ 005,069 GET CHECKBOX oLOTACAO VAR lLOTACAO CAPTION "Lotação"  TRANSPARENT SIZE 74,22  ;
      *          TOOLTIP 'Ativar esta opção caso a lotação da carga seja desta CT'

      @ 005,070 SAY oLabel40 CAPTION "Data prevista entrega:"  TRANSPARENT SIZE 129,21
      @ 138,067 GET DATEPICKER oENTREGa VAR dENTREGa SIZE 98,24  ;
                TOOLTIP 'Informe a data prevista da entrega'
                
      @ 005,101 SAY 'Forma de pagamento:' TRANSPARENT SIZE 136,021
      @ 135,098 GET COMBOBOX oFOR_PGT VAR cFOR_PGT ITEMS {'0-Pago','1-À pagar','2-Outros'} TEXT SIZE 125,024            

      @ 345,029 CONTAINER oContainer1 SIZE 2,160 STYLE 3 BACKSTYLE 2
      
      @ 355,039 SAY 'Espécie: ' SIZE 60,21 TRANSPARENT
      @ 414,036 GET oESPECIE VAR cESPECIE SIZE 180,22 MAXLENGTH 20 STYLE IF(lCCe,WS_DISABLED,0);
                TOOLTIP 'Informe a espécie'
                
      @ 616,039 SAY 'Placa: ' SIZE 60,21 TRANSPARENT
      @ 659,036 GET oPLACA VAR cPLACA SIZE 100,22 PICTURE '@R XXX-9999' STYLE IF(lCCe,WS_DISABLED,0);
                TOOLTIP 'Informe a placa do veículo'
      
      @ 780,039 SAY 'Valor do frete:' SIZE 120,21 TRANSPARENT
      @ 867,036 GET oVAL_FRETE VAR nVAL_FRETE SIZE 120,22 PICTURE '@E 999,999,999.99' STYLE IF(lCCe,WS_DISABLED,0);
                TOOLTIP 'Informe o valor do frete'
      /*
      @ 355,070 SAY 'Valor pedágio:' SIZE 120,21 TRANSPARENT
      @ 442,067 GET oVAL_PEDAGIO VAR nVAL_PEDAGIO SIZE 120,22 PICTURE '@E 999,999,999.99' STYLE IF(lCCe,WS_DISABLED,0);
                TOOLTIP 'Informe o valor do pedágio'
*/
      @ 580,070 SAY 'Valor outros:' SIZE 120,21 TRANSPARENT
      @ 659,067 GET oVAL_OUTROS VAR nVAL_OUTROS SIZE 120,22 PICTURE '@E 999,999,999.99' STYLE IF(lCCe,WS_DISABLED,0);
                TOOLTIP 'Informe outros valores'

   END PAGE OF oPage2
   
   BEGIN PAGE 'Pedágio' OF oPage2
      @ 004,030 BROWSE oBr5 ARRAY SIZE 1005,129 STYLE WS_TABSTOP FONT HFont():Add( '',0,-11,400,,,);
                ON INIT{|| IF(LEN(oBr5:aArray)=1 .AND. oBr5:aArray[1,2]='DELETA',ADEL(oBr5:aArray,1,.T.),.T.) };
                ON CLICK{|| ::uiCad_pedagio(oDlg,'A') }
                       oBr5:lESC := .T.
                       oBr5:aArray := aPEDAGIO
                       CreateArList( oBr5, aPEDAGIO )

                       oBr5:aColumns[1]:heading := 'Código'
                       oBr5:aColumns[2]:heading := 'Fornecedor'
                       oBr5:aColumns[3]:heading := 'Comprovante'
                       oBr5:aColumns[4]:heading := 'Código'
                       oBr5:aColumns[5]:heading := 'Responsável'
                       oBr5:aColumns[6]:heading := 'R$ Valor'

                       oBr5:aColumns[1]:length := 10
                       oBr5:aColumns[2]:length := 40
                       oBr5:aColumns[3]:length := 20
                       oBr5:aColumns[4]:length := 10
                       oBr5:aColumns[5]:length := 40
                       oBr5:aColumns[6]:length := 15

                       oBr5:aColumns[1]:picture:='9999999999'
                       oBr5:aColumns[2]:picture:='@!'
                       oBr5:aColumns[3]:picture:='@!'
                       oBr5:aColumns[4]:picture:='9999999999'
                       oBr5:aColumns[5]:picture:='@!'
                       oBr5:aColumns[6]:picture:='@E 999,999,999.99'

                       oBr5:DelColumn( 7 )
                       oBr5:DelColumn( 8 )

      @ 004,160 BUTTONEX oButtonex17 CAPTION "&Incluir"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{|| ::uiCad_pedagio(oDlg,'C') }
                
      @ 101,160 BUTTONEX oButtonex18 CAPTION "&Alterar"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP;
                ON CLICK{|| ::uiCad_pedagio(oDlg,'A') }
                
      @ 198,160 BUTTONEX oButtonex19 CAPTION "&Remover"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{|| ::uiDel_pedagio(oDlg) }

   END PAGE OF oPage2

   // Marco Barcelos, 14/03/2014
   BEGIN PAGE 'Lotação' OF oPage2

      @ 004,30 BROWSE oBr4 ARRAY SIZE 1005,129 STYLE WS_TABSTOP  FONT HFont():Add( '',0,-11,400,,,);
               ON INIT{|| IF(LEN(oBr4:aArray)=1 .AND. oBr4:aArray[1,2]='DELETA',ADEL(oBr4:aArray,1,.T.),.T.) };
               ON CLICK{|| ::uiCadLota(oDlg,'A',nCTE_ID)  }
      oBr4:aArray := aLotacao
      CreateArList( oBr4, aLotacao )

      oBr4:aColumns[01]:heading := 'Código'
      oBr4:aColumns[02]:heading := 'RENAVAM'
      oBr4:aColumns[03]:heading := 'Placa'
      oBr4:aColumns[04]:heading := 'Tara'
      oBr4:aColumns[05]:heading := 'Capacidade KG'
      oBr4:aColumns[06]:heading := 'Capacidade M3'
      oBr4:aColumns[07]:heading := 'Tipo Propriedade'
      oBr4:aColumns[08]:heading := 'Tipo Veículo'
      oBr4:aColumns[09]:heading := 'Tipo rodado'
      oBr4:aColumns[10]:heading := 'Tipo carroceria'
      oBr4:aColumns[11]:heading := 'UF Licenciamento'

      oBr4:aColumns[01]:length := 10
      oBr4:aColumns[02]:length := 11
      oBr4:aColumns[03]:length := 07
      oBr4:aColumns[04]:length := 06
      oBr4:aColumns[05]:length := 06
      oBr4:aColumns[06]:length := 03
      oBr4:aColumns[07]:length := 01
      oBr4:aColumns[08]:length := 02
      oBr4:aColumns[09]:length := 02
      oBr4:aColumns[10]:length := 02
      oBr4:aColumns[11]:length := 02

      oBr4:aColumns[01]:picture:='@!'
      oBr4:aColumns[02]:picture:='@!'
      oBr4:aColumns[03]:picture:='@R XXX-9999'
      oBr4:aColumns[04]:picture:='@E 999999'
      oBr4:aColumns[05]:picture:='@E 999999'
      oBr4:aColumns[06]:picture:='@E 999'
      oBr4:aColumns[07]:picture:='@!'
      oBr4:aColumns[08]:picture:='@E 9'
      oBr4:aColumns[09]:picture:='@E 99'
      oBr4:aColumns[10]:picture:='@E 99'
      oBr4:aColumns[11]:picture:='@!'

      @ 004,160 BUTTONEX oButtonex14 CAPTION "&Incluir"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{|| ::uiCadLota(oDlg,'C',nCTE_ID)  }

      @ 101,160 BUTTONEX oButtonex15 CAPTION "&Alterar"   SIZE 98,32 STYLE BS_CENTER+WS_TABSTOP;
                ON CLICK{|| ::uiCadLota(oDlg,'A',nCTE_ID)  }

      @ 198,160 BUTTONEX oButtonex16 CAPTION "&Remover"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP+IF(lCCe,WS_DISABLED,0);
                ON CLICK{|| ::uiDelLota(oDlg) }

   END PAGE OF oPage2

   BEGIN PAGE 'Cobrança' OF oPage2
      @ 005,039 SAY 'Forma de Cobrança: ' SIZE 120,21 TRANSPARENT
      @ 127,036 GET oCOD_PRAZO VAR nCOD_PRAZO SIZE 80,22 PICTURE '9999999999' STYLE IF(lCCe,WS_DISABLED,0);
                VALID{|| IF(nCOD_PRAZO>0, ::oCTe_GERAIS:rgPegaPrazo(cDES_PRAZO,oCOD_PRAZO,oDES_PRAZO) ,.T.) };
                TOOLTIP 'Informe o código do prazo de pagamento ou deixe vazio para informar a descrição.'
      
      @ 209,036 GET oDES_PRAZO VAR cDES_PRAZO SIZE 360,22 PICTURE '@!' STYLE IF(lCCe,WS_DISABLED,0);
                VALID{|| IF(nCOD_PRAZO<=0, ::oCTe_GERAIS:rgPegaPrazo(cDES_PRAZO,oCOD_PRAZO,oDES_PRAZO) ,.T.) };
                TOOLTIP 'Informe a descrição do prazo de pagamento ou deixe vazio para a lista.'

      @ 570,036 OWNERBUTTON oOwnerbutton5  SIZE 24,24 FLAT STYLE IF(lCCe,WS_DISABLED,0);
                ON CLICK {|| nCOD_PRAZO:=0, cDES_PRAZO:='', ::oCTe_GERAIS:rgPegaPrazo(cDES_PRAZO,oCOD_PRAZO,oDES_PRAZO) };
                BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
                TOOLTIP 'Localizar um prazo de pagamento'

      @ 005,070 SAY 'Frete por conta:' SIZE 110,21 TRANSPARENT
      @ 110,067 GET COMBOBOX oFRT_CONTA VAR cFRT_CONTA ITEMS {'Remetente','Destinatário'} SIZE 136,24 TEXT STYLE IF(lCCe,WS_DISABLED,0);
                TOOLTIP 'Selecione por quem ficará a responsabilidade do frete'

   END PAGE OF oPage2
   BEGIN PAGE 'Complementado' OF oPage2 
      @ 005,039 SAY 'Chave do CT-e Complementado: ' SIZE 50,22 TRANSPARENT
      @ 005,065 GET oCTE_COMPLE VAR cCTE_COMPLE SIZE 400,24 PICTURE '@R 9999.9999.9999.9999.9999.9999.9999.9999.9999.9999.9999'
      
      @ 407,065 OWNERBUTTON SIZE 24,24 FLAT;
          ON CLICK {|| ::uiPegaChaveCteComple(oCTE_COMPLE) };
          BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
          TOOLTIP 'Localizar uma CT-e'
   END PAGE OF oPage2
   BEGIN PAGE 'Observações' OF oPage2 
      @ 004,030 GET oOBS VAR cOBS SIZE 1005,160  PICTURE '@!';
                STYLE ES_MULTILINE+ES_AUTOVSCROLL+WS_VSCROLL+ES_WANTRETURN
   END PAGE OF oPage2

   @ 359,591 SAY oLabel41 CAPTION "Total Serviço:"  TRANSPARENT SIZE 80,21
   @ 438,589 GET oTOT_SERVICO VAR nTOT_SERVICO SIZE 140,24 ;
             STYLE WS_DISABLED  PICTURE '@E 999,999,999.99'  

   @ 607,592 SAY oLabel42 CAPTION "Total:"  TRANSPARENT SIZE 36,21  
   @ 642,589 GET oTOTAL VAR nTOTAL SIZE 140,24 ;
             STYLE WS_DISABLED  PICTURE '@E 999,999,999.99'  

   @ 806,592 SAY oLabel43 CAPTION "Total Itens:"  TRANSPARENT SIZE 65,21  
   @ 874,589 GET oTOT_ITENS VAR nTOT_ITENS SIZE 140,24 ;
             STYLE WS_DISABLED  PICTURE '@E 999,999,999.99'  
END PAGE OF oPage1
BEGIN PAGE 'Anexos' OF oPage1
      @ 004,030 BROWSE oBr3 ARRAY SIZE 1005,550 STYLE WS_TABSTOP FONT HFont():Add( '',0,-11,400,,,);
                ON INIT{|| ::uiCarregaAnexos(oDlg,nCTE_ID) };
                ON CLICK{|| ::uiAbreArquivoCTe(oDlg,nCTE_ID) }
                       oBr3:lESC := .T.
                       oBr3:aArray := {{'DELETA','DELETA',''}}
                       CreateArList( oBr3, {{'DELETA','DELETA',''}} )
      
                       oBr3:aColumns[1]:heading := 'Tipo'
                       oBr3:aColumns[2]:heading := 'Arquivo'

                       oBr3:aColumns[1]:length := 20
                       oBr3:aColumns[2]:length := 100

                       oBr3:aColumns[1]:picture:='@!'
                       oBr3:aColumns[2]:picture:='@!'
                       
                       oBr3:DelColumn( 3 )

   @ 004,580 BUTTONEX oButtonex10 CAPTION "&Incluir"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP;
             ON CLICK{|| ::uiIncluiArquivoCTe(oDlg,nCTE_ID) }

   @ 102,580 BUTTONEX oButtonex11 CAPTION "&Excluir"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP;
             ON CLICK{|| ::uiExcluiArquivoCTe(oDlg,nCTE_ID) }

   @ 200,580 BUTTONEX oButtonex12 CAPTION "&Abrir"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP;
             ON CLICK{|| ::uiAbreArquivoCTe(oDlg,nCTE_ID) }

   @ 298,580 BUTTONEX oButtonex13 CAPTION "&Exportar"   SIZE 98,32 STYLE BS_CENTER +WS_TABSTOP;
             ON CLICK{|| ::uiExportaArquivoCTe(oDlg,nCTE_ID) }

END PAGE OF oPage1

@ 778,622 BUTTONEX oButtonex1 CAPTION "&Salvar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
          ON CLICK{|| ::uiSalva_cte(oDlg,nCTE_ID,oOBJ,lCCe) }

@ 898,622 BUTTONEX oButtonex2 CAPTION "&Fechar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| oDlg:CLOSE() }

ADD STATUS oSta TO oDlg 
ACTIVATE DIALOG oDlg 

RETURN(.T.)


Method uiCarregaAnexos(oOBJ,nCTE_ID) Class oCTe_HWgui
/*
   Carrega os anexos para a browse
   Mauricio Cruz - 02/09/2013
*/
LOCAL aSQL:={}

WITH OBJECT oOBJ:oPage1
   ::oCTe_GERAIS:rgExecuta_Sql('select anexo_tipo, '+;
                               '       anexo_nome, '+;
                               '       anexo_arquivo '+;
                               '  from sagi_cte_anexo '+;
                               ' where anexo_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)

   :oBr3:aArray := aSQL
   CreateArList( :oBr3, aSQL )
   :oBr3:REFRESH()
END

RETURN(.T.)


Method uiIncluiArquivoCTe(oOBJ,nCTE_ID) Class oCTe_HWgui
/*
   Inclui um arquivo para uma CTe
   Mauricio Cruz - 02/09/2013
*/
LOCAL oDlg, oGroup1, oTIP, oButtonex1, oSta
LOCAL cTIP:='', cARQ:=::oCTe_GERAIS:rgPegaArquivo('*.*')
IF cARQ=NIL .OR. EMPTY(cARQ)
   RETURN(.F.)
ENDIF

INIT DIALOG oDlg TITLE "Tipo de arquivo" AT 000,000 SIZE 577,114 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_SYSMENU+WS_SIZEBOX ICON HIcon():AddResource(::nCte_Icont)

@ 002,000 GROUPBOX oGroup1 CAPTION "Informe uma descrição para o tipo de arquivo "+SUBSTR(cARQ,RAT('\',cARQ)+1,LEN(cARQ))  SIZE 573,49 STYLE BS_LEFT COLOR x_BLUE
                   oGroup1:Anchor := 15 

@ 006,018 GET oTIP VAR cTIP SIZE 562,24  PICTURE '@!';
          TOOLTIP 'Informe a descrição do tipo de arquivo'
          oTIP:Anchor := 15 

@ 454,050 BUTTONEX oButtonex1 CAPTION "&OK"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          ON CLICK{|| oDlg:CLOSE() }
          oButtonex1:Anchor := 12 

ADD STATUS oSta TO oDlg    
ACTIVATE DIALOG oDlg 

::oCTe_GERAIS:rgBeginTransaction()
::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_anexo(anexo_id_cte, '+;
                                                       'anexo_data, '+;
                                                       'anexo_hora, '+;
                                                       'anexo_nome, '+;
                                                       'anexo_arquivo, '+;
                                                       'anexo_usuario, '+;
                                                       'anexo_tipo) values('+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(DATE())+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(TIME())+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(SUBSTR(cARQ,RAT('\',cARQ)+1,LEN(cARQ)))+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(MaskBinData(MEMOREAD(cARQ)))+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(::cCte_Operador)+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(cTIP)+')')
::oCTe_GERAIS:rgEndTransaction()
::uiCarregaAnexos(oOBJ,nCTE_ID)
RETURN(.T.)


Method uiExcluiArquivoCTe(oOBJ,nCTE_ID)
/*
   exclui o arquivo anexado da CTe
   Mauricio Cruz - 02/09/2013
*/
WITH OBJECT oOBJ:oPage1:oBr3
   IF LEN(:aArray)<=0 .OR. !::oCTe_GERAIS:uiSN('Confirma a exclusão do arquivo selecionado ?')
      RETURN(.F.)
   ENDIF

   IF UPPER(RIGHT(ALLTRIM(:aArray[:nCurrent,2]),3))='XML'
      ::oCTe_GERAIS:uiAviso('Arquivos no formado XML não pode ser excluidos de sua CTe.')
      RETURN(.F.)
   ENDIF

   ::oCTe_GERAIS:rgBeginTransaction()
   ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte_anexo '+;
                               ' where anexo_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+;
                               '   and anexo_tipo='+::oCTe_GERAIS:rgConcat_sql(:aArray[:nCurrent,1])+;
                               '   and anexo_nome='+::oCTe_GERAIS:rgConcat_sql(:aArray[:nCurrent,2])+;
                               '   and anexo_arquivo='+::oCTe_GERAIS:rgConcat_sql(:aArray[:nCurrent,3]))
   ::oCTe_GERAIS:rgEndTransaction()
END
::uiCarregaAnexos(oOBJ,nCTE_ID)
RETURN(.T.)

Method uiAbreArquivoCTe(oOBJ,nCTE_ID) Class oCTe_HWgui
/*
   Abre o arqui da CTe
   Mauricio Cruz - 02/09/2013
*/
WITH OBJECT oOBJ:oPage1:oBr3
   IF LEN(:aArray)<=0
      RETURN(.F.)
   ENDIF
   
   IF FILE(::cPastaEnvRes+'\'+ALLTRIM(:aArray[:nCurrent,2]))
      FERASE(::cPastaEnvRes+'\'+ALLTRIM(:aArray[:nCurrent,2]))
   ENDIF

   IF MemoWrit( ::cPastaEnvRes+'\'+ALLTRIM(:aArray[:nCurrent,2]) , UnMaskBinData(:aArray[:nCurrent,3]), .F. )
      ::oCTe_GERAIS:rgAbreArquivo(::cPastaEnvRes+'\'+ALLTRIM(:aArray[:nCurrent,2]))
   ENDIF
END

RETURN(.T.)


Method uiExportaArquivoCTe(oOBJ,nCTE_ID) Class oCTe_HWgui
/*
   Exporta o arquivo selecionado da CTe
   Mauricio Cruz - 02/09/2013
*/
LOCAL cARQ:=''

WITH OBJECT oOBJ:oPage1:oBr3
   IF LEN(:aArray)<=0
      RETURN(.F.)
   ENDIF
   cARQ := SAVEFILE(ALLTRIM(:aArray[:nCurrent,2]),'*.*','todos Arquivos (*.*)')
   IF cARQ<>NIL .AND. !EMPTY(cARQ)
      MEMOWRIT(cARQ,UnMaskBinData(:aArray[:nCurrent,3]),.F.) 
   ENDIF
END

RETURN(.T.)

Method uiImporta_NF(oOBJ,lCCe) Class oCTe_HWgui
/*
   localizar uma nota fiscal e atualiza a tela com os dados da NF
   Mauricio Cruz - 19/08/2013
*/
LOCAL cCNPJ_REMENTENTE:=''
LOCAL aSQL:={}
LOCAL cFILIAL_ATUAL:=_FILIAL()
LOCAL hNNF:=LISTA_NF('PESQ',NIL,.T.)

IF hNNF['NNF']<=0 .OR. EMPTY(hNNF['EMPRESA'])
   RETURN(.F.)
ENDIF

IF hNNF['ORDEM']>0 .OR. hNNF['TIPNF']<>'SAIDA'
   ::oCTe_GERAIS:uiAviso('Favor selecionar uma nota fiscal própria de saida')
   RETURN(.F.)
ENDIF

pcEMPRESA:=hNNF['EMPRESA']
REGISTROS(::nCOD_FIXA_EMP)
cCNPJ_REMENTENTE:=STRTRAN(STRTRAN(STRTRAN(eCGC,'-'),'/'),'.')
pcEMPRESA:=cFILIAL_ATUAL
REGISTROS(::nCOD_FIXA_EMP)

::oCTe_GERAIS:rgExecuta_Sql('select codcli, '+;
                            '       cliente '+;
                            '  from cag_cli '+;
                            ' where cgc='+::oCTe_GERAIS:rgConcat_sql(cCNPJ_REMENTENTE),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não foi possível localizar os dados do remente.')
ELSE
   WITH OBJECT oOBJ:oPage1:oPage3
      :oCOD_CLIENTE:SETTEXT(aSQL[1,1])
      :oCOD_CLIENTE:REFRESH()
      
      :oNOM_CLIENTE:SETTEXT(aSQL[1,2])
      :oNOM_CLIENTE:REFRESH()
   END
ENDIF

::oCTe_GERAIS:rgExecuta_Sql('select a.codcli, '+;
                            '       b.cliente, '+;
                            '       a.produto, '+;
                            '       (select sum(x.total) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs), '+;
                            '       (select sum(x.liquido) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs), '+;
                            '       a.placa, '+;
                            '       a.codtransp, '+;
                            '       c.nome, '+;
                            '       d.ativo_trans_rntrc '+;
                            '  from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' a '+;
                            '  left join cag_cli b on b.codcli=a.codcli '+;
                            '  left join transp c on c.codigo=a.codtransp '+;
                            '  left join sagi_cad_ativo d on d.ativo_placa=a.placa '+;
                            ' where a.nffs='+::oCTe_GERAIS:rgConcat_sql(hNNF['NNF'])+;
                            '   and a.serie='+::oCTe_GERAIS:rgConcat_sql(hNNF['SER'])+;
                            '   and a.modnot='+::oCTe_GERAIS:rgConcat_sql(hNNF['MOD'])+;
                            ' limit 1 ',,,@aSQL)

IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não foi possível localizar os dados da nota fiscal desejada.')
   RETURN(.F.)
ENDIF

WITH OBJECT oOBJ:oPage1
   WITH OBJECT :oPage3
      :oCOD_DESTINATARIO:SETTEXT(aSQL[1,1])
      :oCOD_DESTINATARIO:REFRESH()
      
      :oNOM_DESTINATARIO:SETTEXT(aSQL[1,2])
      :oNOM_DESTINATARIO:REFRESH()
      
      :oCOD_EXPEDIDOR:SETTEXT(aSQL[1,7])
      :oCOD_EXPEDIDOR:REFRESH()

      :oNOM_EXPEDIDOR:SETTEXT(aSQL[1,8])
      :oNOM_EXPEDIDOR:REFRESH()

      :oCOD_RECEBEDOR:SETTEXT(aSQL[1,1])
      :oCOD_RECEBEDOR:REFRESH()
      
      :oNOM_RECEBEDOR:SETTEXT(aSQL[1,2])
      :oNOM_RECEBEDOR:REFRESH()
   END
   
   :oPRODUTO:SETTEXT(LEFT(aSQL[1,3],40))
   :oPRODUTO:REFRESH()

   :oVAL_MERCADORIA:SETTEXT(aSQL[1,4])
   :oVAL_MERCADORIA:REFRESH()
   
   :oPESO_BRUTO:SETTEXT(aSQL[1,5])
   :oPESO_BRUTO:REFRESH()
   
   WITH OBJECT :oPage2
      :oRNTRC:SETTEXT( LEFT(aSQL[1,9],10) )
      :oRNTRC:REFRESH()

      :oPLACA:SETTEXT(aSQL[1,6])
      :oPLACA:REFRESH()
   END

   :oButtonex9:DISABLE()
END


::uiCad_doc_orig(oOBJ,'C',hNNF,lCCe)

RETURN(.T.)


Method uiAtualiza_estado_municipio(oOBJ) Class oCTe_HWgui
/*
   Atualiza as informações da estado e municipio
   Mauricio Cruz - 15/08/2013
*/
LOCAL aSQL:={}

WITH OBJECT oOBJ:oPage1
   IF :oPage3:oCOD_CLIENTE:VARGET()>0
      ::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_CLIENTE['uf']+', '+;
                                  '       '+::tCte_CLIENTE['cidade']+;
                                  '  from '+::tCte_CLIENTE['cag_cli']+;
                                  ' where '+::tCte_CLIENTE['codcli']+'='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_CLIENTE:VARGET())+;
                                  "   and trim(coalesce("+::tCte_CLIENTE['uf']+",''))<>''"+;
                                  "   and trim(coalesce("+::tCte_CLIENTE['cidade']+",''))<>''",,,@aSQL)

      IF LEN(aSQL)>0
         :oUF_ORIGEM:Setitem(ASCAN(:oUF_ORIGEM:aItems,aSQL[1,1]))
         :oUF_ORIGEM:SETTEXT(ALLTRIM(aSQL[1,1]))
         :oUF_ORIGEM:REFRESH()
         ::oCTe_GERAIS:rgRecarrega_combo_uf(aSQL[1,1],:oCIDADE_ORIGEM)
         :oCIDADE_ORIGEM:Setitem(ASCAN(:oCIDADE_ORIGEM:aItems,aSQL[1,2]))
         :oCIDADE_ORIGEM:SETTEXT(aSQL[1,2])
         :oCIDADE_ORIGEM:REFRESH()
      ENDIF
      
      //:oPage3:oCOD_EXPEDIDOR:SETTEXT(:oPage3:oCOD_CLIENTE:VARGET())
      //:oPage3:oCOD_EXPEDIDOR:REFRESH()

      //:oPage3:oNOM_EXPEDIDOR:SETTEXT(:oPage3:oNOM_CLIENTE:VARGET())
      //:oPage3:oNOM_EXPEDIDOR:REFRESH()
   ENDIF
   IF :oPage3:oCOD_DESTINATARIO:VARGET()>0
      ::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_CLIENTE['uf']+', '+;
                                  '       '+::tCte_CLIENTE['cidade']+;
                                  '  from '+::tCte_CLIENTE['cag_cli']+;
                                  ' where '+::tCte_CLIENTE['codcli']+'='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_DESTINATARIO:VARGET())+;
                                  "   and trim(coalesce("+::tCte_CLIENTE['uf']+",''))<>''"+;
                                  "   and trim(coalesce("+::tCte_CLIENTE['cidade']+",''))<>''",,,@aSQL)
      IF LEN(aSQL)>0
         :oUF_DESTINO:Setitem(ASCAN(:oUF_DESTINO:aItems,aSQL[1,1]))
         :oUF_DESTINO:SETTEXT(aSQL[1,1])
         :oUF_DESTINO:REFRESH()
         ::oCTe_GERAIS:rgRecarrega_combo_uf(aSQL[1,1],:oCIDADE_DESTINO)
         :oCIDADE_DESTINO:Setitem(ASCAN(:oCIDADE_DESTINO:aItems,aSQL[1,2]))
         :oCIDADE_DESTINO:SETTEXT(aSQL[1,2])
         :oCIDADE_DESTINO:REFRESH()
      ENDIF
      
      :oPage3:oCOD_RECEBEDOR:SETTEXT(:oPage3:oCOD_DESTINATARIO:VARGET())
      :oPage3:oCOD_RECEBEDOR:REFRESH()

      :oPage3:oNOM_RECEBEDOR:SETTEXT(:oPage3:oNOM_DESTINATARIO:VARGET())
      :oPage3:oNOM_RECEBEDOR:REFRESH()
   ENDIF
END
RETURN(.T.)

Method uiSalva_cte(oOBJ,nCTE_ID,oOBJ2,lCCe) Class oCTe_HWgui
/*
   salva a CT-e
   Mauricio Cruz - 17/07/2013
*/
LOCAL nTOT_SERVICO:=0, mI:=0, nNUMCTE:=0, nTOTpedagio:=0
LOCAL aSQL:={}, cSQL := ''
LOCAL cOUT_CARACT:=''
LOCAL lTRANSMITIDO:=.F., lGERA_CTEAREC:=.F.

WITH OBJECT oOBJ:oPage1
   IF ::lCte_ELETRONICO .AND. LEFT(:oMODELO:GETTEXT(),2)<>'57'
      ::oCTe_GERAIS:uiAviso('O modelo da CTe não é eletrônico. Favor revisar.')
      RETURN(.F.)
   ENDIF

   IF :oCFOP:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('CFOP em branco ou negativo, não é possível gravar!')
      RETURN(.F.)
   ENDIF
   IF :oPage3:oCOD_CLIENTE:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Código do Remetente em branco ou negativo, não é possível gravar!')
      RETURN(.F.)
   ELSE
      ::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_CLIENTE['cliente']+', '+;
                                            ::tCte_CLIENTE['ende']   +', '+;
                                            ::tCte_CLIENTE['numende']+', '+;
                                            ::tCte_CLIENTE['bairro'] +', '+;
                                            ::tCte_CLIENTE['cidade'] +', '+;
                                            ::tCte_CLIENTE['cep']    +;
                                  '  from '+::tCte_CLIENTE['cag_cli']+;
                                  ' where '+::tCte_CLIENTE['codcli']+'='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_CLIENTE:VARGET()),,,@aSQL)
      IF LEN(aSQL)<=0
         ::oCTe_GERAIS:uiAviso('Não foi possível localizar o cliente informado no remetente')
         RETURN(.F.)
      ENDIF
      IF EMPTY(aSQL[1,1])
         ::oCTe_GERAIS:uiAviso('Nome do Remetente em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,2])
         ::oCTe_GERAIS:uiAviso('Endereço do Remetente em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,3])
         ::oCTe_GERAIS:uiAviso('Número do Endereço do Remetente em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,4])
         ::oCTe_GERAIS:uiAviso('Bairro do Remetente em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,5])
         ::oCTe_GERAIS:uiAviso('Cidade do Remetente em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,6])
         ::oCTe_GERAIS:uiAviso('CEP do Remetente em branco, Favor Revisar')
         RETURN(.F.)
      ENDIF
   ENDIF
   IF :oPage3:oCOD_DESTINATARIO:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Código do destinatário em branco ou negativo, não é possível gravar!')
      RETURN(.F.)
   ELSE
      ::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_CLIENTE['cliente']+', '+;
                                  '       '+::tCte_CLIENTE['ende']+', '+;
                                  '       '+::tCte_CLIENTE['numende']+', '+;
                                  '       '+::tCte_CLIENTE['bairro']+', '+;
                                  '       '+::tCte_CLIENTE['cidade']+', '+;
                                  '       '+::tCte_CLIENTE['cep']+;
                                  '  from '+::tCte_CLIENTE['cag_cli']+;
                                  ' where '+::tCte_CLIENTE['codcli']+'='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_DESTINATARIO:VARGET()),,,@aSQL)

      IF LEN(aSQL)<=0
         ::oCTe_GERAIS:uiAviso('Não foi possível localizar o cliente informado no destinatário')
         RETURN(.F.)
      ENDIF
      IF EMPTY(aSQL[1,1])
         ::oCTe_GERAIS:uiAviso('Nome do Destinatário em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,2])
         ::oCTe_GERAIS:uiAviso('Endereço do Destinatário em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,3])
         ::oCTe_GERAIS:uiAviso('Número do Endereço do Destinatário em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,4])
         ::oCTe_GERAIS:uiAviso('Bairro do Destinatário em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,5])
         ::oCTe_GERAIS:uiAviso('Cidade do Destinatário em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,6])
         ::oCTe_GERAIS:uiAviso('CEP do Destinatário em branco, Favor Revisar')
         RETURN(.F.)
      ENDIF
   ENDIF
   
   IF :oPage3:oCOD_EXPEDIDOR:VARGET()<=0
      //::oCTe_GERAIS:uiAviso('Código do expedidor em branco ou negativo, não é possível gravar!')
      //RETURN(.F.)
   ELSE
      ::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_TRANSP['nome']+', '+;
                                  '       '+::tCte_TRANSP['endereco']+', '+;
                                  '       '+::tCte_TRANSP['numende']+', '+;
                                  '       '+::tCte_TRANSP['bairro']+', '+;
                                  '       '+::tCte_TRANSP['cidade']+', '+;
                                  '       '+::tCte_TRANSP['cep']+;
                                  '  from '+::tCte_TRANSP['transp']+;
                                  ' where '+::tCte_TRANSP['codigo']+'='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_EXPEDIDOR:VARGET()),,,@aSQL)

      IF LEN(aSQL)<=0
         ::oCTe_GERAIS:uiAviso('Não foi possível localizar o cliente informado no expedidor')
         RETURN(.F.)
      ENDIF
      IF EMPTY(aSQL[1,1])
         ::oCTe_GERAIS:uiAviso('Nome do expedidor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,2])
         ::oCTe_GERAIS:uiAviso('Endereço do expedidor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,3])
         ::oCTe_GERAIS:uiAviso('Número do Endereço do expedidor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,4])
         ::oCTe_GERAIS:uiAviso('Bairro do expedidor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,5])
         ::oCTe_GERAIS:uiAviso('Cidade do expedidor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,6])
         ::oCTe_GERAIS:uiAviso('CEP do expedidor em branco, Favor Revisar')
         RETURN(.F.)
      ENDIF
   ENDIF
   
   IF :oPage3:oCOD_RECEBEDOR:VARGET()<=0
      //::oCTe_GERAIS:uiAviso('Código do recebedor em branco ou negativo, não é possível gravar!')
      //RETURN(.F.)
   ELSE
      ::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_CLIENTE['cliente']+', '+;
                                  '       '+::tCte_CLIENTE['ende']+', '+;
                                  '       '+::tCte_CLIENTE['numende']+', '+;
                                  '       '+::tCte_CLIENTE['bairro']+', '+;
                                  '       '+::tCte_CLIENTE['cidade']+', '+;
                                  '       '+::tCte_CLIENTE['cep']+;
                                  '  from '+::tCte_CLIENTE['cag_cli']+;
                                  ' where '+::tCte_CLIENTE['codcli']+'='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_RECEBEDOR:VARGET()),,,@aSQL)

      IF LEN(aSQL)<=0
         ::oCTe_GERAIS:uiAviso('Não foi possível localizar o cliente informado no recebedor')
         RETURN(.F.)
      ENDIF
      IF EMPTY(aSQL[1,1])
         ::oCTe_GERAIS:uiAviso('Nome do recebedor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,2])
         ::oCTe_GERAIS:uiAviso('Endereço do recebedor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,3])
         ::oCTe_GERAIS:uiAviso('Número do Endereço do recebedor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,4])
         ::oCTe_GERAIS:uiAviso('Bairro do recebedor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,5])
         ::oCTe_GERAIS:uiAviso('Cidade do recebedor em branco, Favor Revisar')
         RETURN(.F.)
      ELSEIF EMPTY(aSQL[1,6])
         ::oCTe_GERAIS:uiAviso('CEP do recebedor em branco, Favor Revisar')
         RETURN(.F.)
      ENDIF
   ENDIF
   
   IF EMPTY(:oPRODUTO:VARGET())
      ::oCTe_GERAIS:uiAviso('Produto predominante em branco, Favor Revisar!')
      :oPRODUTO:SETFOCUS()
      RETURN(.F.)
   ELSE
      IF LEN(:oPRODUTO:VARGET())>40
         ::oCTe_GERAIS:uiAviso('Descriçao do Produto não pode ultrapassar 40 caracter, favor revisar')
         :oPRODUTO:SETFOCUS()
         RETURN(.F.)
      ENDIF
   ENDIF

   IF LEFT(:oTIPO_CT:GETTEXT(),1)='0' .AND. :oVOLUMES:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Valor do(s) volumes em branco ou negativo, Favor Revisar!')
      :oVOLUMES:SETFOCUS()
      RETURN(.F.)
   ENDIF
   IF !EMPTY(:oAVERBACAO:VARGET()) .AND. :oVAL_AVERBACAO:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Valor da Averbação em branco ou negativo, Favor Revisar!')
      :oVAL_AVERBACAO:SETFOCUS()
      RETURN(.F.)
   ENDIF

   IF LEFT(:oTIPO_CT:GETTEXT(),1)='0' .AND. :oVAL_MERCADORIA:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Valor da mercadoria em branco ou negativo, Favor Revisar!')
      :oVAL_MERCADORIA:SETFOCUS()
      RETURN(.F.)
   ENDIF
   IF LEFT(:oTIPO_CT:GETTEXT(),1)='0' .AND. :oPESO_BRUTO:VARGET()<=0 
      ::oCTe_GERAIS:uiAviso('Valor do peso bruto em branco ou negativo, Favor Revisar!')
      :oPESO_BRUTO:SETFOCUS()
      RETURN(.F.)
   ENDIF
   IF EMPTY(:oNOM_SEGURADORA:VARGET())
      ::oCTe_GERAIS:uiAviso('Nome da Seguradora em branco, Favor Revisar')
      :oNOM_SEGURADORA:SETFOCUS()
      RETURN
   ENDIF
   IF EMPTY(:oOUT_CARACTERISTICAS:VARGET())
      ::oCTe_GERAIS:uiAviso('Outras Caracteristicas em branco, Favor Revisar')
      :oOUT_CARACTERISTICAS:SETFOCUS()
      RETURN
   ENDIF
   WITH OBJECT :oPage2
      IF LEFT(oOBJ:oPage1:oTIPO_CT:GETTEXT(),1)='0' .AND. LEN(:oBr1:aARRAY)<=0
         ::oCTe_GERAIS:uiAviso('Itens da prestação de serviços em branco, Favor Revisar!')
         RETURN(.F.)
      ENDIF      
      IF LEN(:oBr2:aARRAY)<=0
         ::oCTe_GERAIS:uiAviso('Documentos originários do CT em branco, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF EMPTY(:oRNTRC:VARGET())
         ::oCTe_GERAIS:uiAviso('RNTRC/ANTT em branco, Favor Revisar!')
         RETURN(.F.)
      ELSE
         IF LEN(ALLTRIM(:oRNTRC:VARGET())) < 8  .OR. LEN(ALLTRIM(:oRNTRC:VARGET())) > 10
            ::oCTe_GERAIS:uiAviso('RNTRC/ANTT Inválido, Favor Revisar')
            RETURN
         ENDIF
      ENDIF      
      IF :oBASE_CALCULO:VARGET() < 0
         ::oCTe_GERAIS:uiAviso('Valor do imposto na base de cálculo negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oPER_ALIQ_ICMS:VARGET()<0
         ::oCTe_GERAIS:uiAviso('Valor da aliquota negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oVAL_ICMS:VARGET()<0
         ::oCTe_GERAIS:uiAviso('Valor do ICMS negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oPER_RED_BC:VARGET()<0
         ::oCTe_GERAIS:uiAviso('Percentual do ICMS negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oVAL_BC_ST_RET:VARGET()<0
         ::oCTe_GERAIS:uiAviso('Valor da base de cálculo retida negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oVAL_ICMS_ST_RET:VARGET()<0
         ::oCTe_GERAIS:uiAviso('Valor do ICMS ST Retida negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oPER_ALI_BC_ST_RET:VARGET()<0
         ::oCTe_GERAIS:uiAviso('Percentual da aliquota ICMS Base Calc ST Retida negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oVAL_CRE_OUT:VARGET()<0
         ::oCTe_GERAIS:uiAviso('Valor crédito outorgado/presumido negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oPER_RED_BC_OUT_UF:VARGET() < 0
         ::oCTe_GERAIS:uiAviso('Percentual da aliquota de Redução BC Outra UF negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF      
      IF :oVAL_BC_ICMS_OUT_UF:VARGET() < 0
         ::oCTe_GERAIS:uiAviso('Valor da BC do ICMS Outra UF negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oPER_ALI_ICMS_OUT_UF:VARGET() < 0
         ::oCTe_GERAIS:uiAviso('Percentual aliquota do ICMS Outra UF negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
      IF :oVAL_ICMS_DEV_OUT_UF:VARGET() < 0
         ::oCTe_GERAIS:uiAviso('Valor do ICMS devido Outra UF negativo, Favor Revisar!')
         RETURN(.F.)
      ENDIF
   END
/*   
   IF :oPESO_BASE_CALC:VARGET() < 0
      ::oCTe_GERAIS:uiAviso('Peso da base de cálculo é negativo, Favor Revisar!')
      RETURN(.F.)
   ENDIF
*/   
/*
   IF :oPESO_AFERIDO:VARGET() < 0
      ::oCTe_GERAIS:uiAviso('Peso aferido é negativo, Favor Revisar!')
      RETURN(.F.)
   ENDIF
*/   
/*
   IF :oCUBAGEM:VARGET() < 0
      ::oCTe_GERAIS:uiAviso('Cubagem é negativo, Favor Revisar!')
      RETURN(.F.)
   ENDIF
*/   
   IF !EMPTY(:oAVERBACAO:VARGET()) .AND. LEN(ALLTRIM(:oAVERBACAO:VARGET()))<>20
      ::oCTe_GERAIS:uiAviso('A averbação deve conter 20 posições.')
      RETURN(.F.)
   ENDIF

   IF LEFT(:oTIPO_CT:GETTEXT(),1)='1' .AND. EMPTY(:oPage2:oCTE_COMPLE:VARGET())
      ::oCTe_GERAIS:uiAviso('Favor informar a chave do CT-e de complemento.')
      RETURN(.F.)
   ENDIF
   
   WITH OBJECT :oPage2:oBr1
      FOR mI:=1 TO LEN(:aArray)
         nTOT_SERVICO+=:aArray[mI,4]*:aArray[mI,3]
      NEXT
   END

   IF lCCe
      IF ::uiCartaCorrecao200(oOBJ,nCTE_ID)
         oOBJ:CLOSE()
      ENDIF
      RETURN(.T.)
   ENDIF
   
   WITH OBJECT :oPage2:oBr5
      FOR mI:=1 TO LEN(:aArray)
         nTOTpedagio+=:aArray[mI,6]
      NEXT
   END

   ::oCTe_GERAIS:rgBeginTransaction()
   IF nCTE_ID<=0
      WHILE .T.
         nNUMCTE:=::oCTe_GERAIS:rgSequencia_Sql('CT-E'+::cCte_Filial+LEFT(:oMODELO:GETTEXT(),2)+ALLTRIM(:oSERIE:GETTEXT()),.T.)
         ::oCTe_GERAIS:rgExecuta_Sql('select count(*) from sagi_cte where cte_numerodacte='+::oCTe_GERAIS:rgConcat_sql(nNUMCTE),,,@aSQL)
         IF LEN(aSQL)>0 .AND. aSQL[1,1]>0
            LOOP
         ENDIF
         EXIT
      ENDDO
      
      ::oCTe_GERAIS:rgExecuta_Sql("select adiciona::int from adiciona('sagi_cte','cte_numerodacte,"+;
                                                                      'cte_modelo, '+;
                                                                      "cte_serie',$$"+::oCTe_GERAIS:rgConcat_sql(nNUMCTE)+','+;
                                                                                      ::oCTe_GERAIS:rgConcat_sql(:oMODELO:GETTEXT())+','+;
                                                                                      ::oCTe_GERAIS:rgConcat_sql(:oSERIE:GETTEXT())+"$$,'cte_id');",,,@aSQL)
      IF LEN(aSQL)<=0 .OR. aSQL[1,1]<=0
         ::oCTe_GERAIS:rgRollBackTransaction()
         ::oCTe_GERAIS:uiAviso('Houve um erro ao tentar criar a CT-e.')
         RETURN(.F.)
      ENDIF
      nCTE_ID:=aSQL[1,1]
   ELSE
      ::oCTe_GERAIS:rgExecuta_Sql('select cte_numerodacte from sagi_cte where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)
      IF LEN(aSQL)<=0 .OR. aSQL[1,1]<=0
         ::oCTe_GERAIS:rgRollBackTransaction()
         ::oCTe_GERAIS:uiAviso('Houve um erro ao tentar alterar a CT-e.')
         RETURN(.F.)
      ENDIF
      nNUMCTE:=aSQL[1,1]
   ENDIF

   ::oCTe_GERAIS:rgExecuta_Sql('update sagi_cte set cte_modalidade='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oMODALIDADE:GETTEXT(),2)))+','+;
                                   'cte_modelo='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oMODELO:GETTEXT(),2)))+','+;
                                   'cte_serie='+::oCTe_GERAIS:rgConcat_sql(:oSERIE:GETTEXT())+','+;
                                   'cte_numerodacte='+::oCTe_GERAIS:rgConcat_sql(:oNUMCTE:VARGET())+','+;
                                   'cte_dataemissao='+::oCTe_GERAIS:rgConcat_sql(DATE())+','+;
                                   'cte_horaemissao='+::oCTe_GERAIS:rgConcat_sql(TIME())+','+;
                                   'cte_tipo='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oTIPO_CT:GETTEXT(),1)) )+','+;
                                   'cte_tiposervico='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oTIP_SERVICO:GETTEXT(),1)))+','+;
                                   'cte_tomadorservico='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oTOMADOR:GETTEXT(),1)))+','+;
                                   'cte_formapagamento='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oPage2:oFOR_PGT:GETTEXT(),1)))+','+;
                                   'cfop_id='+::oCTe_GERAIS:rgConcat_sql(:oCFOP:VARGET())+','+;
                                   'cte_ibgeorigemprestacao='+::oCTe_GERAIS:rgConcat_sql(::oCTe_GERAIS:rgPega_Cod_Cidade(:oUF_ORIGEM:GETTEXT(),:oCIDADE_ORIGEM:GETTEXT()))+','+;
                                   'empresa='+::oCTe_GERAIS:rgConcat_sql(::cCte_Filial)+','+;
                                   'cte_ibgedestinoprestacao='+::oCTe_GERAIS:rgConcat_sql(::oCTe_GERAIS:rgPega_Cod_Cidade(:oUF_DESTINO:GETTEXT(),:oCIDADE_DESTINO:GETTEXT()))+','+;
                                   'remetente_id='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_CLIENTE:VARGET())+','+;
                                   'destinatario_id='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_DESTINATARIO:VARGET())+','+;
                                   'expedidor_id='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_EXPEDIDOR:VARGET())+','+;
                                   'recebedor_id='+::oCTe_GERAIS:rgConcat_sql(:oPage3:oCOD_RECEBEDOR:VARGET())+','+;
                                   'cte_descricaopredominante='+::oCTe_GERAIS:rgConcat_sql(left(:oPRODUTO:VARGET(),40))+','+;
                                   'cte_outrascaracter='+::oCTe_GERAIS:rgConcat_sql(:oOUT_CARACTERISTICAS:VARGET())+','+; 
                                   'cte_valortotalmercad='+::oCTe_GERAIS:rgConcat_sql(:oVAL_MERCADORIA:VARGET())+','+;
                                   'cte_pesobruto='+::oCTe_GERAIS:rgConcat_sql(:oPESO_BRUTO:VARGET())+','+; // 'cte_pesobasecalc='+::oCTe_GERAIS:rgConcat_sql(:oPESO_BASE_CALC:VARGET())+','+;    //'cte_pesoaferido='+::oCTe_GERAIS:rgConcat_sql(:oPESO_AFERIDO:VARGET())+','+;  //'cte_cubagem='+::oCTe_GERAIS:rgConcat_sql(:oCUBAGEM:VARGET())+','+;
                                   'cte_unidade='+::oCTe_GERAIS:rgConcat_sql(LEFT(:oUNI:GETTEXT(),2))+','+;
                                   'cte_tipo_medida='+::oCTe_GERAIS:rgConcat_sql(:oTIPmed:GETTEXT())+','+;
                                   'cte_volumes='+::oCTe_GERAIS:rgConcat_sql(:oVOLUMES:VARGET())+','+;
                                   'cte_responsavel_seguro='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oRESPONSAVEL:GETTEXT(),1)))+','+;
                                   'seguradora='+::oCTe_GERAIS:rgConcat_sql(:oNOM_SEGURADORA:VARGET())+','+;
                                   'cte_apolice_seguro='+::oCTe_GERAIS:rgConcat_sql(:oAPOLICE:VARGET())+','+;
                                   'cte_averbacao_seguro='+::oCTe_GERAIS:rgConcat_sql(:oAVERBACAO:VARGET())+','+;
                                   'cte_rntrc='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oRNTRC:VARGET())+','+;
                                   'cte_dataprevistaentrega='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oENTREGa:GETVALUE())+','+;
                                   'cte_lotacao='+::oCTe_GERAIS:rgConcat_sql(Len(:oPage2:oBr4:aArray)>0)+','+;
                                   'cte_imposto='+::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:oPage2:oTIP_TRIBUTACAO:GETTEXT(),2)))+','+;
                                   'cte_icmsbasecalc='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oBASE_CALCULO:VARGET())+','+;
                                   'cte_icmsaliq='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oPER_ALIQ_ICMS:VARGET())+','+;
                                   'cte_icmsvalor='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_ICMS:VARGET())+','+;
                                   'cte_icmsreducaobc='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oPER_RED_BC:VARGET())+','+;
                                   'cte_observacao='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oOBS:VARGET())+','+;
                                   'cte_valorservico='+::oCTe_GERAIS:rgConcat_sql(nTOT_SERVICO)+','+;
                                   'cte_valorreceber='+::oCTe_GERAIS:rgConcat_sql(nTOT_SERVICO +nTOTpedagio )+','+;
                                   'cte_vbcstret='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_BC_ST_RET:VARGET())+','+;
                                   'cte_vicmsstret='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_ICMS_ST_RET:VARGET())+','+;
                                   'cte_picmsstret='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oPER_ALI_BC_ST_RET:VARGET())+','+;
                                   'cte_vcred='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_CRE_OUT:VARGET())+','+;
                                   'cte_predbcoutrauf='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oPER_RED_BC_OUT_UF:VARGET())+','+;
                                   'cte_vbcoutrauf='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_BC_ICMS_OUT_UF:VARGET())+','+;
                                   'cte_picmsoutrauf='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oPER_ALI_ICMS_OUT_UF:VARGET())+','+;
                                   'cte_vicmsoutrauf='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_ICMS_DEV_OUT_UF:VARGET())+','+;
                                   'cte_valorcarga_averbacao='+::oCTe_GERAIS:rgConcat_sql(:oVAL_AVERBACAO:VARGET())+','+;
                                   'cte_especie='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oESPECIE:VARGET())+','+;
                                   'cte_placa='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oPLACA:VARGET())+','+;
                                   'cte_valfrete='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_FRETE:VARGET())+','+;     
                                   'cte_valpedagio='+::oCTe_GERAIS:rgConcat_sql(nTOTpedagio)+','+;   //:oPage2:oVAL_PEDAGIO:VARGET()
                                   'cte_outros='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oVAL_OUTROS:VARGET())+','+;
                                   'cte_cod_prazo='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oCOD_PRAZO:VARGET())+','+;
                                   'cte_frete_responsa='+::oCTe_GERAIS:rgConcat_sql(LEFT(:oPage2:oFRT_CONTA:GETTEXT(),1))+','+;
                                   'cte_chave_completa='+::oCTe_GERAIS:rgConcat_sql(:oPage2:oCTE_COMPLE:VARGET())+;
                            ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)) 

   WITH OBJECT :oPage2:oBr1
      ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte_prestacao_servico where prest_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID))
      FOR mI := 1 TO LEN(:aArray)
         ::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_prestacao_servico (prest_id_cte, '+;
                                                             'prest_id_cte_cad_servico, '+;
                                                             'prest_valor, '+;
                                                             'prest_quant) values ('+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+','+;
                                                                                     ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,1])+','+;
                                                                                     ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,4])+','+;
                                                                                     ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,3])+')')
      NEXT
   END
   WITH OBJECT :oPage2:oBr2
      ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte_docs where docs_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID))
      FOR mI:=1 TO LEN(:aArray)
         ::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_docs (docs_id_cte, '+;   // 01
                                                'docs_tipo, '+;     // 02
                                                'docs_mod, '+;      // 03
                                                'docs_serie, '+;    // 04
                                                'docs_ndoc, '+;     // 05
                                                'docs_demi, '+;     // 06
                                                'docs_vnf, '+;      // 07
                                                'docs_vicms, '+;    // 08
                                                'docs_vbcst, '+;    // 09
                                                'docs_vst, '+;      // 10
                                                'docs_vprod, '+;    // 11
                                                'docs_vbc, '+;      // 12
                                                'docs_ncfop, '+;    // 13
                                                'docs_npeso, '+;    // 14
                                                'docs_chavenfe, '+; // 15  
                                                'docs_descricaooutros ) values ( '+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+','+;         // 01
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,01])+','+;  // 02
                                                                                   ::oCTe_GERAIS:rgConcat_sql(VAL(LEFT(:aArray[mI,02],2)))+','+;  // 03
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,03])+','+;  // 04
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,04])+','+;  // 05
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,05])+','+;  // 06
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,11])+','+;  // 07
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,07])+','+;  // 08
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,06])+','+;  // 09
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,09])+','+;  // 10
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,10])+','+;  // 11
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,06])+','+;  // 12
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,12])+','+;  // 13
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,14])+','+;  // 14
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,15])+','+;  // 15
                                                                                   ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,16])+') ')  // 16
      NEXT
   END

   // Marco Barcelos - 17/03/2014
   WITH OBJECT :oPage2:oBr4
     ::oCTe_GERAIS:rgExecuta_Sql('delete from SAGI_CTE_VEICULOS where CTE_ID='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID))
      FOR mI:=1 TO LEN(:aArray)
         cSQL := 'insert into SAGI_CTE_VEICULOS( VEIC_CODIGO, '
         cSQL +=                                'VEIC_RENAVAM, '
         cSQL +=                                'VEIC_PLACA, '
         cSQL +=                                'VEIC_TARA, '
         cSQL +=                                'VEIC_CAPAC_KG, '
         cSQL +=                                'VEIC_CAPAC_M3, '
         cSQL +=                                'VEIC_TP_PROPR, '
         cSQL +=                                'VEIC_TP_VEICULO, '
         cSQL +=                                'VEIC_TP_RODADO, '
         cSQL +=                                'VEIC_TP_CARROC, '
         cSQL +=                                'VEIC_UF_LICENC, '
         cSQL +=                                'CTE_ID )'
         cSQL +=                       ' values('+::oCTe_GERAIS:rgConcat_sql(:aArray[mI,01])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,02])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,03])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,04])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,05])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,06])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,07])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,08])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,09])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,10])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,11])+','
         cSQL +=                                  ::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+')'
         ::oCTe_GERAIS:rgExecuta_Sql(cSQL)
      NEXT
   END

   WITH OBJECT :oPage2:oBr5
      ::oCTe_GERAIS:rgExecuta_Sql('delete from sagi_cte_pedagio where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID))
      FOR mI:=1 TO LEN(:aArray)
         ::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_pedagio (cte_id, '+;               // 01
                                                                   'pedagio_fornecedor, '+;   // 02
                                                                   'pedagio_comprovante, '+;  // 03
                                                                   'pedagio_responsavel, '+;  // 04
                                                                   'pedagio_valor, '+;        // 05
                                                                   'pedagio_cnpj_for, '+;     // 06
                                                                   'pedagio_cnpj_res) values ( '+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+','+;         // 01
                                                                                                 ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,01])+','+;  // 02
                                                                                                 ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,03])+','+;  // 03
                                                                                                 ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,04])+','+;  // 04
                                                                                                 ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,06])+','+;  // 05
                                                                                                 ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,07])+','+;  // 06
                                                                                                 ::oCTe_GERAIS:rgConcat_sql(:aArray[mI,08])+') ')  // 07
      NEXT
   END
   ::oCTe_GERAIS:rgEndTransaction()

   IF nNUMCTE<>:oNUMCTE:VARGET()
      ::oCTe_GERAIS:uiAviso('O número da CT-e mudou para '+ALLTRIM(STR(nNUMCTE)) )

      // Aconteceu na Recimesa de dar o aviso que a CTE mudou para o numero (577)  mas na CTe continuo com o numero (576) e acabou duplicando 2 CTe com 2 numeros. por isso essa regravacao do numero da CTe  (mauricio cruz - 30/01/2014)
      ::oCTe_GERAIS:rgExecuta_Sql('select cte_numerodacte from sagi_cte where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)
      IF LEN(aSQL)>0 .AND. aSQL[1,1]<>nNUMCTE
         ::oCTe_GERAIS:rgBeginTransaction()
         ::oCTe_GERAIS:rgExecuta_Sql('update sagi_cte set cte_numerodacte='+::oCTe_GERAIS:rgConcat_sql(nNUMCTE)+' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID))
         ::oCTe_GERAIS:rgEndTransaction()   
      ENDIF
   ENDIF

   if _RegEmpresa()<>779 // repram
      IF LEFT(:oTIP_SERVICO:GETTEXT(),1)<>'0'
         lGERA_CTEAREC:=::oCTe_GERAIS:uiSN('Deseja gerar contas a receber desta CT-e?')
      ENDIF
   endif
END 

// gera os contas a receber
IF lGERA_CTEAREC
   ::uiMsgRun('Aguarde, gerando contas a receber...',{|| ::oCTe_GERAIS:rgGeraCtaRec(nCTE_ID) } )
ENDIF

IF ::lCte_ELETRONICO
   IF ::oCTe_GERAIS:uiSN('CT-e Salva com sucesso.'+HB_OsNewLine()+;
             'Deseja transmitir agora ?')
       ::uiMsgRun('Aguarde, '+IF(::lCte_Emulador,'emulando','transmitindo')+' a CT-e...',{|| lTRANSMITIDO:=::ctTransmite(nCTE_ID) } )
      IF !lTRANSMITIDO    
         oOBJ:CLOSE()
         ::uiCadastraCTe(oOBJ2,'A',nCTE_ID)
      ENDIF
   ENDIF
ELSE
   IF ::oCTe_GERAIS:uiSN('CT Salva com sucesso.'+HB_OsNewLine()+;
             'Deseja imprimir agora ?')
      ::uiMsgRun('Aguarde, imprimindo a CT-e...',{|| ::oCTe_GERAIS:rgImprimeCTPapel(nCTE_ID) } )
   ENDIF
ENDIF

oOBJ:CLOSE()

RETURN(.T.)


Method uiCalcula_totais(oOBJ) Class oCTe_HWgui
/*
   calcula os totais
   Mauricio Cruz - 17/07/2013
*/
LOCAL mI:=0, nTOTsrv:=0, nQTDsrv:=0

WITH OBJECT oOBJ:oPage1
   WITH OBJECT :oPage2:oBr1
      FOR mI:=1 TO LEN(:aArray)
         nTOTsrv+=:aArray[mI,4]*:aArray[mI,3]
         nQTDsrv+=:aArray[mI,3]
      NEXT
   END

   :oTOT_SERVICO:SETTEXT(nTOTsrv)
   :oTOT_SERVICO:REFRESH()
   
   :oTOTAL:SETTEXT(nTOTsrv)
   :oTOTAL:REFRESH()
   
   :oTOT_ITENS:SETTEXT(nQTDsrv)
   :oTOT_ITENS:REFRESH()
END
RETURN(.T.)


Method uiVerificaSit_CTe(oOBJ,nCTE_ID,lCCe) Class oCTe_HWgui
/*
   verifica se a CTe ja foi autorizada ou cancelada ou inutilizada e não deixa alterar
   Mauricio Cruz - 23/07/2013
*/
LOCAL aSQL:={}

::oCTe_GERAIS:rgExecuta_Sql('select cte_protocolo, '+;
                            '       cte_prot_canc, '+;
                            '       cte_prot_inut '+;
                            '  from sagi_cte '+;
                            ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)
IF LEN(aSQL)>0 .AND. !EMPTY(aSQL[1,3])
   ::oCTe_GERAIS:uiAviso('Esta CT-e esta inutilizada e não pode ser alterada.')
   oOBJ:oButtonex1:DISABLE()
   RETURN(.T.)
ENDIF
IF LEN(aSQL)>0 .AND. !EMPTY(aSQL[1,2])
   ::oCTe_GERAIS:uiAviso('Esta CT-e esta cancelada e não pode ser alterada.')
   oOBJ:oButtonex1:DISABLE()
   RETURN(.T.)
ENDIF
IF LEN(aSQL)>0 .AND. !EMPTY(aSQL[1,1]) .AND. !lCCe
   ::oCTe_GERAIS:uiAviso('Esta CT-e esta autorizada e não pode ser alterada.')
   oOBJ:oButtonex1:DISABLE()
   RETURN(.T.)
ENDIF
IF ::oCTe_GERAIS:rgCteJaEstaRecebida(nCTE_ID) .AND. !lCCe
   ::oCTe_GERAIS:uiAviso('Esta CT-e já tem contas a receber recebidas e não pode ser alterada. Favor estornar o recebimento primeiro.')
   oOBJ:oButtonex1:DISABLE()
   RETURN(.T.)
ENDIF


RETURN(.T.)



Method uiCad_prest_servico(oOBJ,cLAN,nCODpadrao) Class oCTe_HWgui
/*
   Cadastro da prestacao de servico
   Mauricio Cruz - 17/07/2013
*/
LOCAL oDlg
LOCAL oGroup1
LOCAL oLabel1, oLabel2, oLabel3, oLabel4
LOCAL oCOD, oDES, oQTD, oVAL
LOCAL oButtonex1, oButtonex2, oOwnerbutton1
LOCAL cDES:=''
LOCAL nCOD:=0, nQTD:=1, nVAL:=0
LOCAL aSQL:={}

IF cLAN='A'
   WITH OBJECT oOBJ:oPage1:oPage2:oBr1
      IF LEN(:aArray)<=0
         RETURN(.F.)
      ENDIF
      nCOD:=:aArray[:nCurrent,1]
      cDES:=:aArray[:nCurrent,2]
      nQTD:=:aArray[:nCurrent,3]
      nVAL:=:aArray[:nCurrent,4]
   END
ENDIF

INIT DIALOG oDlg TITLE "Prestação de serviços"    AT 000,000 SIZE 729,167 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     ON INIT{|| IF(nCODpadrao<>NIL,(::uiPega_Servico(@nCODpadrao,@cDES,oCOD,oDES),;
                                    ::oCTe_GERAIS:rgExecuta_Sql('select valor from tipserv where codserv='+::oCTe_GERAIS:rgConcat_sql(nCODpadrao),,,@aSQL),;
                                    IF(LEN(aSQL)>0,(oVAL:SETTEXT(aSQL[1,1]),oVAL:REFRESH()),.T. ),; 
                                    oButtonex1:ONCLICK()),.T.), .T. };
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_SYSMENU ICON HIcon():AddResource(::nCte_Icont)

@ 002,001 GROUPBOX oGroup1 CAPTION "Detalhes da prestação de serviço"  SIZE 724,124 STYLE BS_LEFT COLOR x_BLUE
     
@ 007,019 SAY oLabel1 CAPTION "Código"  SIZE 49,21
@ 007,038 GET oCOD VAR nCOD SIZE 120,24  PICTURE '9999999999' MAXLENGTH 10 STYLE IF(cLAN='A',WS_DISABLED,0);
          VALID{|| IF(nCOD>0,::uiPega_Servico(@nCOD,@cDES,oCOD,oDES),.T.),;
                   ::oCTe_GERAIS:rgExecuta_Sql('select valor from tipserv where codserv='+::oCTe_GERAIS:rgConcat_sql(nCOD),,,@aSQL), IF(LEN(aSQL)>0,(oVAL:SETTEXT(aSQL[1,1]),oVAL:REFRESH()),.T. )  };
          TOOLTIP 'Informe o código da prestação de serviço'

@ 132,019 SAY oLabel2 CAPTION "Descrição"  SIZE 80,21
@ 132,038 GET oDES VAR cDES SIZE 559,24  PICTURE '@!' MAXLENGTH 60  STYLE IF(cLAN='A',WS_DISABLED,0); 
          VALID{|| IF(nCOD<=0,::uiPega_Servico(@nCOD,@cDES,oCOD,oDES),.T.),;
                   ::oCTe_GERAIS:rgExecuta_Sql('select valor from tipserv where codserv='+::oCTe_GERAIS:rgConcat_sql(nCOD),,,@aSQL), IF(LEN(aSQL)>0,(oVAL:SETTEXT(aSQL[1,1]),oVAL:REFRESH()),.T. ) };
          TOOLTIP 'Informe a descrição da prestação do serviço'

@ 693,038 OWNERBUTTON oOwnerbutton1  SIZE 24,24 FLAT;
          ON CLICK {|| nCOD:=0, cDES:='', ::uiPega_Servico(@nCOD,@cDES,oCOD,oDES),;
                       ::oCTe_GERAIS:rgExecuta_Sql('select valor from tipserv where codserv='+::oCTe_GERAIS:rgConcat_sql(nCOD),,,@aSQL), IF(LEN(aSQL)>0,(oVAL:SETTEXT(aSQL[1,1]),oVAL:REFRESH()),.T. ) };
          BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
          TOOLTIP 'Localizar um serviço'

@ 007,072 SAY oLabel3 CAPTION "Quantidade"  SIZE 80,21
@ 007,094 GET oQTD VAR nQTD SIZE 177,24  PICTURE '@E 999,999.999'  ; 
          TOOLTIP 'Informe a quantidade'
           
@ 200,072 SAY oLabel4 CAPTION "Valor R$"  SIZE 53,21
@ 200,094 GET oVAL VAR nVAL SIZE 177,24  PICTURE '@E 999,999,999.99'  ; 
          TOOLTIP 'Informe o valor'

@ 486,128 BUTTONEX oButtonex1 CAPTION "&Salvar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
          ON CLICK{|| ::uiSalva_prest_servico(oDlg,oOBJ,cLAN) }
          
@ 606,128 BUTTONEX oButtonex2 CAPTION "&Fechar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| oDlg:CLOSE() }

ACTIVATE DIALOG oDlg 

RETURN(.T.)



Method uiSalva_prest_servico(oOBJ,oOBJ2,cLAN) Class oCTe_HWgui
/*
   salva para a array a prestacao do servico
   Mauricio Cruz - 17/07/2013
*/
WITH OBJECT oOBJ
   IF EMPTY(:oCOD:VARGET())
      ::oCTe_GERAIS:uiAviso('Favor informar um código para esta prestação de serviço')
      RETURN(.F.)
   ENDIF
   IF EMPTY(:oDES:VARGET())
      ::oCTe_GERAIS:uiAviso('Favor informar uma descrição para esta prestação de serviço')
      RETURN(.F.)
   ENDIF
   IF :oQTD:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Favor informar uma quantidade para a prestação de serivço')
      RETURN(.F.)
   ENDIF
   IF :oVAL:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Favor informar um valor para a prestação de serivço')
      RETURN(.F.)
   ENDIF
   
   WITH OBJECT oOBJ2:oPage1:oPage2:oBr1
      IF cLAN='C'
         AADD(:aArray,{oOBJ:oCOD:VARGET(), oOBJ:oDES:VARGET(), oOBJ:oQTD:VARGET(), oOBJ:oVAL:VARGET()} )
      ELSE
        :aArray[:nCurrent,1]:=oOBJ:oCOD:VARGET()
        :aArray[:nCurrent,2]:=oOBJ:oDES:VARGET()
        :aArray[:nCurrent,3]:=oOBJ:oQTD:VARGET()
        :aArray[:nCurrent,4]:=oOBJ:oVAL:VARGET()
      ENDIF
      :REFRESH()
   END
   :CLOSE()
END
RETURN(.T.)



Method uiDel_prest_servico(oOBJ) Class oCTe_HWgui
/*
   remove uma prestacao de servico
   Maurico Cruz - 17/07/2013
*/
WITH OBJECT oOBJ:oPage1:oPage2:oBr1
   IF LEN(:aArray)<=0 .OR. !::oCTe_GERAIS:uiSN('Confirmar a remoção do serviço selecionado ?')
      RETURN(.F.)
   ENDIF
   ADEL(:aArray,:nCurrent,.T.)
   :REFRESH()
END
RETURN(.T.)

Method uiCad_doc_orig(oOBJ,cLAN,hNNF,lCCe) Class oCTe_HWgui
/*
   cadastro / alteracao de documentos originarios
   Mauricio Cruz - 17/07/2013
*/
LOCAL oDlg
LOCAL oGroup1
LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6, oLabel7, oLabel8, oLabel9, oLabel10, oLabel11, oLabel12, oLabel13, oLabel14, oLabel15
LOCAL oTIP, oMOD, oSER, oNUM, oEMI, oVBC, oICM, oVBS, oVST, oVPR, oVDC, oCFOP, oDES_CFOP, oOUT, oPES, oCHV
LOCAL oOwnerbutton1
LOCAL oButtonex1, oButtonex2, oButtonex3
LOCAL cTIP:='NF', cMOD:='01', cSER:='', cDES_CFOP:='', cCHV:='', cOUT:='', cNUM:=''
LOCAL nVBC:=0, nICM:=0, nVBS:=0, nVST:=0, nVPR:=0, nVDC:=0, nCFOP:=0, nPES:=0
LOCAL dEMI:=DATE()

IF cLAN='A'
   WITH OBJECT oOBJ:oPage1:oPage2:oBr2
      IF LEN(:aArray)<=0
         RETURN(.F.)
      ENDIF
      cTIP:=:aArray[:nCurrent,1]
      cMOD:=:aArray[:nCurrent,2]
      cSER:=:aArray[:nCurrent,3]
      cNUM:=:aArray[:nCurrent,4]
      dEMI:=:aArray[:nCurrent,5]
      nVBC:=:aArray[:nCurrent,6]
      nICM:=:aArray[:nCurrent,7]
      nVBS:=:aArray[:nCurrent,8]
      nVST:=:aArray[:nCurrent,9]
      nVPR:=:aArray[:nCurrent,10]
      nVDC:=:aArray[:nCurrent,11]
      nCFOP:=:aArray[:nCurrent,12]
      cDES_CFOP:=:aArray[:nCurrent,13]
      nPES:=:aArray[:nCurrent,14]
      cCHV:=:aArray[:nCurrent,15]
      cOUT:=:aArray[:nCurrent,16]
   END
ENDIF


INIT DIALOG oDlg TITLE "Documento originário" AT 0,0 SIZE 656,329 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     ON INIT{|| IF(hNNF<>NIL,(oButtonex3:ONCLICK(),oButtonex1:ONCLICK()),.T.), ::uiValida_tipo_documento(oDlg) };
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_SYSMENU ICON HIcon():AddResource(::nCte_Icont)

@ 004,000 GROUPBOX oGroup1 CAPTION "Documento Fiscal"  SIZE 649,285 STYLE BS_LEFT COLOR x_BLUE

@ 012,017 SAY oLabel1 CAPTION "Tipo"  SIZE 35,21
@ 012,036 GET COMBOBOX oTIP VAR cTIP  ITEMS {'NF','NF-e','OUTROS'} SIZE 136,24 TEXT STYLE IF(lCCe,WS_DISABLED,0);
          ON INIT{|| oTIP:SETTEXT(oTIP:aItems[ASCAN(oTIP:aItems,cTIP)]), oTIP:REFRESH() };
          ON CHANGE{|| ::uiValida_tipo_documento(oDlg)  };
          TOOLTIP 'Selecione o tipo de documento'

@ 156,017 SAY oLabel2 CAPTION "Modelo"  SIZE 50,21
@ 156,036 GET COMBOBOX oMOD VAR cMOD  ITEMS {'01-Modelo 01/01A e Avulsa','04-NF Produtor'} SIZE 196,24  ; 
          TOOLTIP 'Selecione o modelo'

@ 358,017 SAY oLabel3 CAPTION "Série"  SIZE 38,21
@ 358,036 GET oSER VAR cSER SIZE 48,24  PICTURE '@!' MAXLENGTH 3;
          TOOLTIP 'Informe a série do documento'

@ 413,017 SAY oLabel4 CAPTION "Número"  SIZE 55,21
@ 413,036 GET oNUM VAR cNUM SIZE 117,24  PICTURE '9999999999' MAXLENGTH 10;
          TOOLTIP 'Informe o número do documento'

@ 535,017 SAY oLabel5 CAPTION "Data de Emissão"  SIZE 107,21
@ 535,036 GET DATEPICKER oEMI VAR dEMI SIZE 110,24;
          TOOLTIP 'Informe a data de emissão do documento'

@ 012,070 SAY oLabel6 CAPTION "R$ Base Calculo:"  SIZE 104,21
@ 012,091 GET oVBC VAR nVBC SIZE 152,24  PICTURE '@E 999,999,999.99' MAXLENGTH 15;
          TOOLTIP 'Informe o valor da base de calculo'

@ 172,070 SAY oLabel7 CAPTION "Valor do ICMS R$"  SIZE 107,21  
@ 172,091 GET oICM VAR nICM SIZE 152,24  PICTURE '@E 999,999,999.99' MAXLENGTH 15  ; 
          TOOLTIP 'Informe o valor do icms'

@ 332,070 SAY oLabel8 CAPTION "R$ BC. ST"  SIZE 80,21  
@ 332,091 GET oVBS VAR nVBS SIZE 152,24  PICTURE '@E 999,999,999.99' MAXLENGTH 15;
          TOOLTIP 'Informe o valor da base de calculo da substituição tributária'

@ 492,070 SAY oLabel9 CAPTION "R$ ST."  SIZE 50,21  
@ 492,091 GET oVST VAR nVST SIZE 152,24  PICTURE '@E 999,999,999.99' MAXLENGTH 15  ; 
          TOOLTIP 'Informe o valor da substituição tributária'

@ 012,123 SAY oLabel10 CAPTION "R$ Produtos"  SIZE 80,21  
@ 012,144 GET oVPR VAR nVPR SIZE 152,24  PICTURE '@E 999,999,999.99' MAXLENGTH 15  ; 
          TOOLTIP 'Informe o valor dos produtos'

@ 172,123 SAY oLabel11 CAPTION "R$ Documento"  SIZE 89,21  
@ 172,144 GET oVDC VAR nVDC SIZE 152,24  PICTURE '@E 999,999,999.99' MAXLENGTH 15  ; 
          TOOLTIP 'Informe o valor do documento'

@ 332,123 SAY oLabel12 CAPTION "CFOP Predominante"  SIZE 123,21  
@ 332,144 GET oCFOP VAR nCFOP SIZE 80,24  PICTURE '9999' MAXLENGTH 4  ; 
          VALID{|| IF(nCFOP>0, ::uiPega_Cfop(@nCFOP,@cDES_CFOP,oCFOP,oDES_CFOP),.T.) };
          TOOLTIP 'Inforrme o código do CFOP predominante'

@ 415,143 GET oDES_CFOP VAR cDES_CFOP SIZE 202,24  PICTURE '@!' MAXLENGTH 60 STYLE WS_DISABLED

@ 620,143 OWNERBUTTON oOwnerbutton1  SIZE 24,24  FLAT;
          ON CLICK {|| nCFTOP:=0, cDES_CFOP:='', ::uiPega_Cfop(@nCFOP,@cDES_CFOP,oCFOP,oDES_CFOP) };
          BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
          TOOLTIP 'Localizar um CFOP'


@ 012,182 SAY oLabel13 CAPTION "Peso (kg)"  SIZE 80,21  
@ 011,202 GET oPES VAR nPES SIZE 152,24  PICTURE '@E 999,999.999' MAXLENGTH 9;
          TOOLTIP 'Informe o peso em kilo'

@ 169,182 SAY oLabel14 CAPTION "Chave NF-e"  SIZE 80,21  
@ 169,202 GET oCHV VAR cCHV SIZE 473,24  PICTURE '@R 9999.9999.9999.9999.9999.9999.9999.9999.9999.9999.9999' MAXLENGTH 44  ; 
          TOOLTIP 'Informe a chave da nota fiscal eletrênica'

@ 011,234 SAY oLabel15 CAPTION "Descrição Outros"  SIZE 104,21  
@ 011,254 GET oOUT VAR cOUT SIZE 632,24  PICTURE '@!' MAXLENGTH 100  ; 
          TOOLTIP 'Informe a descrição de outros'


@ 004,288 BUTTONEX oButtonex3 CAPTION "&Localizar NF" SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Buscar)):handle;
          ON CLICK{|| ::uiLocaliaNF(oDlg,hNNF) }

@ 413,288 BUTTONEX oButtonex1 CAPTION "&Salvar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
          ON CLICK{|| ::uiSalva_doc_originario(oDlg,oOBJ,cLAN) }
          
@ 533,288 BUTTONEX oButtonex2 CAPTION "&Fechar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| oDlg:CLOSE() }

ACTIVATE DIALOG oDlg 

RETURN(.T.) 

Method uiLocaliaNF(oOBJ,hNNF) Class oCTe_HWgui
/*
   Localiza e atualiza os dados de uma NF
   Mauricio Cruz - 19/08/2013
*/
LOCAL aSQL:={}
IF hNNF=NIL
   hNNF:=LISTA_NF('PESQ',NIL,.T.)
   IF hNNF=NIL
      ShowMsg('Não foi localizado notas, favor revisar')
      RETURN(.F.)
   ENDIF
ENDIF

IF hNNF['ORDEM']<=0
   ::oCTe_GERAIS:rgExecuta_Sql('select a.modnot, '+;
                               '       a.serie, '+;
                               '       a.nffs, '+;
                               '       a.dataem, '+;
                               '       (select sum(x.total) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs) as base_calc, '+;
                               '       (select sum(x.total*x.icms/100) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs) as val_icms, '+;
                               '       (select sum(x.base_st) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs) as base_st, '+;
                               '       (select sum(x.base_st*x.icms_st/100) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs) as val_st, '+;
                               '       (select sum(x.total) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs) as val_produtos, '+;
                               '       (select sum(x.total) from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' x where x.modnot=a.modnot and x.serie=a.serie and x.nffs=a.nffs) as val_documento, '+;
                               '       a.cfop, '+;
                               '       b.natureza, '+;
                               '       a.peso_liq, '+;
                               '       substring(c.nome_arq from 1 for 44)::text '+;
                               '  from '+valida_nome_tab('cag_not',hNNF['EMPRESA'])+' a '+;
                               '  left join cfop b on b.cfop=a.cfop '+;
                               '  left join '+valida_nome_tab('anexo_not',hNNF['EMPRESA'])+' c on c.modnot=a.modnot and c.serie=a.serie and c.nffs=a.nffs '+;
                               ' where a.modnot='+::oCTe_GERAIS:rgConcat_sql(hNNF['MOD'])+;
                               '   and a.serie='+::oCTe_GERAIS:rgConcat_sql(hNNF['SER'])+;
                               '   and a.nffs='+::oCTe_GERAIS:rgConcat_sql(hNNF['NNF'])+;
                               ' limit 1 ',,,@aSQL)
ELSE
   ::oCTe_GERAIS:rgExecuta_Sql('select a.modnot, '+;
                               '       a.serie, '+;
                               '       a.num_nf, '+;
                               '       a.data_emi, '+;
                               '       a.base_icms, '+;
                               '       a.vlr_icms, '+;
                               '       a.base_st, '+;
                               '       a.toticms_st, '+;
                               '       a.valor_tot, '+;
                               '       a.valor_tot, '+;
                               '       a.cfop, '+;
                               '       b.natureza, '+;
                               '       (select sum(x.quant) from '+valida_nome_tab('sintegra',hNNF['EMPRESA'])+' x where x.ordem=a.ordem), '+;
                               '       a.chv_nf '+;
                               '  from '+valida_nome_tab('sintegra',hNNF['EMPRESA'])+' a '+;
                               '  left join cfop b on b.cfop=a.cfop '+;
                               ' where a.ordem='+::oCTe_GERAIS:rgConcat_sql(hNNF['ORDEM'])+;
                               ' limit 1 ',,,@aSQL)
ENDIF

IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não foi possível localizar a nota fiscal desjada.')
   RETURN(.F.)
ENDIF

WITH OBJECT oOBJ
   :oTIP:Setitem(ASCAN(:oTIP:aItems,IF(aSQL[1,1]='55','NF-e','NF')))
   :oTIP:REFRESH()
   :oTIP:DISABLE()

   :oMOD:DISABLE()

   :oSER:SETTEXT(aSQL[1,2])
   :oSER:DISABLE()
   :oSER:REFRESH()
   
   :oNUM:SETTEXT(ALLTRIM(STR(aSQL[1,3])))
   :oNUM:DISABLE()
   :oNUM:REFRESH()
   
   :oEMI:SETVALUE(aSQL[1,4])
   :oEMI:DISABLE()
   :oEMI:REFRESH()
   
   :oVBC:SETTEXT(aSQL[1,5])
   IF aSQL[1,1]='55'
      :oVBC:DISABLE()
   ELSE
      :oVBC:ENABLE()
   ENDIF
   :oVBC:REFRESH()
   
   :oICM:SETTEXT(aSQL[1,6])
   IF aSQL[1,1]='55'
      :oICM:DISABLE()
   ELSE
      :oICM:ENABLE()
   ENDIF
   :oICM:REFRESH()
   
   :oVBS:SETTEXT(aSQL[1,7])
   IF aSQL[1,1]='55'
      :oVBS:DISABLE()
   ELSE
      :oVBS:ENABLE()
   ENDIF
   :oVBS:REFRESH()
   
   :oVST:SETTEXT(aSQL[1,8])
   IF aSQL[1,1]='55'
      :oVST:DISABLE()
   ELSE
      :oVST:ENABLE()
   ENDIF
   :oVST:REFRESH()
   
   :oVPR:SETTEXT(aSQL[1,9])
   IF aSQL[1,1]='55'
      :oVPR:DISABLE()
   ELSE
      :oVPR:ENABLE()
   ENDIF
   :oVPR:REFRESH()
   
   :oVDC:SETTEXT(aSQL[1,10])
   IF aSQL[1,1]='55'
      :oVDC:DISABLE()
   ELSE
      :oVDC:ENABLE()
   ENDIF
   :oVDC:REFRESH()
   
   :oCFOP:SETTEXT(aSQL[1,11])
   IF aSQL[1,1]='55'
      :oCFOP:DISABLE()
   ELSE
      :oCFOP:ENABLE()
   ENDIF
   :oCFOP:REFRESH()
   
   :oDES_CFOP:SETTEXT(aSQL[1,12])
   :oDES_CFOP:REFRESH()
   
   :oPES:SETTEXT(aSQL[1,13])
   IF aSQL[1,1]='55'
      :oPES:DISABLE()
   ELSE
      :oPES:ENABLE()
   ENDIF
   :oPES:REFRESH()
   
   :oCHV:SETTEXT(aSQL[1,14])
   :oCHV:REFRESH()
END

RETURN(.T.)



Method uiValida_tipo_documento(oOBJ) Class oCTe_HWgui
/*
   abilita / desabilita os campos para os tipos de documentos
   Mauricio Cruz - 17/07/2013
*/
WITH OBJECT oOBJ
   :oMOD:DISABLE()
   :oSER:DISABLE()
   :oNUM:DISABLE()
   :oEMI:DISABLE()
   :oVBC:DISABLE()
   :oICM:DISABLE()
   :oVBS:DISABLE()
   :oVST:DISABLE()
   :oVPR:DISABLE() 
   :oVDC:DISABLE() 
   :oCFOP:DISABLE()
   :oDES_CFOP:DISABLE() 
   :oOwnerbutton1:DISABLE()
   :oOUT:DISABLE()
   :oPES:DISABLE()
   :oCHV:DISABLE()

   IF :oTIP:GETTEXT()='NF'
      :oMOD:ENABLE()
      :oSER:ENABLE()
      :oNUM:ENABLE()
      :oEMI:ENABLE()
      :oVBC:ENABLE()
      :oICM:ENABLE()
      :oVBS:ENABLE()
      :oVST:ENABLE()
      :oVPR:ENABLE() 
      :oVDC:ENABLE() 
      :oCFOP:ENABLE()
      :oOwnerbutton1:ENABLE()
      :oOUT:ENABLE()
      :oPES:ENABLE()
      :oCHV:ENABLE()
   ELSEIF :oTIP:GETTEXT()='NF-e'
      :oCHV:ENABLE()
   ELSEIF :oTIP:GETTEXT()='OUTROS'
      :oNUM:ENABLE()
      :oEMI:ENABLE()
      :oVDC:ENABLE() 
      :oOUT:ENABLE()
   ENDIF
END

RETURN(.T.)



Method uiSalva_doc_originario(oOBJ,oOBJ2,cLAN) Class oCTe_HWgui
/*
   salva para a array o documento originario
   Mauricio Cruz - 17/07/2013
*/
WITH OBJECT oOBJ
   IF :oTIP:GETTEXT()='NF'
      IF EMPTY(:oSER:VARGET())
         ::oCTe_GERAIS:uiAviso('Série do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF
      IF VAL(:oNUM:VARGET())<=0
         ::oCTe_GERAIS:uiAviso('Número do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF      
      IF :oVBC:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor da base de cálculo do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF      
/*      
      IF :oICM:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor do ICMS do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF      
      IF :oVBS:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor da base de cálculo da substituição tributária do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF      
      IF :oVST:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor da substituição tributária do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF      
*/      
      IF :oVPR:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor do Produto do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF
      IF :oVDC:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor do Produto do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF
      IF :oPES:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor do peso do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF
   ELSEIF :oTIP:GETTEXT() == 'NF-e'
      IF LEN(Alltrim(:oCHV:VARGET())) < 44
         ::oCTe_GERAIS:uiAviso('Chave em branco ou faltando caracteres, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF
   ELSEIF :oTIP:GETTEXT() == 'OUTROS'
      IF VAL(:oNUM:VARGET())<=0
         ::oCTe_GERAIS:uiAviso('Número do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF   
      IF :oVDC:VARGET()<=0
         ::oCTe_GERAIS:uiAviso('Valor do documento esta incorreto, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF   
      IF EMPTY(:oOUT:VARGET())
         ::oCTe_GERAIS:uiAviso('Descrição do documento em branco, não é possível gravar este registro!')
         RETURN(.F.)
      ENDIF   
   ENDIF

   WITH OBJECT oOBJ2:oPage1:oPage2:oBr2
      IF cLAN='C'
         AADD(:aArray,{oOBJ:oTIP:GETTEXT(),;
                       oOBJ:oMOD:GETTEXT(),;
                       oOBJ:oSER:VARGET(),;
                       oOBJ:oNUM:VARGET(),;
                       oOBJ:oEMI:GETVALUE(),;
                       oOBJ:oVBC:VARGET(),;
                       oOBJ:oICM:VARGET(),;
                       oOBJ:oVBS:VARGET(),;
                       oOBJ:oVST:VARGET(),;
                       oOBJ:oVPR:VARGET(),;
                       oOBJ:oVDC:VARGET(),;
                       oOBJ:oCFOP:VARGET(),;
                       oOBJ:oDES_CFOP:VARGET(),;
                       oOBJ:oPES:VARGET(),;
                       oOBJ:oCHV:VARGET(),;
                       oOBJ:oOUT:VARGET() })
      ELSE
         :aArray[:nCurrent,01]:=oOBJ:oTIP:GETTEXT()
         :aArray[:nCurrent,02]:=oOBJ:oMOD:GETTEXT()
         :aArray[:nCurrent,03]:=oOBJ:oSER:VARGET()
         :aArray[:nCurrent,04]:=oOBJ:oNUM:VARGET()
         :aArray[:nCurrent,05]:=oOBJ:oEMI:GETVALUE()
         :aArray[:nCurrent,06]:=oOBJ:oVBC:VARGET()
         :aArray[:nCurrent,07]:=oOBJ:oICM:VARGET()
         :aArray[:nCurrent,08]:=oOBJ:oVBS:VARGET()
         :aArray[:nCurrent,09]:=oOBJ:oVST:VARGET()
         :aArray[:nCurrent,10]:=oOBJ:oVPR:VARGET()
         :aArray[:nCurrent,11]:=oOBJ:oVDC:VARGET()
         :aArray[:nCurrent,12]:=oOBJ:oCFOP:VARGET()
         :aArray[:nCurrent,13]:=oOBJ:oDES_CFOP:VARGET()
         :aArray[:nCurrent,14]:=oOBJ:oPES:VARGET()
         :aArray[:nCurrent,15]:=oOBJ:oCHV:VARGET()
         :aArray[:nCurrent,16]:=oOBJ:oOUT:VARGET()
      ENDIF
      :REFRESH()
   END

   :CLOSE()
END


RETURN(.T.)


Method uiDel_doc_orig(oOBJ) Class oCTe_HWgui
/*
   remove uma documento
   Maurico Cruz - 17/07/2013
*/
WITH OBJECT oOBJ:oPage1:oPage2:oBr2
   IF LEN(:aArray)<=0 .OR. !::oCTe_GERAIS:uiSN('Confirmar a remoção do documento originário selecionado ?')
      RETURN(.F.)
   ENDIF
   ADEL(:aArray,:nCurrent,.T.)
   :REFRESH()
END
RETURN(.T.)


Method uiImprime_dact(nCTEid) Class oCTe_HWgui
/*
   Impressão da DACTE
   Mauricio Cruz - 06/06/2013
*/
LOCAL aRET:=HASH()
LOCAL aSQL:={}
LOCAL lDESIGN:=.F., lCANC:=.F.

::oCTe_GERAIS:rgExecuta_Sql('select cte_modelo, '+;
                            '       cte_prot_canc '+;
                            '  from sagi_cte '+;
                            ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTEid),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('CT-e não localizada.')
   RETURN(.F.)
ENDIF
IF aSQL[1,1]=8
   ::oCTe_GERAIS:rgImprimeCTPapel(nCTEid)
   RETURN(.T.)
ENDIF
lCANC:=IF(EMPTY(aSQL[1,2]),.F.,.T.)  

::oCTe_GERAIS:rgExecuta_Sql('select anexo_arquivo, '+;
                            '       anexo_nome '+;
                            '  from sagi_cte_anexo '+;
                            ' where anexo_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTEid)+;
                            '   and anexo_tipo='+::oCTe_GERAIS:rgConcat_sql('CTE'),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('CT-e não transmitida.')
   RETURN(.F.)
ENDIF

IF FILE(::cPastaEnvRes+'\'+ALLTRIM(aSQL[1,2]))
   FERASE(::cPastaEnvRes+'\'+ALLTRIM(aSQL[1,2]))
ENDIF
IF !MEMOWRIT(::cPastaEnvRes+'\'+ALLTRIM(aSQL[1,2]),aSQL[1,1],.F.)
   ::oCTe_GERAIS:uiAviso('Não foi possível gravar o arquivo de XML.')
   RETURN(.F.)
ENDIF

IF ::cCte_Operador='SYGECOM'
   lDESIGN:=::oCTe_GERAIS:uiSN('Deseja executar o designer ?')
ENDIF

HW_Atualiza_Dialogo2('Aguarde, imprimindo a DACTE...')

aRET:=::oCTe_SEFAZ:ctImprimeFastReport(::cPastaEnvRes+'\'+ALLTRIM(aSQL[1,2]),lDESIGN,NIL,lCANC)

IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF

RETURN(.T.)


Method uiCarregaDados(nCTE_ID)
/*
   Carrega as informações para gerar o XML da CTe
   Mauricio Cruz - 26/07/2013
*/
LOCAL aSQL:={}

::oCTe_SEFAZ:cCte_CNPJ:=::cCte_CNPJ
::oCTe_SEFAZ:cCte_IE:=::cCte_IE
::oCTe_SEFAZ:cCte_RAZAO:=::cCte_RAZAO
::oCTe_SEFAZ:cCte_FANTASIA:=::cCte_FANTASIA
::oCTe_SEFAZ:cCte_ENDERECO:=::cCte_ENDERECO
::oCTe_SEFAZ:cCte_NUMERO:=::cCte_NUMERO
::oCTe_SEFAZ:cCte_BAIRRO:=::cCte_BAIRRO
::oCTe_SEFAZ:cCte_Estado:=::cCte_Estado
::oCTe_SEFAZ:cCte_CEP:=::cCte_CEP
::oCTe_SEFAZ:cCte_FONE:=::cCte_FONE
::oCTe_SEFAZ:tpEmis:=::tpEmis
::oCTe_SEFAZ:cVersao_CTe:=ALLTRIM(::cVersao_CTe)
::oCTe_SEFAZ:cVersao_Modal_RODOVIARIO:=::cVersao_Modal_RODOVIARIO
::oCTe_SEFAZ:tpAmb:=::tpAmb
::oCTe_SEFAZ:versaoApp:=::versaoApp
::oCTe_SEFAZ:cCte_Cidade:=::cCte_Cidade
::oCTe_SEFAZ:cJustCont:=::cJustCont
::oCTe_SEFAZ:cPastaSchemas:=::cPastaSchemas
::oCTe_SEFAZ:cSerialCert:=::cSerialCert
::oCTe_SEFAZ:cVersao_DADOS:=::cVersao_DADOS
::oCTe_SEFAZ:lCte_Emulador:=::lCte_Emulador
::oCTe_SEFAZ:cUTC:=::cUTC

::oCTe_GERAIS:rgExecuta_Sql('select a.cte_numerodacte, '+;                // 01
                            '       a.cfop_id, '+;                        // 02
                            '       a.cte_formapagamento, '+;             // 03
                            '       a.cte_modelo, '+;                     // 04
                            '       a.cte_serie, '+;                      // 05
                            '       a.cte_dataemissao, '+;                // 06
                            '       a.cte_horaemissao, '+;                // 07
                            '       a.cte_ibgeorigemprestacao, '+;        // 08
                            '       a.cte_ibgedestinoprestacao, '+;       // 09
                            '       a.cte_tomadorservico, '+;             // 10
                            "       case when trim(b."+::tCte_CLIENTE['cgc']+")<>'' then b."+::tCte_CLIENTE['cgc']+" else b."+::tCte_CLIENTE['cpf']+" end::text, "+;   // 11
                            '       b.'+::tCte_CLIENTE['iest']+', '+;                                                      // 12
                            IF(::tpAmb='2',"'CT-E EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'",'b.'+::tCte_CLIENTE['cliente'])+'::text, '+;  //13
                            '       b.'+::tCte_CLIENTE['fantasia']+', '+;                                                  // 14
                            '       b.'+::tCte_CLIENTE['fone']+', '+;                                                      // 15
                            '       b.'+::tCte_CLIENTE['ende']+', '+;                                                      // 16
                            '       b.'+::tCte_CLIENTE['numende']+', '+;                                                   // 17
                            '       b.'+::tCte_CLIENTE['bairro']+', '+;                                                    // 18
                            '       b.'+::tCte_CLIENTE['cidade']+', '+;                                                    // 19
                            '       b.'+::tCte_CLIENTE['cep']+', '+;                                                       // 20
                            '       b.'+::tCte_CLIENTE['uf']+', '+;                                                        // 21
                            "       case when b."+::tCte_CLIENTE['uf']+"='EX' then b."+::tCte_CLIENTE['cidade']+" else 'BRASIL' end::text, "+;   // 22
                            '       b.'+::tCte_CLIENTE['email']+', '+;                                                     // 23
                            '       a.cte_outrascaracter, '+;                                        // 24
                            '       a.cte_observacao, '+;                                            // 25
                            "       ''::text, "+;  // reservado para obs do fisco                    // 26
                            "       case when trim(c."+::tCte_CLIENTE['cgc']+")<>'' then c."+::tCte_CLIENTE['cgc']+" else c."+::tCte_CLIENTE['cpf']+" end::text, "+;   // 27
                            "       case when trim(c."+::tCte_CLIENTE['iest']+")<>'' then c."+::tCte_CLIENTE['iest']+" else c."+::tCte_CLIENTE['rg']+" end::text, "+;  // 28
                            IF(::tpAmb='2',"'CT-E EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'",'c.'+::tCte_CLIENTE['cliente']+'')+'::text, '+;  //29
                            '       c.'+::tCte_CLIENTE['fone']+', '+;                                                      // 30
                            '       c.'+::tCte_CLIENTE['ende']+', '+;                                                      // 31
                            '       c.'+::tCte_CLIENTE['numende']+', '+;                                                   // 32
                            '       c.'+::tCte_CLIENTE['bairro']+', '+;                                                    // 33
                            '       c.'+::tCte_CLIENTE['cidade']+', '+;                                                    // 34
                            '       c.'+::tCte_CLIENTE['cep']+', '+;                                                       // 35
                            '       c.'+::tCte_CLIENTE['uf']+', '+;                                                        // 36
                            "       case when c."+::tCte_CLIENTE['uf']+"='EX' then c."+::tCte_CLIENTE['cidade']+" else 'BRASIL' end::text, "+;   // 37
                            '       c.'+::tCte_CLIENTE['email']+', '+;                                                     // 38
                            '       a.cte_valorservico, '+;                                          // 39
                            '       a.cte_valorreceber, '+;                                          // 40
                            '       a.cte_imposto, '+;                                               // 41
                            '       a.cte_icmsbasecalc, '+;                                          // 42
                            '       a.cte_icmsaliq, '+;                                              // 43
                            '       a.cte_icmsvalor, '+;                                             // 44
                            '       a.cte_icmsreducaobc, '+;                                         // 45
                            '       a.cte_vbcstret, '+;                                              // 46
                            '       a.cte_vicmsstret, '+;                                            // 47
                            '       a.cte_picmsstret, '+;                                            // 48
                            '       a.cte_vcred, '+;                                                 // 49
                            '       a.cte_vbc, '+;                                                   // 50
                            '       a.cte_predbcoutrauf, '+;                                         // 51
                            '       a.cte_vbcoutrauf, '+;                                            // 52
                            '       a.cte_picmsoutrauf, '+;                                          // 53
                            '       a.cte_vicmsoutrauf, '+;                                          // 54
                            '       a.cte_valortotalmercad, '+;                                      // 55
                            '       a.cte_descricaopredominante, '+;                                 // 56
                            '       a.cte_volumes, '+;                                               // 57
                            '       a.cte_responsavel_seguro, '+;                                    // 58
                            '       a.seguradora, '+;                                                // 59
                            '       a.cte_apolice_seguro, '+;                                        // 60
                            '       a.cte_averbacao_seguro, '+;                                      // 61
                            '       a.cte_valorcarga_averbacao, '+;                                  // 62
                            '       a.cte_pesobruto, '+;                                             // 63
                            "       case when trim(d."+::tCte_TRANSP['cnpj']+")<>'' then d."+::tCte_TRANSP['cnpj']+" else d."+::tCte_TRANSP['cpf']+" end::text, "+;   // 64
                            "       case when trim(d."+::tCte_TRANSP['ie']+")<>'' then d."+::tCte_TRANSP['ie']+" else d."+::tCte_TRANSP['rg']+" end::text, "+;  // 65
                            IF(::tpAmb='2',"'CT-E EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'",'d.'+::tCte_TRANSP['nome']+'')+'::text, '+;  //66
                            '       d.'+::tCte_TRANSP['foneresi']+', '+;                                                  // 67
                            '       d.'+::tCte_TRANSP['endereco']+', '+;                                                  // 68
                            '       d.'+::tCte_TRANSP['numende']+', '+;                                                   // 69
                            '       d.'+::tCte_TRANSP['bairro']+', '+;                                                    // 70
                            '       d.'+::tCte_TRANSP['cidade']+', '+;                                                    // 71
                            '       d.'+::tCte_TRANSP['cep']+', '+;                                                       // 72
                            '       d.'+::tCte_TRANSP['ufcid']+', '+;                                                        // 73
                            "       case when d."+::tCte_TRANSP['ufcid']+"='EX' then d."+::tCte_TRANSP['cidade']+" else 'BRASIL' end::text, "+;   // 74
                            '       d.'+::tCte_TRANSP['email']+', '+;                                                     // 75
                            "       case when trim(e."+::tCte_CLIENTE['cgc']+")<>'' then e."+::tCte_CLIENTE['cgc']+" else e."+::tCte_CLIENTE['cpf']+" end::text, "+;   // 76
                            "       case when trim(e."+::tCte_CLIENTE['iest']+")<>'' then e."+::tCte_CLIENTE['iest']+" else e."+::tCte_CLIENTE['rg']+" end::text, "+;  // 77
                            IF(::tpAmb='2',"'CT-E EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'",'e.'+::tCte_CLIENTE['cliente']+'')+'::text, '+;  //78
                            '       e.'+::tCte_CLIENTE['fone']+', '+;                                                      // 79
                            '       e.'+::tCte_CLIENTE['ende']+', '+;                                                      // 80
                            '       e.'+::tCte_CLIENTE['numende']+', '+;                                                   // 81
                            '       e.'+::tCte_CLIENTE['bairro']+', '+;                                                    // 82
                            '       e.'+::tCte_CLIENTE['cidade']+', '+;                                                    // 83
                            '       e.'+::tCte_CLIENTE['cep']+', '+;                                                       // 84
                            '       e.'+::tCte_CLIENTE['uf']+', '+;                                                        // 85
                            "       case when e."+::tCte_CLIENTE['uf']+"='EX' then e."+::tCte_CLIENTE['cidade']+" else 'BRASIL' end::text, "+;   // 86
                            '       e.'+::tCte_CLIENTE['email']+', '+;                                                     // 87
                            '       a.cte_tiposervico, '+;                                                                 // 88
                            '       a.cte_unidade, '+;                                                                     // 89
                            '       a.cte_tipo_medida, '+;                                                                 // 90
                            '       a.cte_tipo, '+;                                                                        // 91
                            '       a.cte_chave_completa '+;                                                               // 92
                            '  from sagi_cte a '+;
                            ' left join '+::tCte_CLIENTE['cag_cli']+' b on b.'+::tCte_CLIENTE['codcli']+'=a.remetente_id '+;
                            ' left join '+::tCte_CLIENTE['cag_cli']+' c on c.'+::tCte_CLIENTE['codcli']+'=a.destinatario_id '+;
                            ' left join '+::tCte_TRANSP['transp']+' d on d.'+::tCte_TRANSP['codigo']+'=a.expedidor_id '+;
                            ' left join '+::tCte_CLIENTE['cag_cli']+' e on e.'+::tCte_CLIENTE['codcli']+'=a.recebedor_id '+;
                            ' where a.cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)

IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não foi possível localizar a CT-e desejada.')
   RETURN(.F.)
ENDIF

::oCTe_SEFAZ:nCte_NUMERO                      := aSQL[1,01]
::oCTe_SEFAZ:xml_numerodacte                  := aSQL[1,01]
::oCTe_SEFAZ:xml_cfop_id                      := aSQL[1,02]
::oCTe_SEFAZ:xml_formapagamento               := aSQL[1,03]
::oCTe_SEFAZ:xml_modelo                       := aSQL[1,04]
::oCTe_SEFAZ:xml_serie                        := aSQL[1,05]
::oCTe_SEFAZ:xml_dataemissao                  := aSQL[1,06]
::oCTe_SEFAZ:xml_horaemissao                  := aSQL[1,07]
::oCTe_SEFAZ:xml_ibgeorigemprestacao          := aSQL[1,08]
::oCTe_SEFAZ:xml_ibgedestinoprestacao         := aSQL[1,09]
::oCTe_SEFAZ:xml_tomadorservico               := aSQL[1,10]
::oCTe_SEFAZ:xml_CNP_remetente                := aSQL[1,11]
::oCTe_SEFAZ:xml_IERG_remetente               := aSQL[1,12]
::oCTe_SEFAZ:xml_nome_remetente               := aSQL[1,13]
::oCTe_SEFAZ:xml_fantasia_rementente          := aSQL[1,14]
::oCTe_SEFAZ:xml_fone_rementente              := aSQL[1,15]
::oCTe_SEFAZ:xml_endereco_rementente          := aSQL[1,16]
::oCTe_SEFAZ:xml_numero_rementente            := aSQL[1,17]
::oCTe_SEFAZ:xml_bairro_rementente            := aSQL[1,18]
::oCTe_SEFAZ:xml_cidade_rementente            := aSQL[1,19]
::oCTe_SEFAZ:xml_cep_rementente               := aSQL[1,20]
::oCTe_SEFAZ:xml_uf_rementente                := aSQL[1,21]
::oCTe_SEFAZ:xml_pais_rementente              := aSQL[1,22]
::oCTe_SEFAZ:xml_email_rementente             := aSQL[1,23]
::oCTe_SEFAZ:xml_outrascaracter               := aSQL[1,24]
::oCTe_SEFAZ:xml_observacao                   := aSQL[1,25]
::oCTe_SEFAZ:xml_obs_fisco                    := aSQL[1,26]
::oCTe_SEFAZ:xml_CNP_destinatario             := aSQL[1,27]
::oCTe_SEFAZ:xml_IERG_destinatario            := aSQL[1,28]
::oCTe_SEFAZ:xml_nome_destinatario            := aSQL[1,29]
::oCTe_SEFAZ:xml_fone_destinatario            := aSQL[1,30]
::oCTe_SEFAZ:xml_endereco_destinatario        := aSQL[1,31]
::oCTe_SEFAZ:xml_numero_destinatario          := aSQL[1,32]
::oCTe_SEFAZ:xml_bairro_destinatario          := aSQL[1,33]
::oCTe_SEFAZ:xml_cidade_destinatario          := aSQL[1,34]
::oCTe_SEFAZ:xml_cep_destinatario             := aSQL[1,35]
::oCTe_SEFAZ:xml_uf_destinatario              := aSQL[1,36]
::oCTe_SEFAZ:xml_pais_destinatario            := aSQL[1,37]
::oCTe_SEFAZ:xml_email_destinatario           := aSQL[1,38]
::oCTe_SEFAZ:xml_valorservico                 := aSQL[1,39]
::oCTe_SEFAZ:xml_valorreceber                 := aSQL[1,40]
::oCTe_SEFAZ:xml_imposto                      := aSQL[1,41]
::oCTe_SEFAZ:xml_icmsbasecalc                 := aSQL[1,42]
::oCTe_SEFAZ:xml_icmsaliq                     := aSQL[1,43]
::oCTe_SEFAZ:xml_icmsvalor                    := aSQL[1,44]
::oCTe_SEFAZ:xml_icmsreducaobc                := aSQL[1,45]
::oCTe_SEFAZ:xml_vbcstret                     := aSQL[1,46]
::oCTe_SEFAZ:xml_vicmsstret                   := aSQL[1,47]
::oCTe_SEFAZ:xml_picmsstret                   := aSQL[1,48]
::oCTe_SEFAZ:xml_vcred                        := aSQL[1,49]
::oCTe_SEFAZ:xml_vbc                          := aSQL[1,50]
::oCTe_SEFAZ:xml_predbcoutrauf                := aSQL[1,51]
::oCTe_SEFAZ:xml_vbcoutrauf                   := aSQL[1,52]
::oCTe_SEFAZ:xml_picmsoutrauf                 := aSQL[1,53]
::oCTe_SEFAZ:xml_vicmsoutrauf                 := aSQL[1,54]
::oCTe_SEFAZ:xml_valortotalmercad             := aSQL[1,55]
::oCTe_SEFAZ:xml_descricaopredominante        := aSQL[1,56]
//::oCTe_SEFAZ:xml_volumes                      := aSQL[1,57]
::oCTe_SEFAZ:xml_responsavel_seguro           := aSQL[1,58]
::oCTe_SEFAZ:xml_seguradora                   := aSQL[1,59]
::oCTe_SEFAZ:xml_apolice_seguro               := aSQL[1,60]
::oCTe_SEFAZ:xml_averbacao_seguro             := aSQL[1,61]
::oCTe_SEFAZ:xml_valorcarga_averbacao         := aSQL[1,62]
::oCTe_SEFAZ:xml_peso_bruto                   := aSQL[1,63]
::oCTe_SEFAZ:xml_CNP_expedidor                := aSQL[1,64]
::oCTe_SEFAZ:xml_IERG_expedidor               := aSQL[1,65]
::oCTe_SEFAZ:xml_nome_expedidor               := aSQL[1,66]
::oCTe_SEFAZ:xml_fone_expedidor               := aSQL[1,67]
::oCTe_SEFAZ:xml_endereco_expedidor           := aSQL[1,68]
::oCTe_SEFAZ:xml_numero_expedidor             := aSQL[1,69]
::oCTe_SEFAZ:xml_bairro_expedidor             := aSQL[1,70]
::oCTe_SEFAZ:xml_cidade_expedidor             := aSQL[1,71]
::oCTe_SEFAZ:xml_cep_expedidor                := aSQL[1,72]
::oCTe_SEFAZ:xml_uf_expedidor                 := aSQL[1,73]
::oCTe_SEFAZ:xml_pais_expedidor               := aSQL[1,74]
::oCTe_SEFAZ:xml_email_expedidor              := aSQL[1,75]
::oCTe_SEFAZ:xml_CNP_recebedor                := aSQL[1,76]
::oCTe_SEFAZ:xml_IERG_recebedor               := aSQL[1,77]
::oCTe_SEFAZ:xml_nome_recebedor               := aSQL[1,78]
::oCTe_SEFAZ:xml_fone_recebedor               := aSQL[1,79]
::oCTe_SEFAZ:xml_endereco_recebedor           := aSQL[1,80]
::oCTe_SEFAZ:xml_numero_recebedor             := aSQL[1,81]
::oCTe_SEFAZ:xml_bairro_recebedor             := aSQL[1,82]
::oCTe_SEFAZ:xml_cidade_recebedor             := aSQL[1,83]
::oCTe_SEFAZ:xml_cep_recebedor                := aSQL[1,84]
::oCTe_SEFAZ:xml_uf_recebedor                 := aSQL[1,85]
::oCTe_SEFAZ:xml_pais_recebedor               := aSQL[1,86]
::oCTe_SEFAZ:xml_email_recebedor              := aSQL[1,87]
::oCTe_SEFAZ:xml_Tipo_Servico                 := aSQL[1,88]
::oCTe_SEFAZ:xml_unidade                      := aSQL[1,89]
::oCTe_SEFAZ:xml_tipo_medida                  := aSQL[1,90]
::oCTe_SEFAZ:xml_tpCTe                        := aSQL[1,91]
::oCTe_SEFAZ:xml_chave_comple                 := aSQL[1,92]

::oCTe_GERAIS:rgExecuta_Sql('select a.cte_rntrc, '+;
                            '       a.cte_dataprevistaentrega, '+;
                            '       case when a.cte_lotacao then 1 else 0 end::int'+;
                            '  from sagi_cte a '+;
                            ' where a.cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)
IF LEN(aSQL)>0
   ::oCTe_SEFAZ:xml_modal_rntrc                := aSQL[1,1]
   ::oCTe_SEFAZ:xml_modal_dataprevistaentrega  := aSQL[1,2]
   ::oCTe_SEFAZ:xml_modal_lotacao              := aSQL[1,3]
ENDIF

::oCTe_GERAIS:rgExecuta_Sql('select a.docs_tipo, '+;           // 01
                            '       a.docs_mod, '+;            // 02
                            '       a.docs_serie, '+;          // 03
                            '       a.docs_ndoc, '+;           // 04
                            '       a.docs_demi, '+;           // 05
                            '       a.docs_vbc, '+;            // 06
                            '       a.docs_vicms, '+;          // 07
                            '       a.docs_vbcst, '+;          // 08
                            '       a.docs_vst, '+;            // 09
                            '       a.docs_vprod, '+;          // 10
                            '       a.docs_vnf, '+;            // 11
                            '       a.docs_ncfop, '+;          // 12
                            '       a.docs_npeso, '+;          // 13
                            '       a.docs_chavenfe, '+;       // 14
                            '       a.docs_descricaooutros '+; // 15
                            '  from sagi_cte_docs a '+;
                            ' where docs_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+;
                            ' order by 1',,,@::oCTe_SEFAZ:xml_DOCUMENTOS)

::oCTe_GERAIS:rgExecuta_Sql('select b.servico, '+;
                            '       a.prest_valor*a.prest_quant '+;
                            '  from sagi_cte_prestacao_servico a '+;
                            '  left join tipserv b on b.codserv=a.prest_id_cte_cad_servico '+;
                            'where prest_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@::oCTe_SEFAZ:xml_SERVICOS)

::oCTe_GERAIS:rgExecuta_Sql('Select VEIC_CODIGO, VEIC_RENAVAM, VEIC_PLACA, VEIC_TARA, VEIC_CAPAC_KG, VEIC_CAPAC_M3, VEIC_TP_PROPR, VEIC_TP_VEICULO, VEIC_TP_RODADO, VEIC_TP_CARROC, VEIC_UF_LICENC '+;
                            'From SAGI_CTE_VEICULOS ' +;
                            'Where CTE_ID = '+Concat_Sql(nCTE_ID),,,@::oCTe_SEFAZ:xml_VEICULOS)
                             
::oCTe_GERAIS:rgExecuta_Sql('select a.pedagio_cnpj_for, '+;
                            '       a.pedagio_comprovante, '+;
                            '       a.pedagio_cnpj_res, '+;
                            '       a.pedagio_valor '+;
                            '  from sagi_cte_pedagio a '+;
                            ' where a.cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@::oCTe_SEFAZ:xml_pedagio)

RETURN(.T.)

Method uiVer_dacte_xml() Class oCTe_HWgui
/*
   Visualiza a DACTE de um arquivo XML
   Mauricio Cruz - 12/06/2013
*/
LOCAL cXMLarq:=''
LOCAL aRET:=HASH()
LOCAL lDESIGN:=.F.

cXMLarq:=PEGA_ARQUIVO( {'Arquivo de Nota Fiscal (*.xml)'},{'*.xml'} )

IF EMPTY(cXMLarq) .OR. UPPER(RIGHT(cXMLarq,3))<>'XML'
   ::oCTe_GERAIS:uiAviso('Formato de arquivo inválido. Favor verificar.')
   RETURN(.F.)
ENDIF   

IF ::cCte_Operador='SYGECOM'
   lDESIGN:=SN('Deseja executar o designer ?')
ENDIF

HW_Atualiza_Dialogo2('Aguarde, imprimindo a DACTE...')
HABILITA_TIMER(.F.)

aRET:=::oCTe_SEFAZ:ctImprimeFastReport(cXMLarq,lDESIGN )
IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF
HABILITA_TIMER(.T.)

RETURN(.T.)


Method ctTransmite(nCTE_ID) Class oCTe_HWgui
/*
   transmite a CT-e
   Mauricio Cruz - 19/07/2013
*/
LOCAL aRET:=HASH()
LOCAL cXMLenv:='', cXMLret:='', cARQ:='', cREC:=''
LOCAL aSQL:={}
LOCAL lERR:=.F.

::oCTe_GERAIS:rgExecuta_Sql('select cte_dataautorizacao, '+;    // 01
                            '       cte_chaveacesso, '+;        // 02
                            '       cte_protocolo, '+;          // 03
                            '       cte_recibo, '+;             // 04
                            '       cte_prot_inut, '+;          // 05
                            '       cte_prot_canc, '+;          // 06
                            '       cte_modelo '+;              // 07
                            '  from sagi_cte '+;
                            ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não foi possível localizar a CT-e desejada.')
   RETURN(.F.)
ENDIF

IF aSQL[1,7]<>57
   ::oCTe_GERAIS:uiAviso('CT diferente de modelo eletrônico.')
   RETURN(.F.)
ENDIF

IF !EMPTY(aSQL[1,5])
   ::oCTe_GERAIS:uiAviso('A CT-e selecionada encontra-se inutilizada.')
   RETURN(.F.)
ENDIF
IF !EMPTY(aSQL[1,6])
   ::oCTe_GERAIS:uiAviso('A CT-e selecionada encontra-se cancelada.')
   RETURN(.F.)
ENDIF
IF !EMPTY(aSQL[1,3])
   ::oCTe_GERAIS:uiAviso('A CT-e selecionada já encontra-se autorizada no SEFAZ.')
   RETURN(.F.)
ENDIF

IF !::uiCarregaDados(nCTE_ID)
   RETURN(.F.)
ENDIF

IF !EMPTY(aSQL[1,4])
   IF !::oCTe_GERAIS:uiSN('A CT-e selecionada já esta recpcionada no SEFAZ.'+HB_OsNewLine()+;
                          'Deseja consultar o processo agora ?')
      RETURN(.F.)
   ENDIF
   aRET:=::oCTe_SEFAZ:ctRetornoRecepcao(aSQL[1,4])
   IF !aRET['STATUS']
      ::oCTe_GERAIS:uiAviso(aRET['MSG'])
      RETURN(.F.)
   ENDIF
   RETURN(.T.)
ENDIF

// GERA XML
aRET:=::oCTe_SEFAZ:ctXMLGeral()
IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF
cXMLenv:=aRET['XML']

IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"         
   SHOWMSG_EDIT(cXMLenv,'XML ANTES DE ASSINAR')
ENDIF

// ASSINA XML
aRET:=::oCTe_SEFAZ:ctAssinaXML(cXMLenv,::oCTe_SEFAZ:cCte_Chave,'CTe')
IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF
cXMLenv:=aRET['XML']

IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"         
   SHOWMSG_EDIT(cXMLenv,'XML ASSINADO')
ENDIF

// valida CTe com assinatura
aRET:=::oCTe_SEFAZ:ctValidaXML(cXMLenv)
IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF

// cria lote e valida com o lote
cXMLenv:='<enviCTe versao="'+::cVersao_CTe+'" xmlns="http://www.portalfiscal.inf.br/cte"><idLote>'+ALLTRIM(STR(::oCTe_SEFAZ:nCte_NUMERO))+'</idLote>'+cXMLenv+'</enviCTe>'

IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"         
   SHOWMSG_EDIT(cXMLenv,'XML ANTES DE ENVIAR O LOTE')
ENDIF

aRET:=::oCTe_SEFAZ:ctValidaXML(cXMLenv)
IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF

// grava arquivo de pedido
cARQ:=::cPastaEnvRes+'/ped_'+::oCTe_SEFAZ:cCte_Chave+'.xml'
IF FILE(cARQ)
   FERASE(cARQ)
ENDIF
IF !MEMOWRIT(cARQ,cXMLenv,.F.)
   ::oCTe_GERAIS:uiAviso('Não foi possível gravar o arquivo XML de envio de CT-e.')
   RETURN(.F.)
ENDIF

IF !::lCte_Emulador
   // empacota no SOAP ACTION
   IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"
      SHOWMSG_EDIT(cXMLenv,'XML ASSINADO')
   ENDIF
   cXMLenv:=::oCTe_SEFAZ:ctSoapAction(cXMLenv,'CteRecepcao')

   IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"
      SHOWMSG_EDIT(cXMLenv,'XML COM SOAP ACTION')
   ENDIF
   
   // envia a CT-e
   aRET:=::oCTe_SEFAZ:ctComunicaWebService(cXMLenv,'http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcao','CteRecepcao')
   IF !aRET['STATUS']
      ::oCTe_GERAIS:uiAviso(aRET['MSG'])
      RETURN(.F.)
   ENDIF
   cXMLret:=aRET['XML']
   IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"
      SHOWMSG_EDIT(cXMLret,'RETORNO DO ENVIO DE LOTE')   
   ENDIF
ELSE
   cXMLret:='<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Header><cteCabecMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcao"><cUF>50</cUF><versaoDados>'+::cVersao_CTe+'</versaoDados></cteCabecMsg></soap:Header><soap:Body><cteRecepcaoLoteResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcao"><retEnviCte xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'"><tpAmb>2</tpAmb><cUF>50</cUF><verAplic>MS_PL_CTe_104</verAplic><cStat>103</cStat><xMotivo>Lote recebido com sucesso</xMotivo><infRec><nRec>000000000000000</nRec><dhRecbto>2013-08-23T10:12:09</dhRecbto><tMed>1</tMed></infRec></retEnviCte></cteRecepcaoLoteResult></soap:Body></soap:Envelope>'
ENDIF

// Le a resposta do SEFAZ
TRY
   aRET:=::oCTe_SEFAZ:ctPegaRetornoSEFAZ(cXMLret)
   IF VAL(aRET['cStat'])>=200
      ::oCTe_GERAIS:uiAviso(aRET['xMotivo'])
      lERR:=.T.
   ENDIF
CATCH
   lERR:=.T.
END

IF lERR // DEU ERRO VOLTA
   ::oCTe_GERAIS:uiAviso('Erro ao pegar o retorno do Sefaz, tente novamente.')
   RETURN(.F.)
ENDIF

/*
IF !::oCTe_GERAIS:uiSN(aRET['xMotivo']+HB_OsNewLine()+;
           'Recibo Nº: '+aRET['nRec']+HB_OsNewLine()+;
           'Em: '+DTOC(::oFuncoes:DesFormatDate( LEFT(aRET['dhRecbto'],10) ))+HB_OsNewLine()+;
           'As: '+RIGHT(aRET['dhRecbto'],8)+HB_OsNewLine()+;
           'Tempo de Processamento: '+aRET['tMed']+' segundo(s)'+HB_OsNewLine()+;
           'Deseja consultar o processo agora ?')
   RETURN(.F.)
ENDIF
*/

IF VAL(aRET['tMed'])>180
   aRET['tMed']:=5
ENDIF
MILLISEC(VAL(aRET['tMed'])*1000)  // AGUARDA O TEMPO MÉDIO PARA FAZER A CONSULTA

//envia a consulta do recibo
cREC:=aRET['nRec']
aRET:=::oCTe_SEFAZ:ctRetornoRecepcao(cREC)
IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF

// anexa o protocolo ao arquivo XML de envio
cXMLenv:=STRTRAN(MEMOREAD(cARQ),'<CTe xmlns="http://www.portalfiscal.inf.br/cte">','<CTe>')
cXMLenv:='<cteProc versao="'+::cVersao_CTe+'" xmlns="http://www.portalfiscal.inf.br/cte">'+;
            '<CTe>'+;
               ::oFuncoes:pegaTag(cXMLenv,'CTe')+;
            '</CTe>'+;
            '<protCTe versao="'+::cVersao_CTe+'">'+;
               aRET['infProt']+;
            '</protCTe>'+;
         '</cteProc>'
         
IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"         
   SHOWMSG_EDIT(cXMLenv,'XML COM O PROTOCOLO')
ENDIF
//cXMLenv:='<?xml version="1.0" encoding="UTF-8" ?><cteProc xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'">'+MEMOREAD(cARQ)+aRET['infProt']+'</cteProc>'

aRET['dhRecbto']:=::oFuncoes:DesFormatDate(LEFT(aRET['dhRecbto'],10))
IF DAY(aRET['dhRecbto'])<=0
   aRET['dhRecbto']:=DATE()
ENDIF

// grava a transmissão
::oCTe_GERAIS:rgBeginTransaction()
::oCTe_GERAIS:rgExecuta_Sql('update sagi_cte set cte_recibo='+::oCTe_GERAIS:rgConcat_sql(cREC)+','+;
                                                'cte_chaveacesso='+::oCTe_GERAIS:rgConcat_sql(::oCTe_SEFAZ:cCte_Chave)+','+;
                                                'cte_protocolo='+::oCTe_GERAIS:rgConcat_sql(aRET['nProt'])+','+;
                                                'cte_dataautorizacao='+::oCTe_GERAIS:rgConcat_sql(aRET['dhRecbto'])+;
                            ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID))

::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_anexo(anexo_id_cte,'+;
                                                       'anexo_tipo,'+;
                                                       'anexo_nome,'+;
                                                       'anexo_arquivo,'+;
                                                       'anexo_data,'+;
                                                       'anexo_hora,'+;
                                                       'anexo_usuario) values ('+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+','+;
                                                                                 ::oCTe_GERAIS:rgConcat_sql('CTE')+','+;
                                                                                 ::oCTe_GERAIS:rgConcat_sql(::oCTe_SEFAZ:cCte_Chave+'.xml')+','+;
                                                                                 ::oCTe_GERAIS:rgConcat_sql(cXMLenv)+','+;
                                                                                 ::oCTe_GERAIS:rgConcat_sql(DATE())+','+;
                                                                                 ::oCTe_GERAIS:rgConcat_sql(TIME())+','+;
                                                                                 ::oCTe_GERAIS:rgConcat_sql(::cCte_Operador)+')')
::oCTe_GERAIS:rgEndTransaction()

IF ::oCTe_GERAIS:uiSN('CT-e transmitida com sucesso.'+HB_OsNewLine()+;
           'Deseja imprimir a DACTE ?')
   ::uiImprime_dact(nCTE_ID)
ENDIF

IF ::oCTe_GERAIS:uiSN('Deseja enviar esta CT-e por email ?')
   ::uiEnviarPorEmail(NIL,nCTE_ID)
ENDIF

RETURN(.T.)


Method ctInutiliza(oBrw) Class oCTe_HWgui
/*
   Inutilizacao de CT-e
   Mauricio Cruz - 23/07/2013
*/
LOCAL oDlg, oSta
LOCAL oGroup1, oGroup2
LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5
LOCAL oMOD, oSER, oINI, oFIM, oOBS
LOCAL oButtonex1, oButtonex2
LOCAL cMOD:='57', cSER:='', cOBS:=''
LOCAL nINI:=0, nFIM:=0, mI:=0
LOCAL aSQL:={}, aSER:={}, aINU:={}
LOCAL aRET:=HASH()
LOCAL lCANC:=.F.

::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_SERIES['serie']+;
                            '  from '+::tCte_SERIES['series']+;
                            ' where '+::tCte_SERIES['tipo']+'='+::oCTe_GERAIS:rgConcat_sql('CT-ELETRONICA')+;
                            '   and '+::tCte_SERIES['empresa']+'='+::oCTe_GERAIS:rgConcat_sql(::cCte_Filial),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não há séries cadastradas. Favor revisar.')
   RETURN(.F.)
ENDIF
FOR mI:=1 TO LEN(aSQL)
   AADD(aSER,ALLTRIM(STR(aSQL[mI,1])))
NEXT
cSER:=aSER[1]

WHILE .T.
   INIT DIALOG oDlg TITLE "Inutilização de CT-e"    AT 0, 0 SIZE 595,298 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
        ON INIT {||  oLabel5:CAPTION:='Minimo: 15, Maximo: 255, Usados: '+ALLTRIM(STR(LEN(oOBS:GETTEXT()))) };
        STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_SYSMENU+WS_SIZEBOX ICON HIcon():AddResource(::nCte_Icont)

   oDlg:minHeight := 310
   oDlg:minWidth := 605

   @ 002,000 GROUPBOX oGroup1 CAPTION "Faixa a ser inutilizada"  SIZE 586,54 STYLE BS_LEFT COLOR x_BLUE
                      oGroup1:Anchor := 11 

   @ 005,025 SAY oLabel1 CAPTION "Modelo:"  SIZE 47,21
   @ 053,022 GET COMBOBOX oMOD VAR cMOD  ITEMS {'57'} SIZE 76,24 TEXT;
             TOOLTIP 'Selecione o modelo a ser inutilizado'

   @ 147,025 SAY oLabel2 CAPTION "Série:"  SIZE 36,21
   @ 182,022 GET COMBOBOX oSER VAR cSER  ITEMS aSER SIZE 52,24 TEXT;
             TOOLTIP 'Selecione a série a ser inutilizada'

   @ 286,025 SAY oLabel3 CAPTION "De:"  SIZE 23,21
   @ 308,022 GET oINI VAR nINI SIZE 80,24  PICTURE '9999999999';
             TOOLTIP 'Informe o número inicial a ser inutilizado'

   @ 405,025 SAY oLabel4 CAPTION "ate"  SIZE 22,21
   @ 443,022 GET oFIM VAR nFIM SIZE 80,24  PICTURE '9999999999';
             TOOLTIP 'Informe o número final a ser inutilizado'

   @ 002,056 GROUPBOX oGroup2 CAPTION "Motivo da inutilização"  SIZE 586,174 STYLE BS_LEFT COLOR x_BLUE
                      oGroup2:Anchor := 15 

   @ 005,074 GET oOBS VAR cOBS SIZE 576,151;
             STYLE ES_MULTILINE+ES_AUTOVSCROLL+WS_VSCROLL+ES_WANTRETURN;
             ON CHANGE{|| oLabel5:CAPTION:='Minimo: 15, Maximo: 255, Usados: '+ALLTRIM(STR(LEN(oOBS:GETTEXT()))),;
                          IF(LEN(oOBS:GETTEXT())>254, oOBS:SETTEXT(LEFT(oOBS:GETTEXT(),254)),.T.) }
             oOBS:Anchor := 15 

   @ 002,233 SAY oLabel5 CAPTION "Minimo: 000, Máximo: 000, Usados: 000"  SIZE 335,21
                 oLabel5:Anchor := 4 

   @ 348,232 BUTTONEX oButtonex1 CAPTION "&Continuar"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
             BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
             ON CLICK{|| IF(LEN(oOBS:GETTEXT())<15,::oCTe_GERAIS:uiAviso('Favor informar no mínimo 15 caracteres.'),oDlg:CLOSE()) }
             oButtonex1:Anchor := 12 

   @ 468,232 BUTTONEX oButtonex2 CAPTION "Cancela&r"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
             BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
             ON CLICK{|| lCANC:=.T., oDlg:CLOSE() }
             oButtonex2:Anchor := 12 

   ADD STATUS oSta TO oDlg 
   ACTIVATE DIALOG oDlg 

   IF lCANC
      RETURN(.F.)
   ENDIF

   IF nINI<=0 .OR. nFIM<=0
      ::oCTe_GERAIS:uiAviso('Favor informar a numeração inicial e final para a inutilização.' )
      LOOP
   ENDIF
   IF nFIM<nINI
      ::oCTe_GERAIS:uiAviso('Favor informar a numeração final maior que a numeração inicial.' )
      LOOP
   ENDIF

   aINU:={}
   FOR mI:=nINI TO nFIM
      ::oCTe_GERAIS:rgExecuta_Sql('select cte_protocolo, '+;   // 01
                                  '       cte_recibo, '+;      // 02
                                  '       cte_prot_canc, '+;   // 03
                                  '       cte_prot_inut, '+;   // 04
                                  '       cte_modelo, '+;      // 05
                                  '       cte_id '+;           // 06
                                  '  from sagi_cte '+;
                                  ' where cte_numerodacte='+::oCTe_GERAIS:rgConcat_sql(mI)+;
                                  '   and cte_serie='+::oCTe_GERAIS:rgConcat_sql(cSER)+;
                                  '   and cte_modelo='+::oCTe_GERAIS:rgConcat_sql(cMOD),,,@aSQL)
      IF LEN(aSQL)>0
         IF aSQL[1,5]<>57
            ::oCTe_GERAIS:uiAviso('CT diferente de modelo eletrônico.')
            EXIT
         ENDIF
         IF !EMPTY(aSQL[1,4])
            ::oCTe_GERAIS:uiAviso('A CTe '+ALLTRIM(STR(mI))+' já encontra-se inutilizada.' )
            EXIT
         ENDIF
         IF !EMPTY(aSQL[1,3])
            ::oCTe_GERAIS:uiAviso('A CTe '+ALLTRIM(STR(mI))+' já encontra-se cancelada.' )
            EXIT
         ENDIF
         IF !EMPTY(aSQL[1,1]) .OR. !EMPTY(aSQL[1,1])
            ::oCTe_GERAIS:uiAviso('A CTe '+ALLTRIM(STR(mI))+' já encontra-se transmitida.' )
            EXIT
         ENDIF
      ENDIF

      AADD(aINU,{mI,VAL(cSER),VAL(cMOD),IF(LEN(aSQL)>0,aSQL[1,6],0)})
   NEXT

   IF mI-1<>nFIM
      LOOP
   ENDIF

   // inutiliza no sefaz
   ::oCTe_SEFAZ:tpEmis:=::tpEmis
   ::oCTe_SEFAZ:cPastaSchemas:=::cPastaSchemas
   ::oCTe_SEFAZ:cSerialCert:=::cSerialCert
   ::oCTe_SEFAZ:cVersao_DADOS:=::cVersao_DADOS
   ::oCTe_SEFAZ:cCte_CNPJ:=::cCte_CNPJ
   ::oCTe_SEFAZ:cCte_Estado:=::cCte_Estado
   ::oCTe_SEFAZ:cVersao_CTe:=::cVersao_CTe
   ::oCTe_SEFAZ:tpAmb:=::tpAmb
   ::oCTe_SEFAZ:aCte_INUTILIZAR:=aINU
   ::oCTe_SEFAZ:cCte_MOTIVO:=cOBS
   ::oCTe_SEFAZ:lCte_Emulador:=::lCte_Emulador
   ::oCTe_SEFAZ:cUTC:=::cUTC
   aRET:=::oCTe_SEFAZ:ctInutilizaCTe()
   IF !aRET['STATUS']
      ::oCTe_GERAIS:uiAviso(aRET['MSG'])
      LOOP
   ENDIF
   EXIT
ENDDO

// grava a inutilizacao
::oCTe_GERAIS:rgBeginTransaction()
FOR mI:=1 TO LEN(aINU)
   IF aINU[mI,4]<=0
      ::oCTe_GERAIS:rgExecuta_Sql("select adiciona::int from adiciona('sagi_cte','cte_numerodacte,"+;
                                                                      'cte_modelo, '+;
                                                                      'empresa, '+;
                                                                      'cte_dataemissao, '+;
                                                                      "cte_serie',$$"+::oCTe_GERAIS:rgConcat_sql(aINU[mI,1])+','+;
                                                                                      ::oCTe_GERAIS:rgConcat_sql(aINU[mI,3])+','+;
                                                                                      ::oCTe_GERAIS:rgConcat_sql(::cCte_Filial)+','+;
                                                                                      ::oCTe_GERAIS:rgConcat_sql(DATE())+','+;
                                                                                      ::oCTe_GERAIS:rgConcat_sql(aINU[mI,2])+"$$,'cte_id');",,,@aSQL)
      aINU[mI,4]:=aSQL[1,1]
      IF VALTYPE(aINU[mI,4])='C'
         aINU[mI,4]:=VAL(aINU[mI,4])
      ENDIF
   ENDIF
   
   ::oCTe_GERAIS:rgExecuta_Sql('update sagi_cte set cte_prot_inut='+::oCTe_GERAIS:rgConcat_sql(aRET['nProt'])+;
                               ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(aINU[mI,4]))


   ::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_anexo(anexo_id_cte,'+;
                                                          'anexo_tipo,'+;
                                                          'anexo_nome,'+;
                                                          'anexo_arquivo,'+;
                                                          'anexo_data,'+;
                                                          'anexo_hora,'+;
                                                          'anexo_usuario) values ('+::oCTe_GERAIS:rgConcat_sql(aINU[mI,4])+','+;
                                                                                    ::oCTe_GERAIS:rgConcat_sql('INUTILIZACAO')+','+;
                                                                                    ::oCTe_GERAIS:rgConcat_sql(aRET['ID']+'.xml')+','+;
                                                                                    ::oCTe_GERAIS:rgConcat_sql(aRET['XML'])+','+;
                                                                                    ::oCTe_GERAIS:rgConcat_sql(DATE())+','+;
                                                                                    ::oCTe_GERAIS:rgConcat_sql(TIME())+','+;
                                                                                    ::oCTe_GERAIS:rgConcat_sql(::cCte_Operador)+')')
NEXT
::oCTe_GERAIS:rgEndTransaction()

::oCTe_GERAIS:uiAviso('CT-e Inutilizada(s) com sucesso.')

RETURN(.T.)

Method ctCancela(oBrw) Class oCTe_HWgui
/*
   Cancelamento de CT-e
   Mauricio Cruz - 23/07/2013
*/
LOCAL cMOT:=''
LOCAL mI:=0
LOCAL aSQL:={}, aCAN:={}, aINF:={}, aERR:={}
LOCAL aRET:=HASH()

WITH OBJECT oBrw
   IF LEN(:aArray)<=0
      RETURN(.F.)
   ENDIF

   FOR mI:=1 TO LEN(:aArray)
      IF :aArray[mI,1]
         AADD(aCAN,{:aArray[mI,10],:aArray[mI,2],'','',:aArray[mI,7],:aArray[mI,6],:aArray[mI,8] })
      ENDIF
   NEXT

   IF LEN(aCAN)<=0
      AADD(aCAN,{:aArray[:nCurrent,10],:aArray[:nCurrent,2],'','',:aArray[:nCurrent,7],:aArray[:nCurrent,6],:aArray[:nCurrent,8] })
   ENDIF
END

FOR mI:=1 TO LEN(aCAN)
   IF ::oCTe_GERAIS:rgCteJaEstaRecebida(aCAN[mI,1])
      ::oCTe_GERAIS:uiAviso('Esta CT-e '+ALLTRIM(STR(aCAN[mI,2]))+' já tem contas a receber recebidas e não pode ser cancelada. Favor estornar o recebimento primeiro.')   
      RETURN(.F.)
   ENDIF

   ::oCTe_GERAIS:rgExecuta_Sql('select cte_protocolo, '+;
                               '       cte_recibo, '+;
                               '       cte_prot_canc, '+;
                               '       cte_prot_inut, '+;
                               '       cte_chaveacesso '+;
                               '  from sagi_cte '+;
                               ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(aCAN[mI,1]),,,@aSQL)

   IF LEN(aSQL)<=0
      ::oCTe_GERAIS:uiAviso('Houve um erro ao tentar localizar a CTe de número '+ALLTRIM(STR(aCAN[mI,2])) )
      RETURN(.F.)
   ENDIF
   IF !EMPTY(aSQL[1,4])
      ::oCTe_GERAIS:uiAviso('A CTe '+ALLTRIM(STR(aCAN[mI,2]))+' já encontra-se inutilizada.' )
      RETURN(.F.)
   ENDIF
   IF !EMPTY(aSQL[1,3])
      ::oCTe_GERAIS:uiAviso('A CTe '+ALLTRIM(STR(aCAN[mI,2]))+' já encontra-se cancelada.' )
      RETURN(.F.)
   ENDIF
   IF aCAN[mI,5]=57 .AND. (EMPTY(aSQL[1,1]) .OR. EMPTY(aSQL[1,5]))
      ::oCTe_GERAIS:uiAviso('A CTe '+ALLTRIM(STR(aCAN[mI,2]))+' ainda não foi transmitida.' )
      RETURN(.F.)
   ENDIF

   aCAN[mI,3]:=ALLTRIM(aSQL[1,5])  // CHAVE
   aCAN[mI,4]:=ALLTRIM(aSQL[1,1])  // PROTOCOLO
   AADD(aINF,{aCAN[mI,2],aCAN[mI,6],aCAN[mI,5],aCAN[mI,7]})
NEXT

IF LEN(aCAN)<=0
   RETURN(.F.)
ENDIF

// pega o motivo
WITH OBJECT oBrw
   cMOT:=::uiMotivo('Motivo do cancelamento',aINF)
END
IF EMPTY(cMOT)
   RETURN(.F.)
ENDIF

// cancela no sefaz
IF ::lCte_ELETRONICO
   ::oCTe_SEFAZ:tpEmis:=::tpEmis
   ::oCTe_SEFAZ:cPastaSchemas:=::cPastaSchemas
   ::oCTe_SEFAZ:cSerialCert:=::cSerialCert
   ::oCTe_SEFAZ:cVersao_DADOS:=::cVersao_DADOS
   ::oCTe_SEFAZ:cCte_CNPJ:=::cCte_CNPJ
   ::oCTe_SEFAZ:cCte_Estado:=::cCte_Estado
   ::oCTe_SEFAZ:cVersao_CTe:=::cVersao_CTe
   ::oCTe_SEFAZ:tpAmb:=::tpAmb
   ::oCTe_SEFAZ:cCte_MOTIVO:=cMOT
   ::oCTe_SEFAZ:lCte_Emulador:=::lCte_Emulador
   ::oCTe_SEFAZ:cUTC:=::cUTC
ENDIF
FOR mI:=1 TO LEN(aCAN)
   IF ::oCTe_GERAIS:rgCteJaEstaRecebida(aCAN[mI,1])
      ::oCTe_GERAIS:uiAviso('Esta CT-e '+ALLTRIM(STR(aCAN[mI,2]))+' já tem contas a receber recebidas e não pode ser cancelada. Favor estornar o recebimento primeiro.')   
      RETURN(.F.)
   ENDIF

   IF aCAN[mI,5]=57
      ::oCTe_SEFAZ:cCte_Chave:=aCAN[mI,3]
      ::oCTe_SEFAZ:cCte_PROTOCOLO:=aCAN[mI,4]

      IF ::cVersao_CTe='2.00'
         ::oCTe_SEFAZ:nSeqEvento:=1   // SO PODE CANCELAR UMA VEZ
         aRET:=::oCTe_SEFAZ:ctEventoCancelamento()
      ELSE
         aRET:=::oCTe_SEFAZ:ctCancelaCTe()
      ENDIF

      IF !aRET['STATUS']
         ::oCTe_GERAIS:uiAviso(aRET['MSG'])
         AADD(aERR,.T.)
         LOOP
      ENDIF
   ELSE
      aRET['nProt']:='CANCELADA'
      aRET['XML']:=''
   ENDIF

   AADD(aERR,.F.)
   
   ::oCTe_GERAIS:rgBeginTransaction()
   ::oCTe_GERAIS:rgExecuta_Sql('update sagi_cte set cte_prot_canc='+::oCTe_GERAIS:rgConcat_sql(aRET['nProt'])+;
                               ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(aCAN[mI,1]))

   ::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_anexo(anexo_id_cte,'+;
                                              'anexo_tipo,'+;
                                              'anexo_nome,'+;
                                              'anexo_arquivo,'+;
                                              'anexo_data,'+;
                                              'anexo_hora,'+;
                                              'anexo_usuario) values ('+::oCTe_GERAIS:rgConcat_sql(aCAN[mI,1])+','+;
                                                                        ::oCTe_GERAIS:rgConcat_sql('CANCELAMENTO')+','+;
                                                                        ::oCTe_GERAIS:rgConcat_sql(aCAN[mI,3]+'.xml')+','+;
                                                                        ::oCTe_GERAIS:rgConcat_sql(aRET['XML'])+','+;
                                                                        ::oCTe_GERAIS:rgConcat_sql(DATE())+','+;
                                                                        ::oCTe_GERAIS:rgConcat_sql(TIME())+','+;
                                                                        ::oCTe_GERAIS:rgConcat_sql(::cCte_Operador)+')')
                                                                        
   ::oCTe_GERAIS:rgDeletaCtaRec(aCAN[mI,1])
   ::oCTe_GERAIS:rgEndTransaction()
NEXT

IF ASCAN(aERR,.T.)>0
   ::oCTe_GERAIS:uiAviso('Alguma(s) da(s) CT-e selecionada(s) não puderam ser cancelada(s).')
ELSE
   ::oCTe_GERAIS:uiAviso('CT-e cancelada(s) com sucesso.')
ENDIF

RETURN(.T.)


Method uiMotivo(cTit,aINF) Class oCTe_HWgui
/*
   Motivo da inutilizacao ou cancelamento
   Mauricio Cruz - 23/07/2013
*/
LOCAL oDlg, oGroup1, oGroup2, oSta
LOCAL oButtonex1, oButtonex2
LOCAL oLabel1
LOCAL oOBS, oBr1
LOCAL cOBS:=''

IF aINF=NIL
   aINF:={{0,0,0,'DELETA'}}
ENDIF

INIT DIALOG oDlg TITLE cTIT  AT 0, 0 SIZE 755,266 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_SYSMENU+WS_SIZEBOX ICON HIcon():AddResource(::nCte_Icont)

@ 002,000 GROUPBOX oGroup2 CAPTION 'Documentos'  SIZE 751,082 STYLE BS_LEFT  
                   oGroup2:Anchor := 11

@ 007,015 BROWSE oBr1 ARRAY SIZE 741,063 STYLE WS_TABSTOP FONT HFont():Add( '',0,-11,400,,,);
          ON INIT{|| IF(LEN(oBr1:aArray)=1 .AND. oBr1:aArray[1,4]='DELETA',ADEL(oBr1:aArray,1,.T.),.T. ) }
                 oBr1:Anchor := 11
                 oBr1:lESC:=.T.
                 oBr1:aArray := aINF
                 CreateArList( oBr1, aINF )

                 oBr1:aColumns[1]:heading := 'Número'
                 oBr1:aColumns[2]:heading := 'Série'
                 oBr1:aColumns[3]:heading := 'Modelo'
                 oBr1:aColumns[4]:heading := 'Destinatário'
                 
                 oBr1:aColumns[1]:length := 10
                 oBr1:aColumns[2]:length := 05
                 oBr1:aColumns[3]:length := 06
                 oBr1:aColumns[4]:length := 40
                 
                 oBr1:aColumns[1]:picture:='9999999999'
                 oBr1:aColumns[2]:picture:='99999'
                 oBr1:aColumns[3]:picture:='999999'
                 oBr1:aColumns[4]:picture:='@!'

@ 002,080 GROUPBOX oGroup1 CAPTION cTIT  SIZE 751,118 STYLE BS_LEFT  
                   oGroup1:Anchor := 15 

@ 007,102 GET oOBS VAR cOBS SIZE 741,087;
          STYLE ES_MULTILINE+ES_AUTOVSCROLL+WS_VSCROLL+ES_WANTRETURN;
          ON CHANGE{|| oLabel1:CAPTION:='Minimo: 15, Maximo: 255, Usados: '+ALLTRIM(STR(LEN(oOBS:GETTEXT()))),;
                       IF(LEN(oOBS:GETTEXT())>254, oOBS:SETTEXT(LEFT(oOBS:GETTEXT(),254)),.T.) }
          oOBS:Anchor := 15

@ 512,201 BUTTONEX oButtonex1 CAPTION "&Continuar"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
          ON CLICK{|| IF(LEN(ALLTRIM(oOBS:GETTEXT()))<15,::oCTe_GERAIS:uiAviso('Favor informar no mínimo 15 caracteres.'),oDlg:CLOSE()) }
          oButtonex1:Anchor := 12 

@ 633,201 BUTTONEX oButtonex2 CAPTION "Cancela&r"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| cOBS:='', oDlg:CLOSE() }
          oButtonex2:Anchor := 12 

@ 002,202 SAY oLabel1 CAPTION 'Minimo: 15, Maximo: 55, Usados: 0'  SIZE 493,21
              oLabel1:Anchor := 4 

ADD STATUS oSta TO oDlg 
ACTIVATE DIALOG oDlg 

RETURN(ALLTRIM(cOBS))


Method uiRelatorioGeral() Class oCTe_HWgui
/*
   Relatório geral e CT-e
   Mauricio Cruz - 22/08/2013
*/
LOCAL oDlg, oSta
LOCAL oGroup1, oGroup2, oGroup3, oGroup4, oGroup5
LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6, oLabel7, oLabel8, oLabel9
LOCAL oPER, oINI, oFIM, oTODper, oSIT, oSER, oMOD, oREM, oDES, oEXP, oREC, oNOM, oPROD, oITNpre, oIMP, oDOC, oCFOP, oPLA, oRNTRC, oORD
LOCAL oButtonex1, oButtonex2, oButtonex3
LOCAL oOwnerbutton1, oOwnerbutton2
LOCAL cPER:='', cSIT:='', cSER:='', cMOD:='', cNOM:='', cPROD:='', cPLA:=''
LOCAL dINI:=BOM(DATE()), dFIM:=EOM(DATE())
LOCAL lTODper:=.F., lREM:=.F., lDES:=.F., lEXP:=.F., lREC:=.F., lITNpre:=.F., lIMP:=.F., lDOC:=.F. 
LOCAL nCFOP:=0, nRNTRC:=0, nORD:=1, mI:=0
LOCAL aMOD:=IF(::lCte_ELETRONICO,{'57','08'},{'08'}), aSER:={}, aSQL:={}
LOCAL nHANDLE_OLD := Getactivewindow() // salva o handle da janela anterior

cMOD:=aMOD[1]

::oCTe_GERAIS:rgExecuta_Sql('select '+::tCte_SERIES['serie']+;
                            '  from '+::tCte_SERIES['series']+;
                            ' where '+::tCte_SERIES['tipo']+'='+::oCTe_GERAIS:rgConcat_sql(IF(cMOD='57','CT-ELETRONICA','CT-FORMULARIO'))+;
                            '   and '+::tCte_SERIES['empresa']+'='+::oCTe_GERAIS:rgConcat_sql(::cCte_Filial),,,@aSQL)
IF LEN(aSQL)<=0
   ::oCTe_GERAIS:uiAviso('Não há séries cadastradas. Favor revisar.')
   RETURN(.F.)
ENDIF
FOR mI:=1 TO LEN(aSQL)
   AADD(aSER,ALLTRIM(STR(aSQL[mI,1])))
NEXT

cSER:=aSER[1]

INIT DIALOG oDlg TITLE "Relatório geral de conhecimento de transporte"    AT 0, 0 SIZE 529,467 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     ON EXIT{|| HWG_BRINGWINDOWTOTOP(nHANDLE_OLD) };
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_SYSMENU ICON HIcon():AddResource(::nCte_Icont)

@ 003,000 GROUPBOX oGroup1 CAPTION "Período"  SIZE 521,54 STYLE BS_LEFT COLOR x_BLUE

@ 010,020 GET COMBOBOX oPER VAR cPER  ITEMS {'Emissão','Autorizada'} SIZE 125,24;
          TOOLTIP 'Selecione o período'

@ 141,023 SAY oLabel1 CAPTION "De:"  SIZE 22,21
@ 165,020 GET DATEPICKER oINI VAR dINI SIZE 98,24;
          TOOLTIP 'Informe a data inicial'

@ 272,023 SAY oLabel2 CAPTION "ate"  SIZE 23,21
@ 300,020 GET DATEPICKER oFIM VAR dFIM SIZE 98,24;
          TOOLTIP 'Informe a data final'

@ 402,022 GET CHECKBOX oTODper VAR lTODper CAPTION "Todos Períodos"  SIZE 115,22  ; 
          ON CLICK{|| IF(lTODper,(oINI:DISABLE(),oFIM:DISABLE()),(oINI:ENABLE(),oFIM:ENABLE())) };
          TOOLTIP 'Marque esta opção para listar todos os períodos'

@ 003,057 GROUPBOX oGroup2 CAPTION "Situação do Documento"  SIZE 521,58 STYLE BS_LEFT COLOR x_BLUE

@ 010,080 SAY oLabel3 CAPTION "Situação:"  SIZE 59,21
@ 068,077 GET COMBOBOX oSIT VAR cSIT  ITEMS {'TODAS','NÃO TRANSMITIDA','AUTORIZADA','INUTILIZADA','CANCELADA'} SIZE 123,24;
          TOOLTIP 'Selecione a situação do documento desejado'

@ 210,080 SAY oLabel4 CAPTION "Série:"  SIZE 38,21 
@ 248,077 GET COMBOBOX oSER VAR cSER  ITEMS aSER SIZE 60,24 TEXT;
          TOOLTIP 'Selecione a série da CTe desejada'

@ 330,080 SAY oLabel5 CAPTION "Modelo:"  SIZE 51,21
@ 386,077 GET COMBOBOX oMOD VAR cMOD  ITEMS aMOD SIZE 64,24 TEXT; 
          TOOLTIP 'Selecione o modelo da CTe desejada'

@ 003,118 GROUPBOX oGroup3 CAPTION "Contendo"  SIZE 521,178 STYLE BS_LEFT COLOR x_BLUE

@ 009,135 GET CHECKBOX oREM VAR lREM CAPTION "Remetente"  SIZE 87,22;
          TOOLTIP ''

@ 107,135 GET CHECKBOX oDES VAR lDES CAPTION "Destinatário"  SIZE 98,22;
          TOOLTIP ''

@ 215,135 GET CHECKBOX oEXP VAR lEXP CAPTION "Expedidor"  SIZE 89,22;
          TOOLTIP ''

@ 319,135 GET CHECKBOX oREC VAR lREC CAPTION "Recebedor"  SIZE 92,22;
          TOOLTIP ''

@ 009,160 GET oNOM VAR cNOM SIZE 508,24  PICTURE '@!';
          TOOLTIP 'Informe o nome ou parte do nome desejado'

@ 009,187 SAY oLabel6 CAPTION "Produto predominante"  SIZE 130,21
@ 009,209 GET oPROD VAR cPROD SIZE 508,24  PICTURE '@!';
          TOOLTIP 'Informe o produto predominante ou parte da descrição'

@ 009,241 SAY oLabel7 CAPTION "CFOP"  SIZE 44,21
@ 009,263 GET oCFOP VAR nCFOP SIZE 80,24  PICTURE '9999';
          VALID{|| IF(nCFOP>0, ::uiPega_Cfop(@nCFOP,'',oCFOP),.T.) };
          TOOLTIP 'Informe o CFOP desejado para listar nas CTe'

@ 090,263 OWNERBUTTON oOwnerbutton1  SIZE 24,24 FLAT;
          ON CLICK {|| nCFOP:=0, ::uiPega_Cfop(@nCFOP,'',oCFOP) };
          BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
          TOOLTIP 'Localizar um CFOP'

@ 130,241 SAY oLabel8 CAPTION "Placa"  SIZE 39,21
@ 131,263 GET oPLA VAR cPLA SIZE 111,24  PICTURE '@R XXX-9999';
          TOOLTIP 'Informe a placa que deseja listar nas CTe'

@ 244,263 OWNERBUTTON oOwnerbutton2  SIZE 24,24 FLAT;
          ON CLICK {|| cPLA:='', ::oCTe_GERAIS:rgPegaPlaca(@cPLA,NIL,oPLA), oPLA:ENABLE() };
          BITMAP ::nCte_Img_Buscar FROM RESOURCE TRANSPARENT;
          TOOLTIP 'Localizar um CFOP'

@ 278,241 SAY oLabel9 CAPTION "RNTRC/ANTT"  SIZE 84,21
@ 278,263 GET oRNTRC VAR nRNTRC SIZE 239,24  PICTURE '9999999999';
          TOOLTIP 'Informe o RNTRC/ANTT que deseja listar nas CTe'

@ 003,299 GROUPBOX oGroup4 CAPTION "Detalhar"  SIZE 521,48 STYLE BS_LEFT COLOR x_BLUE

@ 009,317 GET CHECKBOX oITNpre VAR lITNpre CAPTION "Itens da prestação de serviço"  SIZE 197,22;
          TOOLTIP 'Marque esta opção para detalhar os itens da prestação de serviço'

@ 223,317 GET CHECKBOX oIMP VAR lIMP CAPTION "Impostos"  SIZE 83,22  ; 
          TOOLTIP 'Marque esta opção para detalhar os impostos'

// qqq isso ta me fudendo a vida...
//@ 321,317 GET CHECKBOX oDOC VAR lDOC CAPTION "Documentos originários"  SIZE 162,22  ; 
//          TOOLTIP 'Marque esta opção para detalhar os documentos originários'

@ 003,348 GROUPBOX oGroup5 CAPTION "Ordenado por"  SIZE 521,51 STYLE BS_LEFT COLOR x_BLUE

@ 009,366 GET COMBOBOX oORD VAR nORD  ITEMS {'Número CTe',;
                                             'Série',;
                                             'Modelo',;
                                             'Emissão',;
                                             'Autorização',;
                                             'Situação',;
                                             'Código do Remetente',;
                                             'Nome do Remetente',;
                                             'Código do Destinatário',;
                                             'Nome do Destinatário',; 
                                             'Produto predominante',;
                                             'Tipo de Serviço',;
                                             'Tomado do Serviço',;
                                             'Volumes',;
                                             'Peso Bruto',;
                                             'Total da Mercadoria',;
                                             'CFOP',;
                                             'Placa',;
                                             'RNTRC/ANTT'} SIZE 510,24 DISPLAYCOUNT 10; 
          TOOLTIP 'Selecione a ordem desejada de listagem do relatório'

@ 166,403 BUTTONEX oButtonex1 CAPTION "&Visualizar" SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddFile(::cCte_Planilha)):handle;
          ON CLICK{|| ::oCTe_GERAIS:rgRelatorioGeral(oDlg,'S',::cCte_Filial) }

@ 285,403 BUTTONEX oButtonex2 CAPTION "&Imprimir"   SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddFile(::cCte_Printer)):handle;
          ON CLICK{|| ::oCTe_GERAIS:rgRelatorioGeral(oDlg,'P',::cCte_Filial) }

@ 404,403 BUTTONEX oButtonex3 CAPTION "&Fechar"     SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| oDlg:CLOSE() }

ADD STATUS oSta TO oDlg 
ACTIVATE DIALOG oDlg NOMODAL

RETURN(.T.)


Method uiConfiguraHorario() Class oCTe_HWgui
/*
   Configura o horario UTC
   Mauricio Cruz - 22/10/2013
*/
IF ::cCte_Estado='RS' .OR.;
   ::cCte_Estado='SC' .OR.;
   ::cCte_Estado='PR' .OR.;
   ::cCte_Estado='SP' .OR.;
   ::cCte_Estado='RJ' .OR.;
   ::cCte_Estado='MG' .OR.;
   ::cCte_Estado='ES' .OR.;
   ::cCte_Estado='GO' .OR.;
   ::cCte_Estado='DF' .OR.;
   ::cCte_Estado='TO'
   IF ::lCte_VERAO
      ::cUTC:='-02:00'
   ELSE
      ::cUTC:='-03:00'
   ENDIF
ELSEIF ::cCte_Estado='MT' .OR.;
       ::cCte_Estado='MS'
   IF ::lCte_VERAO
      ::cUTC:='-03:00'
   ELSE
      ::cUTC:='-04:00'
   ENDIF
ENDIF

RETURN(.T.)



Method uiCartaCorrecao200(oOBJ,nCTE_ID) Class oCTe_HWgui
/*
   Carta de correcao 2.00
   Mauricio Cruz - 23/10/2013
*/
LOCAL oDlg, oSta
LOCAL oGroup1
LOCAL oBr1
LOCAL oButtonex1, oButtonex2
LOCAL cOBS:=''
LOCAL mI:=0
LOCAL lSAI:=.F.
LOCAL aCTE:={}, aITN:={}, aDOC:={}, aDIF:={}, aSQL:={}
LOCAL aRET:=HASH()

::oCTe_GERAIS:rgExecuta_Sql('select a.cte_modalidade, '+;             // 01
                            '       a.cte_tipo, '+;                   // 02
                            '       a.cte_tiposervico, '+;            // 03
                            '       a.cte_tomadorservico, '+;         // 04
                            '       a.cfop_id, '+;                    // 05
                            '       a.cte_descricaopredominante, '+;  // 06
                            '       a.cte_responsavel_seguro, '+;     // 07
                            '       a.cte_valorcarga_averbacao, '+;   // 08
                            '       a.cte_valortotalmercad, '+;       // 09
                            '       a.cte_pesobruto, '+;              // 10
                            '       a.cte_apolice_seguro, '+;         // 11
                            '       a.cte_averbacao_seguro, '+;       // 12
                            '       a.seguradora, '+;                 // 13
                            '       a.cte_outrascaracter, '+;         // 14
                            '       a.cte_rntrc, '+;                  // 15
                            '       a.cte_lotacao, '+;                // 16
                            '       a.cte_dataprevistaentrega, '+;    // 17
                            '       a.cte_formapagamento, '+;         // 18
                            '       a.cte_observacao, '+;             // 19
                            '       a.cte_chaveacesso '+;             // 20
                            '  from sagi_cte a '+;
                            ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aCTE)
IF LEN(aCTE)<=0
   ::oCTe_GERAIS:uiAviso('Não foi possível localizar a cte desejada.')
   RETURN(.F.)
ENDIF

::oCTe_GERAIS:rgExecuta_Sql('select b.servico, '+;                   // 01
                            '       a.prest_valor*a.prest_quant '+;  // 02
                            '  from sagi_cte_prestacao_servico a '+;
                            '  left join tipserv b on b.codserv=a.prest_id_cte_cad_servico '+;
                            ' where a.prest_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aITN)

::oCTe_GERAIS:rgExecuta_Sql('select a.docs_tipo, '+;             // 01
                            '       a.docs_mod, '+;              // 02
                            '       a.docs_serie, '+;            // 03
                            '       a.docs_ndoc, '+;             // 04
                            '       a.docs_demi, '+;             // 05
                            '       a.docs_vbc, '+;              // 06
                            '       a.docs_vicms, '+;            // 07
                            '       a.docs_vbcst, '+;            // 08
                            '       a.docs_vst, '+;              // 09
                            '       a.docs_vprod, '+;            // 10
                            '       a.docs_vnf, '+;              // 11
                            '       a.docs_ncfop, '+;            // 12
                            '       a.docs_npeso, '+;            // 13
                            '       a.docs_chavenfe, '+;         // 14
                            '       a.docs_descricaooutros '+;   // 15
                            '  from sagi_cte_docs a '+;
                            ' where a.docs_id_cte='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aDOC)

WITH OBJECT oOBJ:oPage1
   IF VAL(LEFT(:oMODALIDADE:GETTEXT(),2))<>aCTE[1,1]
      AADD(aDIF,{'Modalidade','ide','modal',LEFT(:oMODALIDADE:GETTEXT(),2),0})
   ENDIF

   IF VAL(LEFT(:oTIPO_CT:GETTEXT(),1))<>aCTE[1,2]
      AADD(aDIF,{'Tipo de CT','ide','tpCTe',LEFT(:oTIPO_CT:GETTEXT(),1),0})
   ENDIF

   IF VAL(LEFT(:oTIP_SERVICO:GETTEXT(),1))<>aCTE[1,3]
      AADD(aDIF,{'Tipo de Serviço','ide','tpServ',LEFT(:oTIP_SERVICO:GETTEXT(),1),0})
   ENDIF

   IF VAL(LEFT(:oTOMADOR:GETTEXT(),1))<>aCTE[1,4]
      AADD(aDIF,{'Tomador do serviço','toma03','toma',LEFT(:oTOMADOR:GETTEXT(),1),0})
   ENDIF

   IF :oCFOP:VARGET()<>aCTE[1,5]
      AADD(aDIF,{'CFOP','ide','CFOP',ALLTRIM(STR(:oCFOP:VARGET())),0})
   ENDIF

   IF ALLTRIM(UPPER(:oPRODUTO:VARGET()))<>ALLTRIM(UPPER(aCTE[1,6]))
      AADD(aDIF,{'Produto predominante','infCarga','proPred',ALLTRIM(:oPRODUTO:VARGET()),0})
   ENDIF

   IF VAL(LEFT(:oRESPONSAVEL:GETTEXT(),1))<>aCTE[1,7]
      AADD(aDIF,{'Responsável','seg','respSeg',LEFT(:oRESPONSAVEL:GETTEXT(),1),0})
   ENDIF

   IF :oVAL_AVERBACAO:VARGET()<>aCTE[1,8]
      AADD(aDIF,{'Valor Averbação','seg','vCarga',ALLTRIM(STR(:oVAL_AVERBACAO:VARGET())),0})
   ENDIF

   IF :oVAL_MERCADORIA:VARGET()<>aCTE[1,9]
      AADD(aDIF,{'Valor da Mercadoria','infCarga','vCarga',ALLTRIM(STR(:oVAL_MERCADORIA:VARGET())),0})
   ENDIF

   IF :oPESO_BRUTO:VARGET()<>aCTE[1,10]
      AADD(aDIF,{'Peso Bruto','infQ','qCarga',ALLTRIM(STR(:oVAL_MERCADORIA:VARGET())),0})
   ENDIF

   IF ALLTRIM(UPPER(:oAPOLICE:VARGET()))<>ALLTRIM(UPPER(aCTE[1,11]))
      AADD(aDIF,{'Nº da Apolice','seg','nApol',ALLTRIM(:oAPOLICE:VARGET()),0})
   ENDIF

   IF ALLTRIM(UPPER(:oAVERBACAO:VARGET()))<>ALLTRIM(UPPER(aCTE[1,12]))
      AADD(aDIF,{'Nº Averbação','seg','nAver',ALLTRIM(:oAVERBACAO:VARGET()),0})
   ENDIF

   IF ALLTRIM(UPPER(:oNOM_SEGURADORA:VARGET()))<>ALLTRIM(UPPER(aCTE[1,13]))
      AADD(aDIF,{'Nome da Seguradora','seg','xSeg',ALLTRIM(:oNOM_SEGURADORA:VARGET()),0})
   ENDIF

   IF ALLTRIM(UPPER(:oOUT_CARACTERISTICAS:VARGET()))<>ALLTRIM(UPPER(aCTE[1,14]))
      AADD(aDIF,{'Outras caracteristicas','infCarga','xOutCat',ALLTRIM(:oOUT_CARACTERISTICAS:VARGET()),0})
   ENDIF

   WITH OBJECT :oPage2
      IF ALLTRIM(:oRNTRC:VARGET())<>ALLTRIM(UPPER(aCTE[1,15]))
         AADD(aDIF,{'RNTRC/ANTT','rodo','RNTRC',ALLTRIM(STR(:oRNTRC:VARGET())),0})
      ENDIF

      /*  Marco Barcelos - 17/03/2014
      IF :oLOTACAO:GETVALUE()<>aCTE[1,16]
         AADD(aDIF,{'Lotação','rodo','lota',IF(:oLOTACAO:GETVALUE(),'1','0'),0})
      ENDIF
      */

      IF :oENTREGa:GETVALUE()<>aCTE[1,17]
         AADD(aDIF,{'Data Prevista da Entrega','rodo','dPrev',::oFuncoes:FormatDate(:oENTREGa:GETVALUE(),'YYYY-MM-DD','-'),0})
      ENDIF

      IF VAL(LEFT(:oFOR_PGT:GETTEXT(),1))<>aCTE[1,18]
         AADD(aDIF,{'Forma de Pagamento','ide','forPag',LEFT(:oFOR_PGT:GETTEXT(),1),0})
      ENDIF
      
      IF ALLTRIM(:oOBS:GETTEXT(),1)<>aCTE[1,19]
         AADD(aDIF,{'Observações','compl','xObs',LEFT(:oOBS:GETTEXT(),1),0})
      ENDIF
      
      WITH OBJECT :oBr1
         IF LEN(aITN)<>LEN(:aArray)
            ::oCTe_GERAIS:uiAviso('A quantidade de itens de prestaçã de serviço não confere.')
            RETURN(.F.)
         ENDIF
         FOR mI:=1 TO LEN(:aArray)
            IF :aArray[mI,2]<>aITN[mI,1]
               AADD(aDIF,{'Descrição item de Serviço','Comp','xNome',:aArray[mI,2],mI})
            ENDIF
            IF ROUND(:aArray[mI,4]*:aArray[mI,3],2)<>ROUND(aITN[mI,2],2)
               AADD(aDIF,{'Valor do item de Serviço','Comp','vComp',ALLTRIM(STR(ROUND(:aArray[mI,4]*:aArray[mI,3],2))),mI})
            ENDIF
         NEXT
      END
      WITH OBJECT :oBr2
         IF LEN(aDOC)<>LEN(:aArray)
            ::oCTe_GERAIS:uiAviso('A quantidade de documentos não confere.')
            RETURN(.F.)
         ENDIF
         FOR mI:=1 TO LEN(:aArray)
            IF VAL(:aArray[mI,2])<>aDOC[mI,2]
               AADD(aDIF,{'Modelo Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'mod',ALLTRIM(:aArray[mI,2]),mI})
            ENDIF
            IF ALLTRIM(:aArray[mI,3])<>ALLTRIM(aDOC[mI,3])
               AADD(aDIF,{'Série Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'serie',ALLTRIM(:aArray[mI,3]),mI})
            ENDIF
            IF ALLTRIM(:aArray[mI,4])<>ALLTRIM(aDOC[mI,4])
               AADD(aDIF,{'Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'nDoc',ALLTRIM(:aArray[mI,4]),mI})
            ENDIF
            IF :aArray[mI,5]<>aDOC[mI,5]
               AADD(aDIF,{'Data de Emissão do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'dEmi',::oFuncoes:FormatDate(:aArray[mI,5],'YYYY-MM-DD','-'),mI})
            ENDIF
            IF :aArray[mI,6]<>aDOC[mI,6]
               AADD(aDIF,{'Valor Base Cálculo Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'vBC',ALLTRIM(STR(:aArray[mI,6])),mI})
            ENDIF
            IF :aArray[mI,7]<>aDOC[mI,7]
               AADD(aDIF,{'Valor do ICMS do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'vICMS',ALLTRIM(STR(:aArray[mI,7])),mI})
            ENDIF
            IF :aArray[mI,8]<>aDOC[mI,8]
               AADD(aDIF,{'Valor Báse Cálculo de S.T do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'vBCST',ALLTRIM(STR(:aArray[mI,8])),mI})
            ENDIF
            IF :aArray[mI,9]<>aDOC[mI,9]
               AADD(aDIF,{'Valor da Subst. Tributária do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'vST',ALLTRIM(STR(:aArray[mI,9])),mI})
            ENDIF
            IF :aArray[mI,10]<>aDOC[mI,10]
               AADD(aDIF,{'Valor dos Produtos do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'vProd',ALLTRIM(STR(:aArray[mI,10])),mI})
            ENDIF
            IF :aArray[mI,11]<>aDOC[mI,11]
               AADD(aDIF,{'Valor do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'vNF',ALLTRIM(STR(:aArray[mI,11])),mI})
            ENDIF
            IF :aArray[mI,12]<>aDOC[mI,12]
               AADD(aDIF,{'CFOP do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'nCFOP',ALLTRIM(STR(:aArray[mI,12])),mI})
            ENDIF
            IF :aArray[mI,14]<>aDOC[mI,13]
               AADD(aDIF,{'Total do Peso do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'nPeso',ALLTRIM(STR(:aArray[mI,14])),mI})
            ENDIF
            IF :aArray[mI,15]<>aDOC[mI,14]
               AADD(aDIF,{'Chave do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'chave',ALLTRIM(:aArray[mI,15]),mI})
            ENDIF
            IF :aArray[mI,16]<>aDOC[mI,15]
               AADD(aDIF,{'Descrição Outros do Documento Originário',IF(ALLTRIM(:aArray[mI,1])='NF','infNF',IF(ALLTRIM(:aArray[mI,1])='NF-e','infNFe','infOutros')),'descOutros',ALLTRIM(STR(:aArray[mI,16])),mI})
            ENDIF
            IF ALLTRIM(:aArray[mI,1])='OUTROS'
               IF :aArray[mI,11]<>aDOC[mI,11]
                  AADD(aDIF,{'Valor Outros do Documento Originário','infOutros','vDocFisc',ALLTRIM(STR(:aArray[mI,11])),mI})
               ENDIF
            ENDIF
         NEXT
      END
   END
END

FOR mI:=1 TO LEN(aDIF)
   IF (aDIF[mI,2]='infNFe' .AND. aDIF[mI,3]<>'chave' .AND. aDIF[mI,3]<>'PIN' .AND. aDIF[mI,3]<>'dPrev') .OR.;
      (aDIF[mI,2]='infOutros' .AND. aDIF[mI,3]<>'descOutros' .AND. aDIF[mI,3]<>'vDocFisc' .AND. aDIF[mI,3]<>'dPrev')
      ADEL(aDIF,mI,.T.)
      mI--
   ENDIF
NEXT

IF LEN(aDIF)<=0
   ::oCTe_GERAIS:uiAviso('Não foram identificados alterações.')
   RETURN(.F.)
ENDIF

INIT DIALOG oDlg TITLE "Alterações da Carta de Correção da CT-e" AT 0, 0 SIZE 575,392 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_SYSMENU+WS_SIZEBOX ICON HIcon():AddResource(::nCte_Icont)

@ 008,018 BROWSE oBr1 ARRAY SIZE 557,298 STYLE WS_TABSTOP+WS_VSCROLL+WS_HSCROLL FONT HFont():Add( '',0,-11,400,,,)
                 oBr1:Anchor := 15 
                 oBr1:aArray := aDIF
                 CreateArList( oBr1, aDIF )
                 
                 oBr1:aColumns[1]:heading := 'Descrição'
                 oBr1:aColumns[2]:heading := 'Grupo'
                 oBr1:aColumns[3]:heading := 'Campo'
                 oBr1:aColumns[4]:heading := 'Alteração'
                 oBr1:aColumns[5]:heading := 'Indice'
                 
                 oBr1:aColumns[1]:length := 70
                 oBr1:aColumns[2]:length := 0
                 oBr1:aColumns[3]:length := 0
                 oBr1:aColumns[4]:length := 30
                 oBr1:aColumns[5]:length := 0
                 
                 oBr1:aColumns[1]:picture:='@!'
                 oBr1:aColumns[2]:picture:='@!'
                 oBr1:aColumns[3]:picture:='@!'
                 oBr1:aColumns[4]:picture:='@!'
                 oBr1:aColumns[5]:picture:='9999'
                 
                 oBr1:aColumns[2]:lHide:=.T.
                 oBr1:aColumns[3]:lHide:=.T.
                 oBr1:DelColumn( 5 )

@ 003,000 GROUPBOX oGroup1 CAPTION "Alterações identificadas"  SIZE 567,324 STYLE BS_LEFT  
                   oGroup1:Anchor := 15 

@ 331,327 BUTTONEX oButtonex1 CAPTION "&Transmitir" SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
          ON CLICK{|| oDlg:CLOSE() }
          oButtonex1:Anchor := 12 

@ 450,327 BUTTONEX oButtonex2 CAPTION "&Fechar" SIZE 120,38 STYLE BS_CENTER+WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| lSAI:=.T., oDlg:CLOSE() }
          oButtonex2:Anchor := 12 

ADD STATUS oSta TO oDlg 
ACTIVATE DIALOG oDlg 


IF lSAI
   RETURN(.F.)
ENDIF

::oCTe_SEFAZ:aCartaCorrecao:={}
FOR mI:=1 TO LEN(aDIF)
   AADD(::oCTe_SEFAZ:aCartaCorrecao,{aDIF[mI,2],aDIF[mI,3],aDIF[mI,4],aDIF[mI,5]})
   cOBS+='Descrição: '+aDIF[mI,1]+', Grupo: '+aDIF[mI,2]+', Campo: '+aDIF[mI,3]+', Alteração: '+aDIF[mI,4]+', Indice: '+ALLTRIM(STR(aDIF[mI,5]))+HB_OsNewLine()
NEXT

::oCTe_GERAIS:rgExecuta_Sql('select count(*) '+;
                            '  from sagi_cte_cce '+;
                            ' where cte_id='+::oCTe_GERAIS:rgConcat_sql(nCTE_ID),,,@aSQL)

::oCTe_SEFAZ:tpEmis:=::tpEmis
::oCTe_SEFAZ:cPastaSchemas:=::cPastaSchemas
::oCTe_SEFAZ:cSerialCert:=::cSerialCert
::oCTe_SEFAZ:cVersao_DADOS:=::cVersao_DADOS
::oCTe_SEFAZ:cCte_Estado:=::cCte_Estado
::oCTe_SEFAZ:lCte_Emulador:=::lCte_Emulador
::oCTe_SEFAZ:nSeqEvento:=IF(LEN(aSQL)<=0 .OR. aSQL[1,1]<=0,1,aSQL[1,1]+1)
::oCTe_SEFAZ:cCte_Chave:=aCTE[1,20]
::oCTe_SEFAZ:tpAmb:=::tpAmb
::oCTe_SEFAZ:cCte_CNPJ:=::cCte_CNPJ
::oCTe_SEFAZ:cVersao_CTe:=::cVersao_CTe
::oCTe_SEFAZ:cUTC:=::cUTC
::uiMsgRun('Aguarde, carta de correção para a CTe...',{|| aRET:=::oCTe_SEFAZ:ctEventoCartaCorrecao()})
IF !aRET['STATUS']
   ::oCTe_GERAIS:uiAviso(aRET['MSG'])
   RETURN(.F.)
ENDIF

::oCTe_GERAIS:rgBeginTransaction()   
::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_cce(cte_id,cte_obs) values('+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+','+::oCTe_GERAIS:rgConcat_sql(cOBS)+')'  )
::oCTe_GERAIS:rgExecuta_Sql('insert into sagi_cte_anexo(anexo_id_cte,'+;
                                                       'anexo_arquivo,'+;
                                                       'anexo_data,'+;
                                                       'anexo_hora,'+;
                                                       'anexo_nome,'+;
                                                       'anexo_usuario, '+;
                                                       'anexo_tipo) values('+::oCTe_GERAIS:rgConcat_sql(nCTE_ID)+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(aRET['XML'])+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(DATE())+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(TIME())+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(::oCTe_SEFAZ:cCte_Chave+'.xml')+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql(::cCte_Operador)+','+;
                                                                             ::oCTe_GERAIS:rgConcat_sql('CARTA DE CORRECAO')+')' )
::oCTe_GERAIS:rgEndTransaction()

SHOWMSG('Carta de Correção registrada com sucesso.')

RETURN(.T.)



Method uiDelLota(oOBJ) Class oCTe_HWgui
/*
   Cadastrar dados da lotação
   Marco Barcelos -14/03/2014
*/
WITH OBJECT oOBJ:oPage1:oPage2:oBr4
   IF LEN(:aArray)<=0 .OR. !::oCTe_GERAIS:uiSN('Confirmar a remoção do veículo selecionado ?')
      RETURN(.F.)
   ENDIF
   ADEL(:aArray,:nCurrent,.T.)
   :REFRESH()
END
RETURN(.T.)


Method uiPegaChaveCteComple(oCTE_COMPLE) Class oCTe_HWgui
/*
   Pega a chave de uma CT-e
   Mauricio Cruz - 17/03/2014
*/
LOCAL aCTE:=LISTA_CTE('PESQ')
LOCAL aSQL:={}

IF LEN(aCTE)<=0
   RETURN(.F.)
ENDIF

EXECUTA_SQL('select cte_chaveacesso '+;
            '  from sagi_cte '+;
            ' where cte_id='+cs(aCTE[1]),,,@aSQL)

IF LEN(aSQL)<=0 .OR. EMPTY(aSQL[1,1])
   SHOWMSG('Não foi possível localizar a chave da CT-e desejada.')
   RETURN(.F.)
ENDIF

IF oCTE_COMPLE<>NIL
   oCTE_COMPLE:SETTEXT(aSQL[1,1])
   oCTE_COMPLE:REFRESH()
ENDIF

/* -------------------------------
   Cadastrar dados da lotação
   Marco Barcelos - 14/03/2014
 -------------------------------*/
Method uiCadLota(oOBJ, cLan, nCTE_ID) Class oCTe_HWgui

LOCAL oDlg
LOCAL oGroup1
LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6, oLabel7, oLabel8, oLabel9, oLabel10, oLabel11
LOCAL oCod, oRenavam, oPlaca, oTara, oCapKg, oCapM3
LOCAL oOwnerbutton1
LOCAL oButtonex1, oButtonex2, oButtonex3
LOCAL cCod:='', cRenavam:='', cPlaca:='', nTara:=0, nCapKg:=0, nCapM3:=0
Local oRadiogroup1, oRadiobutton1, oRadiobutton2, oRadiogroup2, oRadiobutton3, oRadiobutton4, oCombo1, oCombo2, oCombo3
Local nRadiogroup1 := .T., nRadiogroup2 := .F.
Local cCombo1, cCombo2, cCombo3, cSQL := '', aSQL := {}, nLoop := 0

IF cLAN='A'
   WITH OBJECT oOBJ:oPage1:oPage2:oBr4
      IF LEN(:aArray)<=0
         RETURN(.F.)
      ENDIF
      cCod      := :aArray[:nCurrent,01]
      cRenavam  := :aArray[:nCurrent,02]
      cPlaca    := :aArray[:nCurrent,03]
      nTara     := :aArray[:nCurrent,04]
      nCapKg    := :aArray[:nCurrent,05]
      nCapM3    := :aArray[:nCurrent,06]
      nRadiogroup1 := If(:aArray[:nCurrent,07]='P',1,2)
      nRadiogroup2 := :aArray[:nCurrent,08]+1
      cCombo1   := :aArray[:nCurrent,09]
      cCombo2   := :aArray[:nCurrent,10]+1
      cCombo3   := :aArray[:nCurrent,11]
   END
ENDIF

INIT DIALOG oDlg TITLE "Veículo" AT 0,0 SIZE 800,229 FONT HFont():Add( '',0,-13,400,,,) CLIPPER NOEXIT;
     ON INIT{||.T. };
     STYLE DS_CENTER+WS_VISIBLE+WS_CAPTION+WS_MINIMIZEBOX+WS_SYSMENU ICON HIcon():AddResource(::nCte_Icont)

   @ 004,000 GROUPBOX oGroup1 CAPTION "Dados do Veículo"  SIZE 790,180 STYLE BS_LEFT COLOR x_BLUE

   @ 010,025 SAY oLabel1 CAPTION "Código"  SIZE 63,21
   @ 010,050 GET oCod VAR cCod SIZE 80,24  PICTURE '9999999999' MAXLENGTH 10  ;
        TOOLTIP 'Informe o código do veículo'

   @ 117,025 SAY oLabel2 CAPTION "Renavam"  SIZE 76,21
   @ 119,050 GET oRenavam VAR cRenavam SIZE 114,24      MAXLENGTH 11;
   VALID{|| !Empty(cRenavam) };
        TOOLTIP 'Informe o número do Renavam do veículo'

   @ 248,025 SAY oLabel3 CAPTION "Placa" SIZE 53,21
   @ 247,050 GET oPlaca VAR cPlaca SIZE 87,24  PICTURE '@!R AAA-9999'  MAXLENGTH 7  ;
   VALID{|| !Empty(cPlaca) };
        TOOLTIP 'Informe a placa do veículo'

   @ 374,025 SAY oLabel4 CAPTION "Tara"  SIZE 44,21
   @ 376,050 GET oTara VAR nTara SIZE 82,24      MAXLENGTH 6;
   VALID{|| nTara > 0 };
        TOOLTIP 'Informe a tara do veículo'

   @ 495,025 SAY oLabel5 CAPTION "Capacidade Kg"  SIZE 118,19
   @ 499,050 GET oCapKg VAR nCapKg SIZE 119,24  MAXLENGTH 6 ;
   VALID{|| nCapKg > 0 };
        TOOLTIP 'Informe a capacidade do veículo em Kg'

   @ 649,025 SAY oLabel6 CAPTION "Capacidade M3"  SIZE 118,21
   @ 646,050 GET oCapM3 VAR nCapM3 SIZE 131,24     MAXLENGTH 3 ;
   VALID{|| nCapM3 > 0 };
        TOOLTIP 'Informe a capacidade do veículo em M3'

   @ 13,86 GET RADIOGROUP oRadiogroup1 VAR nRadiogroup1  ;
        CAPTION "Tipo de Propriedade"  SIZE 152,80 ;
        STYLE BS_LEFT
        @ 22,111 RADIOBUTTON oRadiobutton1 CAPTION "Próprio"  SIZE 90,22
        @ 22,135 RADIOBUTTON oRadiobutton2 CAPTION "Terceiros"  SIZE 90,22
   END RADIOGROUP
   //oRadiogroup1 SELECTED 1

   @ 183,86 GET RADIOGROUP oRadiogroup2 VAR nRadiogroup2  ;
        CAPTION "Tipo de veículo"  SIZE 130,80 ;
        STYLE BS_LEFT
        @ 197,110 RADIOBUTTON oRadiobutton3 CAPTION "Tração"  SIZE 90,22
        @ 196,137 RADIOBUTTON oRadiobutton4 CAPTION "Reboque"  SIZE 90,22
   END RADIOGROUP
   //oRadiogroup2 SELECTED 1

   @ 335,85 SAY oLabel7 CAPTION "Tipo de rodado"  SIZE 110,21
   @ 336,107 GET COMBOBOX oCombo1 VAR cCombo1  ITEMS {'01 - Truck','02 - Toco','03 - Cavalo Mecânico','04 - VAN','05 - Utilitários','06 - Outros'}  ;
        SIZE 110,24  ;
        TOOLTIP 'Selecione o tipo de rodado do veículo'

   @ 485,86 SAY oLabel8 CAPTION "Tipo de carroceria"  SIZE 135,21
   @ 486,109 GET COMBOBOX oCombo2 VAR cCombo2  ITEMS {'00 - Não aplicável','01 - Aberta','02 - Fechada/Baú','03 - Granelera','04 - Porta Container','05 - Sider'}  ;
        SIZE 110,24  ;
        TOOLTIP 'Selecione o tipo de carroceria do veículo'

   @ 641,87 SAY oLabel9 CAPTION "UF do licenciamento"   SIZE 149,21
   @ 642,108 GET COMBOBOX oCombo3 VAR cCombo3  ITEMS {"AC","AL","AP","AM","BA","CE","DF","GO","ES","MA","MT","MS","MG","PA","PB","PR","PE","PI","RN","RS","RJ","RO","RR","SC","SP","SE","TO","EX"}  DISPLAYCOUNT 10 TEXT ;
        SIZE 110,24

@ 553,188 BUTTONEX oButtonex1 CAPTION "&Salvar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Salvar)):handle;
          ON CLICK{|| ::uiSalvaLotacao(oDlg,oOBJ,cLAN) }

@ 673,188 BUTTONEX oButtonex2 CAPTION "&Fechar"   SIZE 120,38 STYLE BS_CENTER +WS_TABSTOP;
          BITMAP (HBitmap():AddResource(::nCte_Img_Sair)):handle;
          ON CLICK{|| oDlg:CLOSE() }

ACTIVATE DIALOG oDlg

RETURN(.T.)

/* ------------------------------------------------------
   salva para a array com dados da lotação
   Marco Barcelos - 17/03/2014
-------------------------------------------------------*/
Method uiSalvaLotacao(oOBJ,oOBJ2,cLAN) Class oCTe_HWgui

Local cTipoProp:='', nTipVeic:=0, cTipCarroc := '', cUF := '', cTipoRoda := ''

WITH OBJECT oOBJ
   IF EMPTY(:oCapM3:VARGET())
      ::oCTe_GERAIS:uiAviso('Favor informar a capacidade em M3 deste veículo')
      RETURN(.F.)
   ENDIF
   IF EMPTY(:oCapKg:VARGET())
      ::oCTe_GERAIS:uiAviso('Favor informar a capacidade em Kg deste veículo')
      RETURN(.F.)
   ENDIF
   IF EMPTY(:oRENAVAM:VARGET())
      ::oCTe_GERAIS:uiAviso('Favor informar o Renavam do veículo')
      RETURN(.F.)
   ENDIF
   IF Empty(:oPlaca:VARGET())
      ::oCTe_GERAIS:uiAviso('Favor informar a placa do veículo')
      RETURN(.F.)
   ENDIF
   IF :oTara:VARGET()<=0
      ::oCTe_GERAIS:uiAviso('Favor informar a tara do veículo')
      RETURN(.F.)
   ENDIF

   WITH OBJECT oOBJ2:oPage1:oPage2:oBr4
      If oOBJ:oRadiobutton1:GETVALUE()
         cTipoProp := 'P'
      Else
         cTipoProp := 'T'
      Endif
      If oOBJ:oRadiobutton3:GETVALUE()
         nTipVeic := 0
      Else
         nTipVeic := 1
      Endif
      cTipoRoda := Left(oOBJ:oCombo1:VARGET(),2)
      cTipCarroc :=  Left(oOBJ:oCombo2:VARGET(),2)
      cUF :=  oOBJ:oCombo3:VARGET()
      IF cLAN='C'
         AADD(:aArray,{ oOBJ:oCOD:VARGET(), oOBJ:oRenavam:VARGET(), oOBJ:oPlaca:VARGET(), oOBJ:oTara:VARGET(), oOBJ:oCapKg:VARGET(),;
              oOBJ:oCapM3:VARGET(), cTipoProp, nTipVeic, cTipoRoda, cTipCarroc, cUF })
      ELSE
         :aArray[:nCurrent,01] := oOBJ:oCod:VARGET()
         :aArray[:nCurrent,02] := oOBJ:oRenavam:VARGET()
         :aArray[:nCurrent,03] := oOBJ:oPlaca:VARGET()
         :aArray[:nCurrent,04] := oOBJ:oTara:VARGET()
         :aArray[:nCurrent,05] := oOBJ:oCapKg:VARGET()
         :aArray[:nCurrent,06] := oOBJ:oCapM3:VARGET()
         :aArray[:nCurrent,07] := cTipoProp
         :aArray[:nCurrent,08] := nTipVeic
         :aArray[:nCurrent,09] := cTipoRoda
         :aArray[:nCurrent,10] := cTipCarroc
         :aArray[:nCurrent,11] := cUF
      ENDIF
      :REFRESH()
   END
   :CLOSE()
END
RETURN(.T.)



Method uiCad_pedagio(oOBJ,cLAN) Class oCTe_HWgui
/*
   Cadastro de dados do pedágio
   Mauricio Cruz - 18/03/2014
*/
LOCAL oTELA:=oSygTela()

WITH OBJECT oOBJ:oPage1:oPage2:oBr5
   IF cLAN='A' .AND. LEN(:aArray)<=0
      RETURN(.F.)
   ENDIF
END

oTELA:cTitulo:='Pedágio'
oTELA:nWidth:=559
oTELA:nHeight:=255
oTELA:lModal:=.T.
oTELA:bDesenhaTela:={|| TELA_PEDAGIO(oTELA,oOBJ,cLAN)  }
oTELA:aBotoes:= {{'&Salvar' ,{|| SALVA_PEDAGIO(oTELA,oOBJ,cLAN)  } ,'Salvar os dados do pedágio',(HBitmap():AddResource(1002)):handle }}
oTELA:Execute()

RETURN(.T.)

STATIC FUNCTION SALVA_PEDAGIO(oTELA,oOBJ,cLAN)
/*
   Salva os dados do pedágio
   Mauricio Cruz - 18/03/2014
*/
LOCAL aSQL:={}
LOCAL cCNPJfor:='', cCNPJcli:=''

WITH OBJECT oTELA:oDlgTela
   IF :oCODfor:VARGET()<=0
      SHOWMSG('Favor informar o fornecedor do vale pedágio.')
      RETURN(.F.)
   ENDIF
   IF EMPTY(:oCPV:VARGET())
      SHOWMSG('Favor informar o comprovante do vale pedágio.')
      RETURN(.F.)
   ENDIF
   IF :oVAL:VARGET()<=0
      SHOWMSG('Favor informar o valor do vale pedágio.')
      RETURN(.F.)
   ENDIF
   
   EXECUTA_SQL('select cgc from cag_for where codfor='+concat_sql(:oCODfor:VARGET()),,,@aSQL)
   IF LEN(aSQL)<=0 .OR. EMPTY(aSQL[1,1])
      SHOWMSG('Não foi possível localizar o CNPJ do fornecedor do vale pedágio.')
      RETURN(.F.)
   ENDIF
   cCNPJfor:=aSQL[1,1]

   IF :oCODcli:VARGET()>0   
      EXECUTA_SQL('select cgc from cag_cli where codcli='+concat_sql(:oCODcli:VARGET()),,,@aSQL)
      IF LEN(aSQL)<=0 .OR. EMPTY(aSQL[1,1])
         SHOWMSG('Não foi possível localizar o CNPJ do responsável pelo pagamento do vale pedágio.')
         RETURN(.F.)
      ENDIF
      cCNPJcli:=aSQL[1,1]
   ENDIF   
   
   IF cLAN='C'
      AADD(oOBJ:oPage1:oPage2:oBr5:aArray,{:oCODfor:VARGET(),:oNOMfor:VARGET(),:oCPV:VARGET(),:oCODcli:VARGET(),:oNOMcli:VARGET(),:oVAL:VARGET(),cCNPJfor,cCNPJcli})
   ELSE
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,1]:=:oCODfor:VARGET()
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,2]:=:oNOMfor:VARGET()
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,3]:=:oCPV:VARGET()
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,4]:=:oCODcli:VARGET()
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,5]:=:oNOMcli:VARGET()
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,6]:=:oVAL:VARGET()
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,7]:=cCNPJfor
      oOBJ:oPage1:oPage2:oBr5:aArray[oOBJ:oPage1:oPage2:oBr5:nCurrent,8]:=cCNPJcli
   ENDIF

   oOBJ:oPage1:oPage2:oBr5:REFRESH()
   :CLOSE()
END



RETURN(.T.)

STATIC FUNCTION TELA_PEDAGIO(oTELA,oOBJ,cLAN)
/*
   Tela de dados do pedágio
   Mauricio Cruz - 18/03/2014
*/
LOCAL oGroup1, oGroup2
LOCAL oLabel1, oLabel2
LOCAL oCPV, oVAL, oCODfor,oCODcli,oNOMfor,oNOMcli
LOCAL oOwnerbutton1, oOwnerbutton2
LOCAL cCPV:='', cNOMfor:='', cNOMcli:=''
LOCAL nVAL:=0, nCODcli:=0, nCODfor:=0
LOCAL oFOR:=oSygTela()
LOCAL oRES:=oSygTela()

IF cLAN='A'
   WITH OBJECT oOBJ:oPage1:oPage2:oBr5
      nCODfor:=:aArray[:nCurrent,1]
      cNOMfor:=:aArray[:nCurrent,2]
      cCPV:=:aArray[:nCurrent,3]
      nCODcli:=:aArray[:nCurrent,4]
      cNOMcli:=:aArray[:nCurrent,5]
      nVAL:=:aArray[:nCurrent,6]
   END
ENDIF

@ 004,000 GROUPBOX oGroup1 CAPTION "Fornecedor"  SIZE 550,57 STYLE BS_LEFT COLOR x_BLUE

@ 012,020 GET oCODfor VAR nCODfor SIZE 80,24  PICTURE '9999999999' MAXLENGTH 10;
          VALID{|| IF(nCODfor>0,PEGAFOR(@nCODfor,@cNOMfor,oCODfor,oNOMfor),.T.)  };
          TOOLTIP 'Informe o código do fornecedor ou deixe vazil para informar o nome'

@ 094,020 GET oNOMfor VAR cNOMfor SIZE 425,24  PICTURE '@!' MAXLENGTH 100;
          VALID{|| IF(nCODfor<=0,PEGAFOR(@nCODfor,@cNOMfor,oCODfor,oNOMfor),.T.)  };
          TOOLTIP 'Informe o nome do fornecedor, parte do nome ou deixe vazil para a lista'

@ 521,020 OWNERBUTTON oOwnerbutton1  SIZE 24,24 FLAT;
          ON CLICK {|| nCODfor:=0, cNOMfor:='',PEGAFOR(@nCODfor,@cNOMfor,oCODfor,oNOMfor) };
          BITMAP 1010 FROM RESOURCE  TRANSPARENT;
          TOOLTIP 'Localizar um fornecedor'

@ 004,060 GROUPBOX oGroup2 CAPTION "Responsável Pelo Pagamento"  SIZE 550,57 STYLE BS_LEFT COLOR x_BLUE
@ 012,083 GET oCODcli VAR nCODcli SIZE 80,24  PICTURE '999999999' MAXLENGTH 10;
          VALID{|| IF(nCODcli>0,PEGACLI(@nCODcli,@cNOMcli,oCODcli,oNOMcli),.T.)  };
          TOOLTIP 'Informe o código do cliente ou deixe vazil para informar o nome'

@ 094,083 GET oNOMcli VAR cNOMcli SIZE 425,24  PICTURE '@!' MAXLENGTH 100;
          VALID{|| IF(nCODcli<=0,PEGACLI(@nCODcli,@cNOMcli,oCODcli,oNOMcli),.T.)  };
          TOOLTIP 'Informe o nome do cliente, parte do nome ou deixe vazil para a lista'

@ 522,083 OWNERBUTTON oOwnerbutton2  SIZE 24,24 FLAT;
          ON CLICK {|| nCODcli:=0, cNOMcli:='',PEGACLI(@nCODcli,@cNOMcli,oCODcli,oNOMcli) };
          BITMAP 1010 FROM RESOURCE  TRANSPARENT;
          TOOLTIP 'Localizar um cliente'

@ 004,131 SAY oLabel1 CAPTION "Comprovante de Compra:"  SIZE 149,21
@ 160,128 GET oCPV VAR cCPV SIZE 207,24  PICTURE '99999999999999999999' MAXLENGTH 20;
          TOOLTIP 'Informe o comprovante da compra'

@ 004,164 SAY oLabel2 CAPTION "Valor do Vale-Pedágio:"  SIZE 136,21  
@ 160,161 GET oVAL VAR nVAL SIZE 207,24  PICTURE '@E 999,999,999.99' MAXLENGTH 13;
          TOOLTIP 'Informe o valor do vale pedágio'

RETURN(.T.)

Method uiDel_pedagio(oOBJ) Class oCTe_HWgui
/*
   Exclui um dado de pedágio
   Mauricio Cruz - 18/03/2014
*/
WITH OBJECT oOBJ:oPage1:oPage2:oBr5
   IF LEN(:aArray)<=0 .OR. !SN('Confirma a exclusão do pedágio selecionado ?')
      RETURN(.F.)
   ENDIF
   ADEL(:aArray,:nCurrent,.T.)
   :REFRESH()
END

Return(.T.)

// * EOF


