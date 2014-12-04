#include "hbclass.ch"
#include "hbnfe.ch"

class hbNFSe_DSF
   DATA oFuncoes INIT hbNFeFuncoes()
   data oCTe_GERAIS INIT oCTe_GERAIS()
   DATA ohbNFe
   DATA Xml

   // Cabecalho
   DATA cab_CodCidade
   DATA cab_CPFCNPJRemetente
   DATA cab_RazaoSocialRemetente
   DATA cab_dtInicio
   DATA cab_dtFim
   DATA cab_QtdRPS
   DATA cab_ValorTotalServicos
   DATA cab_ValorTotalDeducoes
   DATA cab_Versao Init 1
   DATA cab_MetodoEnvio Init 'WS'
   DATA cab_VersaoComponente Init '6.0004'

   // Rps
   DATA rps_InscricaoMunicipalPrestador
   DATA rps_RazaoSocialPrestador
   DATA rps_TipoRPS Init 'RPS'
   DATA rps_SerieRPS Init 'NF'
   DATA rps_NumeroRPS
   DATA rps_DataEmissaoRPS
   DATA rps_SituacaoRPS
   DATA rps_SerieRPSSubstituido
   DATA rps_NumeroRPSSubstituido
   DATA rps_NumeroNFSeSubstituida
   DATA rps_DataEmissaoNFSeSubstituida Init CTOD('01/01/1900')
   DATA rps_SeriePrestacao Init '99'
   DATA rps_InscricaoMunicipalTomador
   DATA rps_CPFCNPJTomador
   DATA rps_RazaoSocialTomador
   DATA rps_DocTomadorEstrangeiro
   DATA rps_TipoLogradouroTomador
   DATA rps_LogradouroTomador
   DATA rps_NumeroEnderecoTomador
   DATA rps_ComplementoEnderecoTomador
   DATA rps_TipoBairroTomador
   DATA rps_BairroTomador
   DATA rps_CidadeTomador
   DATA rps_CidadeTomadorDescricao
   DATA rps_CEPTomador
   DATA rps_EmailTomador
   DATA rps_CodigoAtividade
   DATA rps_AliquotaAtividade
   DATA rps_TipoRecolhimento
   DATA rps_MunicipioPrestacao
   DATA rps_MunicipioPrestacaoDescricao
   DATA rps_Operacao
   DATA rps_Tributacao
   DATA rps_ValorPIS
   DATA rps_ValorCOFINS
   DATA rps_ValorINSS
   DATA rps_ValorIR
   DATA rps_ValorCSLL
   DATA rps_AliquotaPIS
   DATA rps_AliquotaCOFINS
   DATA rps_AliquotaINSS
   DATA rps_AliquotaIR
   DATA rps_AliquotaCSLL
   DATA rps_DescricaoRPS
   DATA rps_DDDPrestador
   DATA rps_TelefonePrestador
   DATA rps_DDDTomador
   DATA rps_TelefoneTomador
   DATA rps_MotCancelamento
   DATA rps_CPFCNPJIntermediario

   // Registros de Itens da RPS
   DATA Itens_DiscriminacaoServico
   DATA Itens_Quantidade
   DATA Itens_ValorUnitario
   DATA Itens_ValorTotal
   DATA Itens_Tributavel

   // Registro das Deducoes
   DATA Deducao_DeducaoPor
   DATA Deducao_TipoDeducao
   DATA Deducao_CPFCNPJReferencia
   DATA Deducao_NumeroNFReferencia
   DATA Deducao_ValorTotalReferencia
   DATA Deducao_PercentualDeduzir
   DATA Deducao_ValorDeduzir

   DATA numero_nota
   DATA codigo_verificacao
   DATA motivo

   Method Registro_Cabecalho()
   Method Registro_RPS()
   Method Registro_Itens_RPS(lABRE,lFECHA)
   Method Registro_Deducao_RPS(lABRE,lFECHA)
   Method Assina_XML()

   Method Finaliza_RPS()

   Method Gera_Chave_SHA1()
   Method DataToYYYY_MM_DD(dDAT,lTIME)
   Method DataToYYYYMMDD(dDAT)
   Method LinkWebService()
   Method ComunicaWebService(cMethod)
   Method ctPegaCNCertificado()
   Method LeRetorno(cRET)
   Method CancelaNFSe()
   Method ValidaXML()

EndCLass


Method Registro_Cabecalho() Class hbNFSe_DSF
/*
   cria o arquivo de remessa
   Mauricio Cruz - 01/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cARQ

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::cab_CodCidade=NIL .OR. ::cab_CodCidade<=0
   aRETORNO['MSG']:='Favor informar o código do município'
ENDIF
IF ::cab_CPFCNPJRemetente=NIL .OR. EMPTY(::cab_CPFCNPJRemetente)
   aRETORNO['MSG']:='Favor informar o CPF / CNPJ do Remetente'
ENDIF
IF ::cab_RazaoSocialRemetente=NIL .OR. EMPTY(::cab_RazaoSocialRemetente)
   aRETORNO['MSG']:='Favor informar a razão social do Remetente'
ENDIF
IF ::cab_dtInicio=NIL .OR. DAY(::cab_dtInicio)<=0
   aRETORNO['MSG']:='Favor informar a data inicial da remessa'
ENDIF
IF ::cab_dtFim=NIL .OR. DAY(::cab_dtFim)<=0
   aRETORNO['MSG']:='Favor informar a data final da remessa'
ENDIF
IF ::cab_ValorTotalServicos=NIL
   ::cab_ValorTotalServicos:=0
ENDIF
IF ::cab_ValorTotalDeducoes=NIL
   ::cab_ValorTotalDeducoes:=0
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML+='<ns1:ReqEnvioLoteRPS xmlns:ns1="http://localhost:8080/WsNFe2/lote" xmlns:tipos="http://localhost:8080/WsNFe2/tp"'+;
      ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'+;
      ' xsi:schemaLocation="http://localhost:8080/WsNFe2/lote http://localhost:8080/WsNFe2/xsd/ReqEnvioLoteRPS.xsd">'

cXML+=   '<Cabecalho>'
cXML+=      '<CodCidade>'+ALLTRIM(STR(::cab_CodCidade))+'</CodCidade>'
cXML+=      '<CPFCNPJRemetente>'+ALLTRIM(::cab_CPFCNPJRemetente)+'</CPFCNPJRemetente>'
cXML+=      '<RazaoSocialRemetente>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::cab_RazaoSocialRemetente))+'</RazaoSocialRemetente>'
cXML+=      '<transacao>true</transacao>'
cXML+=      '<dtInicio>'+::DataToYYYY_MM_DD(::cab_dtInicio)+'</dtInicio>'
cXML+=      '<dtFim>'+::DataToYYYY_MM_DD(::cab_dtFim)+'</dtFim>'
cXML+=      '<QtdRPS>'+ALLTRIM(STR(::cab_QtdRPS))+'</QtdRPS>'
cXML+=      '<ValorTotalServicos>'+ALLTRIM(STR(::cab_ValorTotalServicos))+'</ValorTotalServicos>'
cXML+=      '<ValorTotalDeducoes>'+ALLTRIM(STR(::cab_ValorTotalDeducoes))+'</ValorTotalDeducoes>'
cXML+=      '<Versao>'+ALLTRIM(STR(::cab_Versao))+'</Versao>'
cXML+=      '<MetodoEnvio>'+ALLTRIM(::cab_MetodoEnvio)+'</MetodoEnvio>'
//cXML+=      '<VersaoComponente>'+ALLTRIM(::cab_VersaoComponente)+'</VersaoComponente>'
cXML+=   '</Cabecalho>'

cARQ:=::ohbNFe:pastaEnvRes+'\NFSe'+ALLTRIM(::cab_CPFCNPJRemetente)+DTOS(DATE())+STRTRAN(LEFT(TIME(),8),':')+'.xml'
hb_MemoWrit( cARQ, cXML )

aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=cARQ
aRETORNO['MSG']:='XML criado em '+cARQ

RETURN(aRETORNO)



Method Registro_RPS() Class hbNFSe_DSF
/*
   cria o registro do RPS
   Mauricio Cruz - 01/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cARQ

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::Xml=NIL .OR. EMPTY(::Xml)
   aRETORNO['MSG']:='Arquivo XML com o registro do cabeçalho não informado.'
ENDIF
IF ::rps_InscricaoMunicipalPrestador=NIL .OR. EMPTY(::rps_InscricaoMunicipalPrestador)
   aRETORNO['MSG']:='Favor Informar a Inscrição Municipal do Prestador. Verificar regra de preenchimento do campo no Anexo 03.'
ENDIF
IF ::rps_RazaoSocialPrestador=NIL .OR. EMPTY(::rps_RazaoSocialPrestador)
   aRETORNO['MSG']:='Favor Informar a Razão Social do Prestador.'
ENDIF
IF ::rps_TipoRPS=NIL .OR. EMPTY(::rps_TipoRPS)
   aRETORNO['MSG']:='Favor Informar o Tipo de RPS Padrão "RPS".'
ENDIF
IF ::rps_SerieRPS=NIL .OR. EMPTY(::rps_SerieRPS)
   aRETORNO['MSG']:='Favor Informar a Série do RPS - Padrão "NF".'
ENDIF
IF ::rps_NumeroRPS=NIL .OR. ::rps_NumeroRPS<=0
   aRETORNO['MSG']:='Favor Informar o Número da RPS.'
ENDIF
IF ::rps_NumeroRPS=NIL .OR. ::rps_NumeroRPS<=0
   aRETORNO['MSG']:='Favor Informar o Número da RPS.'
ENDIF
IF ::rps_DataEmissaoRPS=NIL .OR. DAY(::rps_DataEmissaoRPS)<=0
   aRETORNO['MSG']:='Favor Informar o Data de Emissão da RPS.'
ENDIF
IF ::rps_SituacaoRPS=NIL .OR. EMPTY(::rps_SituacaoRPS)
   aRETORNO['MSG']:='Favor Informar a Situação da RPS - "N"-Normal, "C"-Cancelada.'
ENDIF
IF ::rps_SerieRPSSubstituido=NIL
   ::rps_SerieRPSSubstituido:=''
ENDIF

IF ::rps_SituacaoRPS=NIL .OR. EMPTY(::rps_SituacaoRPS)
   aRETORNO['MSG']:='Favor Informar a Situação da RPS - "N"-Normal, "C"-Cancelada.'
ENDIF
IF ::rps_NumeroRPSSubstituido=NIL
   ::rps_NumeroRPSSubstituido:=0
ENDIF
IF ::rps_NumeroNFSeSubstituida=NIL
   ::rps_NumeroNFSeSubstituida:=0
ENDIF
IF ::rps_DataEmissaoNFSeSubstituida=NIL .OR. DAY(::rps_DataEmissaoNFSeSubstituida)<=0
   aRETORNO['MSG']:='Favor Informar a Data de emissão da NFSe Formato= AAAA-MM-DD. Se não for substituto preencher com "01/01/1900".'
ENDIF
IF ::rps_SeriePrestacao=NIL .OR. EMPTY(::rps_SeriePrestacao)
   aRETORNO['MSG']:='Favor Informar o Número do equipamento emissor do RPS ou série de prestação. Caso não utilize a série, preencha o campo com o valor ‘99’ que indica modelo único. Caso queira utilizar o campo série para indicar o número do equipamento emissor do RPS deve-se solicitar liberação da prefeitura.'
ENDIF
IF ::rps_InscricaoMunicipalTomador=NIL .OR. EMPTY(::rps_InscricaoMunicipalTomador)
   aRETORNO['MSG']:='Favor Informar a Inscrição Municipal do Tomador. Caso o tomador não for do municipio não preencher, caso o tomador for do município preencher com a Inscrição Municipal formatada Seguindo Anexo 03.'
ENDIF
IF ::rps_CPFCNPJTomador=NIL .OR. EMPTY(::rps_CPFCNPJTomador)
   aRETORNO['MSG']:='Favor Informar o CPF ou CNPJ do Tomador. Ex: "00000000000191"'
ENDIF
IF ::rps_RazaoSocialTomador=NIL .OR. EMPTY(::rps_RazaoSocialTomador)
   aRETORNO['MSG']:='Favor Informar a Razão Social do Tomador'
ENDIF
IF ::rps_DocTomadorEstrangeiro=NIL
   ::rps_DocTomadorEstrangeiro:=''
   //aRETORNO['MSG']:='Favor Informar o Documento de Identificação de Tomador Estrangeiro. Caso o tomador não for estrangeiro ou não possuir o documento deixar o campo vazio.'
ENDIF
IF ::rps_TipoLogradouroTomador=NIL .OR. EMPTY(::rps_TipoLogradouroTomador)
   aRETORNO['MSG']:='Favor Informar o Tipo de Logradouro do Tomador. Campo de preenchimento livre. Verificar exemplos no anexo 04.'
ENDIF
IF ::rps_LogradouroTomador=NIL .OR. EMPTY(::rps_LogradouroTomador)
   aRETORNO['MSG']:='Favor Informar o Logradouro do Tomador.'
ENDIF
IF ::rps_NumeroEnderecoTomador=NIL .OR. EMPTY(::rps_NumeroEnderecoTomador)
   aRETORNO['MSG']:='Favor Informar o Numero de Endereço do Tomador.'
ENDIF
IF ::rps_ComplementoEnderecoTomador=NIL
   ::rps_ComplementoEnderecoTomador:=''
ENDIF
IF ::rps_TipoBairroTomador=NIL .OR. EMPTY(::rps_TipoBairroTomador)
   aRETORNO['MSG']:='Favor Informar o Tipo de Bairro do Tomador . Campo de preenchimento livre. Verificar exemplos no Anexo 05.'
ENDIF
IF ::rps_BairroTomador=NIL .OR. EMPTY(::rps_BairroTomador)
   aRETORNO['MSG']:='Favor Informar o Bairro do Tomador.'
ENDIF
IF ::rps_CidadeTomador=NIL .OR. ::rps_CidadeTomador<=0
   aRETORNO['MSG']:='Favor Informar o Código da Cidade do Tomador padrão SIAFI. (Confira o nome da cidade no cadastro do cliente)'
ENDIF
IF ::rps_CidadeTomadorDescricao=NIL .OR. EMPTY(::rps_CidadeTomadorDescricao)
   aRETORNO['MSG']:='Favor Informar o Nome da Cidade do Tomador.'
ENDIF
IF ::rps_CEPTomador=NIL .OR. EMPTY(::rps_CEPTomador)
   aRETORNO['MSG']:='Favor Informar o CEP do Tomador Ex: "37900000".'
ENDIF
IF ::rps_EmailTomador=NIL .OR. EMPTY(::rps_EmailTomador)
   ::rps_EmailTomador:='-'
   //aRETORNO['MSG']:='Favor Informar o Email do Tomador. Caso o Tomador não possua email informar o valor "-". Caso queira informar mais de um email colocar ";" separando os emails e no final. Exemplo:nome@bol.com.br;outro@bol.com.br;.'
ENDIF
IF ::rps_CodigoAtividade=NIL .OR. EMPTY(::rps_CodigoAtividade)
   aRETORNO['MSG']:='Favor Informar o Código da Atividade da RPS. (Confira o codigo CNAE no cadastro do cliente)'
ENDIF
IF ::rps_AliquotaAtividade=NIL
   ::rps_AliquotaAtividade:=0
   //aRETORNO['MSG']:='Favor Informar a Alíquota de ISS da Atividade.'
ENDIF
IF ::rps_TipoRecolhimento=NIL .OR. EMPTY(::rps_TipoRecolhimento)
   aRETORNO['MSG']:='Favor Informar o Tipo de Recolhimento - "A" – A Receber, "R" - Retido na Fonte.'
ENDIF
IF ::rps_MunicipioPrestacao=NIL .OR. ::rps_MunicipioPrestacao<=0
   aRETORNO['MSG']:='Favor Informar o Código do Município de Prestação – Padrão SIAFI.'
ENDIF
IF ::rps_MunicipioPrestacao=NIL .OR. ::rps_MunicipioPrestacao<=0
   aRETORNO['MSG']:='Favor Informar o Código do Município de Prestação – Padrão SIAFI.'
ENDIF
IF ::rps_MunicipioPrestacaoDescricao=NIL .OR. EMPTY(::rps_MunicipioPrestacaoDescricao)
   aRETORNO['MSG']:='Favor Informar o Município de Prestação do Serviço.'
ENDIF
IF ::rps_Operacao=NIL .OR. EMPTY(::rps_Operacao)
   aRETORNO['MSG']:='Favor Informar a Operação - "A"-Sem Dedução, "B"-Com Dedução/Materiais, "C" - Imune/Isenta de ISSQN, "D" - Devolução/Simples Remessa, "J" - Intemediação.'
ENDIF
IF ::rps_Tributacao=NIL .OR. EMPTY(::rps_Tributacao)
   aRETORNO['MSG']:='Favor Informar a Tributação: C - Isenta de ISS, E - Não Incidência no Município, F - Imune, K - Exigibilidd Susp.Dec.J/Proc.A, N - Não Tributável, T – Tributável, G - Tributável Fixo, H - Tributável S.N., M - Micro Empreendedor Individual (MEI).'
ENDIF
IF ::rps_ValorPIS=NIL
   ::rps_ValorPIS:=0.00
ENDIF
IF ::rps_ValorCOFINS=NIL
   ::rps_ValorCOFINS:=0.00
ENDIF
IF ::rps_ValorINSS=NIL
   ::rps_ValorINSS:=0.00
ENDIF
IF ::rps_ValorIR=NIL
   ::rps_ValorIR:=0.00
ENDIF
IF ::rps_ValorCSLL=NIL
   ::rps_ValorCSLL:=0.00
ENDIF
IF ::rps_AliquotaPIS=NIL
   ::rps_AliquotaPIS:=0.00
ENDIF
IF ::rps_AliquotaCOFINS=NIL
   ::rps_AliquotaCOFINS:=0.00
ENDIF
IF ::rps_AliquotaINSS=NIL
   ::rps_AliquotaINSS:=0.00
ENDIF
IF ::rps_AliquotaIR=NIL
   ::rps_AliquotaIR:=0.00
ENDIF
IF ::rps_AliquotaCSLL=NIL
   ::rps_AliquotaCSLL:=0.00
ENDIF
IF ::rps_DescricaoRPS=NIL
   ::rps_DescricaoRPS:=''
ENDIF
IF ::rps_DDDPrestador=NIL
   ::rps_DDDPrestador:=''
ENDIF
IF ::rps_TelefonePrestador=NIL
   ::rps_TelefonePrestador:=''
ENDIF
IF ::rps_DDDTomador=NIL
   ::rps_DDDTomador:=''
ENDIF
IF ::rps_TelefoneTomador=NIL
   ::rps_TelefoneTomador:=''
ENDIF
IF ::rps_MotCancelamento=NIL
   ::rps_MotCancelamento:=''
ENDIF
IF ::rps_CPFCNPJIntermediario=NIL
   ::rps_CPFCNPJIntermediario:=''
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::Xml)
FERASE(::Xml)

cXML+=   '<Lote Id="lote:1ABCDZ">'  //'<Lote Id="lote:1ABCDZ">'
cXML+=      '<RPS Id="rps:1">'  //'<RPS Id="rps:2">'
cXML+=         '<Assinatura>'+::Gera_Chave_SHA1()+'</Assinatura>'
cXML+=         '<InscricaoMunicipalPrestador>'+ALLTRIM(::rps_InscricaoMunicipalPrestador)+'</InscricaoMunicipalPrestador>'
cXML+=         '<RazaoSocialPrestador>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_RazaoSocialPrestador))+'</RazaoSocialPrestador>'
cXML+=         '<TipoRPS>'+ALLTRIM(::rps_TipoRPS)+'</TipoRPS>'
cXML+=         '<SerieRPS>'+ALLTRIM(::rps_SerieRPS)+'</SerieRPS>'
cXML+=         '<NumeroRPS>'+ALLTRIM(STR(::rps_NumeroRPS))+'</NumeroRPS>'
cXML+=         '<DataEmissaoRPS>'+::DataToYYYY_MM_DD(::rps_DataEmissaoRPS,.T.)+'</DataEmissaoRPS>'
cXML+=         '<SituacaoRPS>'+ALLTRIM(::rps_SituacaoRPS)+'</SituacaoRPS>'
cXML+=         '<SerieRPSSubstituido>'+ALLTRIM(::rps_SerieRPSSubstituido)+'</SerieRPSSubstituido>'
cXML+=         '<NumeroRPSSubstituido>'+ALLTRIM(STR(::rps_NumeroRPSSubstituido))+'</NumeroRPSSubstituido>'
cXML+=         '<NumeroNFSeSubstituida>'+ALLTRIM(STR(::rps_NumeroNFSeSubstituida))+'</NumeroNFSeSubstituida>'
cXML+=         '<DataEmissaoNFSeSubstituida>'+::DataToYYYY_MM_DD(::rps_DataEmissaoNFSeSubstituida)+'</DataEmissaoNFSeSubstituida>'
cXML+=         '<SeriePrestacao>'+ALLTRIM(::rps_SeriePrestacao)+'</SeriePrestacao>'
cXML+=         '<InscricaoMunicipalTomador>'+ALLTRIM(::rps_InscricaoMunicipalTomador)+'</InscricaoMunicipalTomador>'
cXML+=         '<CPFCNPJTomador>'+ALLTRIM(::rps_CPFCNPJTomador)+'</CPFCNPJTomador>'
cXML+=         '<RazaoSocialTomador>'+ALLTRIM(::rps_RazaoSocialTomador)+'</RazaoSocialTomador>'
cXML+=         '<DocTomadorEstrangeiro>'+ALLTRIM(::rps_DocTomadorEstrangeiro)+'</DocTomadorEstrangeiro>'
cXML+=         '<TipoLogradouroTomador>'+ALLTRIM(::rps_TipoLogradouroTomador)+'</TipoLogradouroTomador>'
cXML+=         '<LogradouroTomador>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_LogradouroTomador))+'</LogradouroTomador>'
cXML+=         '<NumeroEnderecoTomador>'+ALLTRIM(::rps_NumeroEnderecoTomador)+'</NumeroEnderecoTomador>'
cXML+=         '<ComplementoEnderecoTomador>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_ComplementoEnderecoTomador))+'</ComplementoEnderecoTomador>'
cXML+=         '<TipoBairroTomador>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_TipoBairroTomador))+'</TipoBairroTomador>'
cXML+=         '<BairroTomador>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_BairroTomador))+'</BairroTomador>'
cXML+=         '<CidadeTomador>'+ALLTRIM(STR(::rps_CidadeTomador))+'</CidadeTomador>'
cXML+=         '<CidadeTomadorDescricao>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_CidadeTomadorDescricao))+'</CidadeTomadorDescricao>'
cXML+=         '<CEPTomador>'+ALLTRIM(::rps_CEPTomador)+'</CEPTomador>'
cXML+=         '<EmailTomador>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_EmailTomador))+'</EmailTomador>'
cXML+=         '<CodigoAtividade>'+ALLTRIM(::rps_CodigoAtividade)+'</CodigoAtividade>'
cXML+=         '<AliquotaAtividade>'+ALLTRIM(STR(::rps_AliquotaAtividade))+'</AliquotaAtividade>'
cXML+=         '<TipoRecolhimento>'+ALLTRIM(::rps_TipoRecolhimento)+'</TipoRecolhimento>'
cXML+=         '<MunicipioPrestacao>'+ALLTRIM(STR(::rps_MunicipioPrestacao))+'</MunicipioPrestacao>'
cXML+=         '<MunicipioPrestacaoDescricao>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::rps_MunicipioPrestacaoDescricao))+'</MunicipioPrestacaoDescricao>'
cXML+=         '<Operacao>'+ALLTRIM(::rps_Operacao)+'</Operacao>'
cXML+=         '<Tributacao>'+ALLTRIM(::rps_Tributacao)+'</Tributacao>'
cXML+=         '<ValorPIS>'+ALLTRIM(STR(::rps_ValorPIS))+'</ValorPIS>'
cXML+=         '<ValorCOFINS>'+ALLTRIM(STR(::rps_ValorCOFINS))+'</ValorCOFINS>'
cXML+=         '<ValorINSS>'+ALLTRIM(STR(::rps_ValorINSS))+'</ValorINSS>'
cXML+=         '<ValorIR>'+ALLTRIM(STR(::rps_ValorIR))+'</ValorIR>'
cXML+=         '<ValorCSLL>'+ALLTRIM(STR(::rps_ValorCSLL))+'</ValorCSLL>'
cXML+=         '<AliquotaPIS>'+ALLTRIM(STR(::rps_AliquotaPIS))+'</AliquotaPIS>'
cXML+=         '<AliquotaCOFINS>'+ALLTRIM(STR(::rps_AliquotaCOFINS))+'</AliquotaCOFINS>'
cXML+=         '<AliquotaINSS>'+ALLTRIM(STR(::rps_AliquotaINSS))+'</AliquotaINSS>'
cXML+=         '<AliquotaIR>'+LEFT(ALLTRIM(STR(::rps_AliquotaIR)),6)+'</AliquotaIR>'
cXML+=         '<AliquotaCSLL>'+ALLTRIM(STR(::rps_AliquotaCSLL))+'</AliquotaCSLL>'
cXML+=         '<DescricaoRPS>'+ALLTRIM(::rps_DescricaoRPS)+'</DescricaoRPS>'
cXML+=         '<DDDPrestador>'+ALLTRIM(::rps_DDDPrestador)+'</DDDPrestador>'
cXML+=         '<TelefonePrestador>'+ALLTRIM(::rps_TelefonePrestador)+'</TelefonePrestador>'
cXML+=         '<DDDTomador>'+ALLTRIM(::rps_DDDTomador)+'</DDDTomador>'
cXML+=         '<TelefoneTomador>'+ALLTRIM(::rps_TelefoneTomador)+'</TelefoneTomador>'
cXML+=         '<MotCancelamento>'+ALLTRIM(::rps_MotCancelamento)+'</MotCancelamento>'
cXML+=         '<CPFCNPJIntermediario>'+ALLTRIM(::rps_CPFCNPJIntermediario)+'</CPFCNPJIntermediario>'


cXML:=::oFuncoes:RemoveAcentuacao(cXML)

cARQ:=::ohbNFe:pastaEnvRes+'\NFSe'+ALLTRIM(::cab_CPFCNPJRemetente)+ALLTRIM(::rps_InscricaoMunicipalPrestador)+ALLTRIM(::rps_SerieRPS)+DTOS(::rps_DataEmissaoRPS)+ALLTRIM(STR(::rps_NumeroRPS))+'.xml'
hb_MemoWrit( cARQ, cXML )

aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=cARQ
aRETORNO['MSG']:='XML criado em '+cARQ

RETURN(aRETORNO)




Method Registro_Itens_RPS(lABRE,lFECHA) Class hbNFSe_DSF
/*
   Registra os itens de serviços da RPS
   Mauricio Cruz - 02/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::Xml=NIL .OR. EMPTY(::Xml)
   aRETORNO['MSG']:='Arquivo XML com o registro do cabeçalho e RPS não informado.'
ENDIF
IF ::Itens_DiscriminacaoServico=NIL .OR. EMPTY(::Itens_DiscriminacaoServico)
   aRETORNO['MSG']:='Favor informar a Discriminação do Serviço.'
ENDIF
IF ::Itens_Quantidade=NIL .OR. ::Itens_Quantidade<=0
   aRETORNO['MSG']:='Favor informar a Quantidade do serviço tomado.'
ENDIF
IF ::Itens_ValorUnitario=NIL .OR. ::Itens_ValorUnitario<=0
   aRETORNO['MSG']:='Favor informar o Valor Unitário do serviço tomado.'
ENDIF
IF ::Itens_ValorTotal=NIL .OR. ::Itens_ValorTotal<=0
   aRETORNO['MSG']:='Favor informar o Valor total do serviço tomado.'
ENDIF
IF ::Itens_Tributavel=NIL
   ::Itens_Tributavel:=''
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::Xml)
FERASE(::Xml)

cXML+='<Deducoes/>'
IF lABRE
   cXML+='<Itens>'
ENDIF

cXML+='<Item>'
cXML+=   '<DiscriminacaoServico>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::Itens_DiscriminacaoServico))+'</DiscriminacaoServico>'
cXML+=   '<Quantidade>'+ALLTRIM(STR(::Itens_Quantidade))+'</Quantidade>'
cXML+=   '<ValorUnitario>'+LEFT(ALLTRIM(STR(::Itens_ValorUnitario)),4)+'</ValorUnitario>'
cXML+=   '<ValorTotal>'+ALLTRIM(STR(::Itens_ValorTotal))+'</ValorTotal>'
cXML+=   '<Tributavel>'+ALLTRIM(::Itens_Tributavel)+'</Tributavel>'
cXML+='</Item>'

IF lFECHA
   cXML+='</Itens>'
ENDIF

hb_MemoWrit( ::Xml, cXML )

aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=::Xml
aRETORNO['MSG']:='XML criado em '+::Xml

RETURN(aRETORNO)




Method Registro_Deducao_RPS(lABRE,lFECHA)
/*
   Registra os itens de deduções da RPS
   Mauricio Cruz - 02/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::Xml=NIL .OR. EMPTY(::Xml)
   aRETORNO['MSG']:='Arquivo XML com o registro do cabeçalho e RPS não informado.'
ENDIF

IF ::Deducao_DeducaoPor=NIL .OR. EMPTY(::Deducao_DeducaoPor)
   aRETORNO['MSG']:='Favor informar DeducaoPor Valores Possíveis: "Percentual", "alor".'
ENDIF
IF ::Deducao_TipoDeducao=NIL  .OR. UPPER(ALLTRIM(::Deducao_DeducaoPor))='PERCENTUAL'
   ::Deducao_TipoDeducao:=' '
ENDIF
IF !EMPTY(ALLTRIM(::Deducao_TipoDeducao)) .AND. UPPER(ALLTRIM(::Deducao_DeducaoPor))='VALOR' .AND. (UPPER(ALLTRIM(::Deducao_TipoDeducao))<>'Despesas com Materiais' .OR. UPPER(ALLTRIM(::TipoDeducao))<>'Despesas com Sub-empreitada' )
   aRETORNO['MSG']:='Favor informar Tipo de Dedução, Caso a dedução for por "Valor" os valores possíveis são : "Despesas com Materiais" ou "Despesas com Sub-empreitada" Caso a dedução for por "Percentual" informar o campo com valor vazio.'
ENDIF
IF ::Deducao_CPFCNPJReferencia=NIL
   ::Deducao_CPFCNPJReferencia:=''
ENDIF
IF ::Deducao_NumeroNFReferencia=NIL
   ::Deducao_NumeroNFReferencia:=0
ENDIF
IF ::Deducao_ValorTotalReferencia=NIL
   ::Deducao_ValorTotalReferencia:=0
ENDIF
IF ::Deducao_ValorTotalReferencia=NIL .OR. ::Deducao_ValorTotalReferencia<=0
   aRETORNO['MSG']:='Favor informar o Valor total da Nota Fiscal de Referência.'
ENDIF
IF UPPER(ALLTRIM(::Deducao_DeducaoPor))='PERCENTUAL' .AND. (::Deducao_PercentualDeduzir=NIL .OR. ::Deducao_PercentualDeduzir<=0)
   aRETORNO['MSG']:='Favor informar o Percentual a Deduzir.'
ENDIF
IF UPPER(ALLTRIM(::Deducao_DeducaoPor))='VALOR' .AND. (::Deducao_ValorDeduzir=NIL .OR. ::Deducao_ValorDeduzir<=0)
   aRETORNO['MSG']:='Favor informar o Valor a ser Deduzido.'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::Xml)
FERASE(::Xml)

IF lABRE
   cXML+='<Deducoes>'
ENDIF

cXML+='<Deducao>'
cXML+=   '<DeducaoPor>'+ALLTRIM(::Deducao_DeducaoPor)+'</DeducaoPor>'
cXML+=   '<TipoDeducao>'+ALLTRIM(::Deducao_TipoDeducao)+'</TipoDeducao>'
cXML+=   '<CPFCNPJReferencia>'+ALLTRIM(::Deducao_CPFCNPJReferencia)+'</CPFCNPJReferencia>'
cXML+=   '<NumeroNFReferencia>'+ALLTRIM(STR(::Deducao_NumeroNFReferencia))+'</NumeroNFReferencia>'
cXML+=   '<ValorTotalReferencia>'+ALLTRIM(STR(::Deducao_ValorTotalReferencia))+'</ValorTotalReferencia>'
cXML+=   '<PercentualDeduzir>'+ALLTRIM(STR(::Deducao_PercentualDeduzir))+'</PercentualDeduzir>'
cXML+=   '<ValorDeduzir>'+ALLTRIM(STR(::Deducao_ValorDeduzir))+'</ValorDeduzir>'
cXML+='</Deducao>'

IF lFECHA
   cXML+='</Deducoes>'
ENDIF

hb_MemoWrit( ::Xml, cXML )

aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=::Xml
aRETORNO['MSG']:='XML criado em '+::Xml

RETURN(aRETORNO)



Method Finaliza_RPS() Class hbNFSe_DSF
/*
   Finaliza o lote da RPS
   Mauricio Cruz - 02/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::Xml=NIL .OR. EMPTY(::Xml)
   aRETORNO['MSG']:='Arquivo XML com o registro do cabeçalho e RPS não informado.'
ENDIF

cXML:=MEMOREAD(::Xml)
FERASE(::Xml)

cXML+='</RPS>'
cXML+='</Lote>'
cXML+='<Signature></Signature>'
cXML+='</ns1:ReqEnvioLoteRPS>'

hb_MemoWrit( ::Xml, cXML )

aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=::Xml
aRETORNO['MSG']:='XML criado em '+::Xml

RETURN(aRETORNO)


Method Assina_XML() Class hbNFSe_DSF
/*
   Finaliza a estrutura do arquivo XML e assina o XML
   Mauricio Cruz - 02/05/2013
*/
LOCAL oDOMDoc, oXmldsig, oCert, oStoreMem, dsigKey, signedKey
LOCAL aRETORNO:=HASH()
LOCAL cXML, cXMLSig
LOCAL PosIni, PosFim, nP, nResult
LOCAL oError

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::Xml=NIL .OR. EMPTY(::Xml)
   aRETORNO['MSG']:='Arquivo XML com o registro do cabeçalho e RPS não informado.'
ENDIF
cXML:=MEMOREAD(::Xml)
FERASE(::Xml)

cXML:=STRTRAN(cXML,'<Signature></Signature>','<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">'+;
                                             '<SignedInfo>'+;
                                                '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />'+;
                                                '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />'+;
                                                '<Reference URI="#lote:1ABCDZ">'+;
                                                   '<Transforms>'+;
                                                      '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />'+;
                                                      '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />'+;
                                                   '</Transforms>'+;
                                                   '<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />'+;
                                                   '<DigestValue>'+;
                                                  '</DigestValue>'+;
                                                '</Reference>'+;
                                             '</SignedInfo>'+;
                                             '<SignatureValue>'+;
                                             '</SignatureValue>'+;
                                             '<KeyInfo>'+;
                                                '<X509Data>'+;
                                                   '<X509Certificate>'+;
                                                   '</X509Certificate>'+;
                                                '</X509Data>'+;
                                             '</KeyInfo>'+;
                                          '</Signature>')

// Inicializa o objeto do DOMDocument
TRY

      oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )

CATCH
   aRETORNO['MSG']:='Nao foi possível carregar ' + _MSXML2_DOMDocument
   RETURN(aRETORNO)
END
oDOMDoc:async = .F.
oDOMDoc:resolveExternals := .F.
oDOMDoc:validateOnParse  = .T.
oDOMDoc:preserveWhiteSpace = .T.

// inicializa o objeto do MXDigitalSignature
TRY

      oXmldsig := win_OleCreateObject( _MSXML2_MXDigitalSignature )

CATCH
   aRETORNO['MSG']:='Nao foi possível carregar ' +_MSXML2_MXDigitalSignature
   RETURN(aRETORNO)
END

// carrega o arquivo XML para o DOM
oDOMDoc:LoadXML(cXML)
IF oDOMDoc:parseError:errorCode<>0
   aRETORNO['MSG']:=' Assinar: Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_EOL()+;
                    ' Linha: '              + STR(oDOMDoc:parseError:line)+HB_EOL()+;
                    ' Caractere na linha: ' + STR(oDOMDoc:parseError:linepos)+HB_EOL()+;
                    ' Causa do erro: '      + oDOMDoc:parseError:reason+HB_EOL()+;
                    ' code: '               + STR(oDOMDoc:parseError:errorCode)
   RETURN(aRETORNO)
ENDIF

// Localiza as assinaturas no XML
oDOMDoc:setProperty('SelectionNamespaces',"xmlns:ds='http://www.w3.org/2000/09/xmldsig#'")
oXmldsig:signature := oDOMDoc:selectSingleNode('.//ds:Signature')
IF (oXmldsig:signature = nil)
   aRETORNO['MSG'] := 'É preciso carregar o template antes de assinar.'
   RETURN(aRETORNO)
ENDIF

// carrega o objeto do certificado digital
oCert:=::ohbNFe:pegaObjetoCertificado(::ohbNFe:cSerialCert)
IF oCert == Nil
   aRETORNO['MSG']  := 'Certificado não encontrado, Favor revisar a instalação do Certificado'
   RETURN(aRETORNO)
ENDIF

   oStoreMem := win_oleCreateObject('CAPICOM.Store')

TRY
   oStoreMem:open(_CAPICOM_MEMORY_STORE,'Memoria',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
CATCH oError
   aRETORNO['MSG']:='Falha ao alocar o certificado na memoria '+HB_EOL()+ ;
                    'Error: '     + Transform(oError:GenCode, nil)   + ';' +HB_EOL()+ ;
                    'SubC: '      + Transform(oError:SubCode, nil)   + ';' +HB_EOL()+ ;
                    'OSCode: '    + Transform(oError:OsCode,  nil)   + ';' +HB_EOL()+ ;
                    'SubSystem: ' + Transform(oError:SubSystem, nil) + ';' +HB_EOL()+ ;
                    'Mensangem: ' + oError:Description
   RETURN(aRETORNO)
END

// Aloca o certificado na Capicom
TRY
   oStoreMem:Add(oCert)
CATCH oError
   aRETORNO['MSG']:='Falha ao aloca o certificado na memoria da Capicom '+HB_EOL()+;
                    'Error: '     + Transform(oError:GenCode, nil)   + ';' +HB_EOL()+;
                    'SubC: '      + Transform(oError:SubCode, nil)   + ';' +HB_EOL()+;
                    'OSCode: '    + Transform(oError:OsCode,  nil)   + ';' +HB_EOL()+;
                    'SubSystem: ' + Transform(oError:SubSystem, nil) + ';' +HB_EOL()+;
                    'Mensangem: ' + oError:Description
   RETURN(aRETORNO)
END
oXmldsig:store:=oStoreMem

// Cria chave CSP
TRY
   dsigKey:=oXmldsig:createKeyFromCSP(oCert:PrivateKey:ProviderType, oCert:PrivateKey:ProviderName, oCert:PrivateKey:ContainerName, 0)
CATCH
   aRETORNO['MSG']:='Erro ao criar a chave do CSP, talvez o certificado não esteja instalado corretamente.'
   RETURN(aRETORNO)
END
IF (dsigKey = nil)
   aRETORNO['MSG']:='Erro ao criar a chave do CSP.'
   RETURN(aRETORNO)
ENDIF

// Assina a chave do CSP
TRY
   signedKey:=oXmldsig:sign(dsigKey, 2)
CATCH
   aRETORNO['MSG']:='Erro ao assinar a chave do CSP, talvez o certificado não esteja instalado corretamente.'
   RETURN(aRETORNO)
END
IF signedKey=NIL
   aRETORNO['MSG']:='Assinatura Falhou.'
   RETURN(aRetorno)
ENDIF

// Trata o formato da estrutura do XML
cXMLSig := STRTRAN(STRTRAN(oDOMDoc:xml,CHR(10)),CHR(13))
PosIni := AT('<SignatureValue>',cXMLSig)+len('<SignatureValue>')
cXMLSig := SUBS(cXMLSig,1,PosIni-1)+STRTRAN( SUBS(cXMLSig,PosIni,len(cXMLSig)), ' ', '' )
PosIni := AT('<X509Certificate>',cXMLSig)-1
nP = AT('<X509Certificate>',cXMLSig)
nResult := 0
DO WHILE nP<>0
   nResult := nP
   nP = AT('<X509Certificate>',cXMLSig,nP+1)
ENDDO
PosFim := nResult
cXMLSig := SUBS(cXMLSig,1,PosIni)+SUBS(cXMLSig,PosFim,len(cXMLSig))
//cXMLSig:='<?xml version="1.0" encoding="UTF-8" ?>'+cXMLSig

// grava o arquivo no disco
hb_MemoWrit( ::Xml, cXMLSig )

aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=::Xml
aRETORNO['MSG']:='XML assinado com sucesso em '+::Xml

RETURN(aRETORNO)


Method LinkWebService() Class hbNFSe_DSF
/*
   Lista de WebServices para DSF
   Mauricio Cruz - 06/09/2013
*/
LOCAL cWeb:=''

IF ::cab_CodCidade=6291 // CAMPINAS-SP
   cWeb:='http://issdigital.campinas.sp.gov.br/WsNFe2/LoteRps.jws'
ELSEIF ::cab_CodCidade=5403 // UBERLANDIA-MG
   cWeb:='http://udigital.uberlandia.mg.gov.br/WsNFe2/LoteRps.jws'
ELSEIF ::cab_CodCidade=427 // BELEM-PA
   cWeb:='http://www.issdigitalbel.com.br/WsNFe2/LoteRps.jws'
ELSEIF ::cab_CodCidade=9051 // CAMPO GRANDE-MS
   cWeb:='http://issdigital.pmcg.ms.gov.br/WsNFe2/LoteRps.jws'
ELSEIF ::cab_CodCidade=5869 // NOVA IGUAÇU
   cWeb:='http://www.issmaisfacil.com.br/WsNFe2/LoteRps.jws'
ELSEIF ::cab_CodCidade=1219 // TERESINA
   cWeb:='http://www.issdigitalthe.com.br/WsNFe2/LoteRps.jws'
ELSEIF ::cab_CodCidade=921 // SÃO LUÍS
   cWeb:='http://www.issdigitalslz.com.br/WsNFe2/LoteRps.jws'
ELSEIF ::cab_CodCidade=7145 // SOROCABA
   cWeb:='http://www.issdigitalsod.com.br/WsNFe2/LoteRps.jws'
ENDIF

RETURN(cWeb)

Method ctPegaCNCertificado() Class hbNFSe_DSF
/*
   Pega o CN do certificado - do projeto hbNFE
   Mauricio Cruz - 22/07/2013
*/
LOCAL oStore, oCertificados
LOCAL cSubjectName:='', cCN:=''
LOCAL mI

TRY

      oStore := win_OleCreateObject( "CAPICOM.Store" )

CATCH
END

IF oStore = Nil
   RETURN('')
ENDIF

oStore:open(_CAPICOM_CURRENT_USER_STORE,'My',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
oCertificados:=oStore:Certificates()
FOR mI=1 TO oCertificados:Count()
   IF oCertificados:Item(mI):SerialNumber = ::ohbNFe:cSerialCert
      cSubjectName := oCertificados:Item(mI):SubjectName
   ENDIF
NEXT
cCN:=''
FOR mI:=AT("CN=",cSubjectName)+3 TO LEN(cSubjectName)
   IF SUBS(cSubjectName,mI,1) == ","
      EXIT
   ENDIF
   cCN += SUBS(cSubjectName,mI,1)
NEXT
oCertificados := Nil
oStore := Nil
RETURN(cCN)

Method ComunicaWebService(cMethod) Class hbNFSe_DSF
/*
   Faz a comunicação com o webservice
   Mauricio Cruz - 23/05/2013
*/
LOCAL oServerWS
LOCAL aRETORNO:=HASH()
LOCAL cCERT:='', cUrlWS, cXML, oDomDoc, e

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::Xml=NIL .OR. EMPTY(::Xml)
   aRETORNO['MSG']:='Arquivo XML assinado de RPS não informado.'
ENDIF

cXML:=MEMOREAD(::Xml)
FERASE(::Xml)

IF EMPTY(cXML)
   aRETORNO['MSG']:='Favor informar o arquivo de XML.'
   RETURN(aRETORNO)
ENDIF

// SOUP ACTION
cXML:='<soapenv:Envelope xmlns:dsf="http://dsfnet.com.br"'+;
                           ' xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'+;
                           ' xmlns:xsd="http://www.w3.org/2001/XMLSchema"'+;
                           ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+;
             '<soapenv:Body>'+;
               '<dsf:'+cMethod+' soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'+;
                 '<mensagemXml xsi:type="xsd:string">'+;
                 '<![CDATA['+;
                   cXML+;
                  ']]>'+;
                 '</mensagemXml>'+;
               '</dsf:'+cMethod+'>'+;
             '</soapenv:Body>'+;
           '</soapenv:Envelope>'

TRY
   cCERT := ::ctPegaCNCertificado()
CATCH
END
IF EMPTY(cCERT)
   aRETORNO['MSG']:='Não foi possível carregar as informações do certificado.'
   RETURN(aRETORNO)
ENDIF

cUrlWS:=::LinkWebService()

IF EMPTY(cUrlWS)
   aRETORNO['MSG']:='Webservice não localizado'
   RETURN(aRETORNO)
ENDIF

TRY

   oServerWS := win_OleCreateObject( _MSXML2_ServerXMLHTTP )

   oServerWS:setOption( 3, 'CURRENT_USER\MY\'+cCERT )
   oServerWS:open('POST', cUrlWS, .F.)
   oServerWS:setRequestHeader('SOAPAction', '""' )
   oServerWS:setRequestHeader('Content-Type','application/soap+xml; charset=utf-8')
CATCH
   aRETORNO['MSG']:='Não foi possível inicializar a conexão do webservice'
   RETURN(aRETORNO)
END

IF oServerWS=NIL
   aRETORNO['MSG']:='Não foi possível inicializar o objeto de conexão do webservice'
   RETURN(aRETORNO)
ENDIF

TRY

   oDOMDoc := win_OleCreateObject( _MSXML2_DOMDocument )

   oDOMDoc:async = .F.
   oDOMDoc:validateOnParse  = .T.
   oDOMDoc:resolveExternals := .F.
   oDOMDoc:preserveWhiteSpace = .T.
   oDOMDoc:LoadXML(cXML)
CATCH
   aRETORNO['MSG']:='Não foi possível carregar o documento XML'
   RETURN(aRETORNO)
END
IF oDOMDoc:parseError:errorCode <> 0
   aRETORNO['MSG']:='Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_EOL()+;
                    ' Linha: '+STR(oDOMDoc:parseError:line)                                       +HB_EOL()+;
                    ' Caractere na linha: '+STR(oDOMDoc:parseError:linepos)                       +HB_EOL()+;
                    ' Causa do erro: '+oDOMDoc:parseError:reason                                  +HB_EOL()+;
                    ' Code: '+STR(oDOMDoc:parseError:errorCode)
  RETURN(aRETORNO)
ENDIF

TRY
  oServerWS:send(oDOMDoc:xml)
CATCH e
   aRETORNO['MSG']:='Falha: Não foi possível conectar-se ao servidor do SEFAZ, Servidor inativou ou inoperante.'+HB_EOL()+;
                    'Error: '+Transform(e:GenCode,nil)                                                      +';'+HB_EOL()+;
                    'SubC: '+Transform(e:SubCode,nil)                                                       +';'+HB_EOL()+;
                    'OSCode: '+Transform(e:OsCode,nil)                                                      +';'+HB_EOL()+;
                    'SubSystem: '+Transform(e:SubSystem,nil)                                                +';'+HB_EOL()+;
                    'Mensangem: '+e:Description
  RETURN(aRETORNO)
END
DO WHILE oServerWS:readyState <> 4
  millisec(500)
ENDDO

aRETORNO['MSG']:='Comunicação com o webservice finalizada com sucesso.'
aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=oServerWS:responseText

RETURN(aRETORNO)



Method CancelaNFSe() Class hbNFSe_DSF
/*
   Cancelamento de NFSe DSF
   Mauricio Cruz - 31/10/2013

   chamar  ::Registro_Cabecalho() antes de chamar esse no xml
*/
LOCAL cXML:=''
LOCAL aRETORNO:=HASH()
aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::cab_CodCidade=NIL .OR. ::cab_CodCidade<=0
   aRETORNO['MSG']:='Favor informar o código do município'
ENDIF
IF ::cab_CPFCNPJRemetente=NIL .OR. EMPTY(::cab_CPFCNPJRemetente)
   aRETORNO['MSG']:='Favor informar o CPF / CNPJ do Remetente'
ENDIF
IF ::rps_InscricaoMunicipalPrestador=NIL .OR. EMPTY(::rps_InscricaoMunicipalPrestador)
   aRETORNO['MSG']:='Favor Informar a Inscrição Municipal do Prestador. Verificar regra de preenchimento do campo no Anexo 03.'
ENDIF
IF ::numero_nota=NIL .OR. ::numero_nota<=0
   aRETORNO['MSG']:='Favor Informar o número da nota a ser cancelada.'
ENDIF
IF ::codigo_verificacao=NIL .OR. EMPTY(::codigo_verificacao)
   aRETORNO['MSG']:='Favor Informar o código verificador.'
ENDIF
IF ::motivo=NIL .OR. EMPTY(::motivo)
   aRETORNO['MSG']:='Favor Informar o motivo do cancelamento.'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML+='<ns1:ReqCancelamentoNFSe xmlns:ns1="http://localhost:8080/WsNFe2/lote" xmlns:tipos="http://localhost:8080/WsNFe2/tp"'+;
      ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'+;
      ' xsi:schemaLocation="http://localhost:8080/WsNFe2/lote http://localhost:8080/WsNFe2/xsd/ReqCancelamentoNFSe.xsd"> '

cXML+=   '<Cabecalho>'
cXML+=      '<CodCidade>'+ALLTRIM(STR(::cab_CodCidade))+'</CodCidade>'
cXML+=      '<CPFCNPJRemetente>'+ALLTRIM(::cab_CPFCNPJRemetente)+'</CPFCNPJRemetente>'
cXML+=      '<transacao>true</transacao>'
cXML+=      '<Versao>'+ALLTRIM(STR(::cab_Versao))+'</Versao>'
cXML+=   '</Cabecalho>'
cXML+=   '<Lote Id="lote:1ABCDZ">'
cXML+=      '<Nota>'
cXML+=         '<InscricaoMunicipalPrestador>'+ALLTRIM(::rps_InscricaoMunicipalPrestador)+'</InscricaoMunicipalPrestador>'
cXML+=         '<NumeroNota>'+ALLTRIM(STR(::numero_nota))+'</NumeroNota>'
cXML+=         '<CodigoVerificacao>'+ALLTRIM(::codigo_verificacao)+'</CodigoVerificacao>'
cXML+=         '<MotivoCancelamento>'+ALLTRIM(::motivo)+'</MotivoCancelamento>'
cXML+=      '</Nota>'
cXML+=   '</Lote>'
cXML+=   '<Signature></Signature>'
cXML+='</ns1:ReqCancelamentoNFSe>'

::Xml:=::ohbNFe:pastaEnvRes+'\NFSe_canc'+ALLTRIM(::cab_CPFCNPJRemetente)+DTOS(DATE())+STRTRAN(LEFT(TIME(),8),':')+'.xml'
hb_MemoWrit( ::Xml, cXML )

aRETORNO:=::Assina_XML()
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

aRETORNO:=::ValidaXML()
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

aRETORNO:=::ComunicaWebService('cancelar')
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

aRETORNO:=::LeRetorno(aRETORNO['XML'])
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

RETURN(aRETORNO)


Method LeRetorno(cRET) Class hbNFSe_DSF
/*
   Le o retorno
   Mauricio Cruz - 31/10/2013
*/
LOCAL aRETORNO:=HASH()
aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

cRET:=STRTRAN(cRET,'&lt;','<')
cRET:=STRTRAN(cRET,'&gt;','>')
cRET:=STRTRAN(cRET,'&quot;','"')

IF '<Erros>' $ cRET
   cRET:=::oFuncoes:pegaTag(cRET,'Erro')
   aRETORNO['CODIGO']:=::oFuncoes:pegaTag(cRET,'Codigo')
   aRETORNO['DESCRICAO']:=::oFuncoes:pegaTag(cRET,'Descricao')
   aRETORNO['MSG']:=aRETORNO['CODIGO']+'-'+aRETORNO['DESCRICAO']
ELSEIF '<Alertas>' $ cRET
   cRET:=::oFuncoes:pegaTag(cRET,'Alerta')
   aRETORNO['CODIGO']:=::oFuncoes:pegaTag(cRET,'Codigo')
   aRETORNO['DESCRICAO']:=::oFuncoes:pegaTag(cRET,'Descricao')
   aRETORNO['MSG']:=aRETORNO['CODIGO']+'-'+aRETORNO['DESCRICAO']
ELSE
   aRETORNO['STATUS']:=.T.
ENDIF

RETURN(aRETORNO)


Method ValidaXML() Class hbNFSe_DSF
/*
   Valida o arquivo XML
   Mauricio Cruz - 27/05/2013
*/
LOCAL oDOMDoc, oSchema, ParseError
LOCAL aRETORNO:=HASH()
LOCAL cSchemaFilename:='', cXml, oError

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::Xml=NIL .OR. EMPTY(::Xml)
   aRETORNO['MSG']:='Arquivo XML assinado de RPS não informado.'
ENDIF

cXML:=MEMOREAD(::Xml)

IF 'ReqEnvioLoteRPS' $ cXML // Envio de lote
   cXML:=STRTRAN(cXML,' xmlns:tipos="http://localhost:8080/WsNFe2/tp" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://localhost:8080/WsNFe2/lote http://localhost:8080/WsNFe2/xsd/ReqEnvioLoteRPS.xsd"')
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\NFSe\ISSDSF\ReqEnvioLoteRPS.xsd'
ELSEIF 'ReqCancelamentoNFSe' $ cXML  // Cancelamento de NFSe
   cXML:=STRTRAN(cXML,' xmlns:tipos="http://localhost:8080/WsNFe2/tp" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://localhost:8080/WsNFe2/lote http://localhost:8080/WsNFe2/xsd/ReqCancelamentoNFSe.xsd"')
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\NFSe\ISSDSF\ReqCancelamentoNFSe.xsd'
ENDIF

TRY

   oDOMDoc := win_OleCreateObject( _MSXML2_DOMDocument )

CATCH
   aRETORNO['MSG']:='Não foi possível carregar o MSXML para validação do XML.'
   RETURN(aRETORNO)
END

TRY
   oDOMDoc:async = .F.
   oDOMDoc:resolveExternals := .F.
   oDOMDoc:validateOnParse  = .T.
   oDOMDoc:LoadXML(cXML)
CATCH
   aRETORNO['MSG']:='Não foi possível carregar o arquivo XML para a validação.'
   RETURN(aRETORNO)
END
IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
   aRETORNO['MSG']:='Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_EOL()+;
                    'Linha: '+STR(oDOMDoc:parseError:line)                                        +HB_EOL()+;
                    'Caractere na linha: '+STR(oDOMDoc:parseError:linepos)                        +HB_EOL()+;
                    'Causa do erro: '+oDOMDoc:parseError:reason                                   +HB_EOL()+;
                    'Code: '+STR(oDOMDoc:parseError:errorCode)
  RETURN(aRETORNO)
ENDIF

TRY

   oSchema := win_OleCreateObject( _MSXML2_XMLSchemaCache )

CATCH
   aRETORNO['MSG']:='Não foi possível carregar o MSXML para o schema do XML.'
   RETURN(aRETORNO)
END

IF !FILE(cSchemaFilename)
  aRETORNO['MSG']:='Arquivo do schema não encontrado '+cSchemaFilename
  RETURN(aRETORNO)
ENDIF

TRY
   oSchema:add( 'http://localhost:8080/WsNFe2/lote', cSchemaFilename )
CATCH oError
   aRETORNO['MSG']:='Falha '+HB_EOL()+ ;
                    'Error: '+Transform(oError:GenCode, nil)       + ';' +HB_EOL()+;
                    'SubC: '+Transform(oError:SubCode, nil)        + ';' +HB_EOL()+;
                    'OSCode: '+Transform(oError:OsCode,  nil)      + ';' +HB_EOL()+;
                    'SubSystem: '+Transform(oError:SubSystem, nil) + ';' +HB_EOL()+;
                    'Mensangem: '+oError:Description
  RETURN(aRETORNO)
END

oDOMDoc:Schemas := oSchema
ParseError := oDOMDoc:validate
IF ParseError:errorCode <> 0
   aRetorno['nResult']  := ParseError:errorCode
   aRETORNO['MSG']  := ParseError:reason
   RETURN(aRetorno)
ENDIF
oDOMDoc := nil
ParseError := nil
oSchema := nil
aRETORNO['XML']:=::Xml
aRETORNO['STATUS']:=.T.

RETURN(aRETORNO)















Method Gera_Chave_SHA1() Class hbNFSe_DSF
/*
   Gera a chave e Chama executavel auxiliar para retornar a chave SHA1
   Mauricio Cruz - 02/05/2013
*/
LOCAL cRET
LOCAL cCHA:=PADL(ALLTRIM(::rps_InscricaoMunicipalPrestador),11,'0')

cCHA+=PADR(ALLTRIM(::rps_SerieRPS),5,' ')
cCHA+=STRZERO(::rps_NumeroRPS,12)
cCHA+=::DataToYYYYMMDD(::rps_DataEmissaoRPS)
cCHA+=PADR(ALLTRIM(::rps_Tributacao),2,' ')
cCHA+=LEFT(ALLTRIM(::rps_SituacaoRPS),1)
cCHA+=IF(ALLTRIM(LEFT(::rps_TipoRecolhimento,1))='A','N','S')
cCHA+=STRZERO(VAL(STRTRAN(STR(::cab_ValorTotalServicos-::cab_ValorTotalDeducoes*100),'.')),15)  //STRZERO((::cab_ValorTotalServicos-::cab_ValorTotalDeducoes),15)
cCHA+=STRZERO(VAL(STRTRAN(STR(::cab_ValorTotalDeducoes*100,15),'.')),15)  //STRZERO(::cab_ValorTotalDeducoes/100,15)
cCHA+=PADL(ALLTRIM(::rps_CodigoAtividade),10,'0')
cCHA+=PADL(ALLTRIM(::rps_CPFCNPJTomador),14,'0')

SETENVIRONMENTVARIABLE('SYG_SHA1',cCHA)
MILLISEC(500)
MYRUN2(CAMINHO_EXE()+'\'+PEGA_ARQUIVO_SAGI(24))
MILLISEC(500)

cRET:=MemoRead(GETENV("temp")+"\sy_temp\sha1.sag")

Return(cRET)



Method DataToYYYY_MM_DD(dDAT,lTIME) Class hbNFSe_DSF
/*
   Converte uma data para ano-mes-dia (YYYY-MM-DD)
   Mauricio Cruz - 01/05/2013
*/
LOCAL cRET:=ALLTRIM(STR(YEAR(dDAT)))+'-'+STRZERO(MONTH(dDAT),2)+'-'+STRZERO(DAY(dDAT),2)
IF lTIME=NIL
  lTIME:=.F.
ENDIF
IF lTIME
   cRET+='T'+LEFT(TIME(),8)
ENDIF
RETURN(cRET)


Method DataToYYYYMMDD(dDAT) Class hbNFSe_DSF
/*
   Converte uma data para ano-mes-dia (YYYYMMDD)
   Mauricio Cruz - 02/05/2013
*/
LOCAL cRET:=ALLTRIM(STR(YEAR(dDAT)))+STRZERO(MONTH(dDAT),2)+STRZERO(DAY(dDAT),2)
RETURN(cRET)


