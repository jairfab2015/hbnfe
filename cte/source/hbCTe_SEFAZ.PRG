/*
   Classe de comunicação com o SEFAZ e impressão da DACTE da CT-e com xHarbour
   Mauricio Cruz - 15/07/2013
   - cruz@sygecom.com.br
   - www.sygecom.com.br
   
   Implementado versão 2.00
   Mauricio Cruz - 21/10/2013


NOTAS:   
   - Schemas XML estão feitos da versão 1.04
   - A v2.00 entra em vigor em Ambiente de Homologação: 01/09/2013 - Ambiente de Produção: 01/11/2013
     O bloco dos documentos muda de posição no XML para a versão 2.00, procurar por v2.00 para ver onde ele deve ficar e v1.04 de onde deve sair
     -- eventos a serem inseridos apartir de 01/09/2013
        passam para os eventos: cancelamento
                                Multimodal
                                Carta de Correção
   - Atualmente o projeto CTe está compatível apenas com xHarbour
   - Não é compatível para usar nativamente no Linux e Mac
   - Não é necessário nenhuma DLL de terceiro além das DLL mencionadas acima que são de dominio publico e disponibilizadas pela Microsoft
   
DEPENDENCIAS:
   - BAIXAR E INTEGRAR DO PROJETO hbNFE A CLASSE oFuncoes - https://code.google.com/p/hbnfe/
   - REGISTRAR AS DLL QUE ESTÁ NA PASTA DLL, PARA ISSO PODE USAR OS .BAT QUE SEGUEM EM ANEXO, PRESTE 
     ATENÇÃO NA HORA DE EXECUTAR OS .BAT POR QUE AS VEZ O USUÁRIO NÃO TEM PERMISSÃO NAS PASTAS DO WINDOWS PARA COPIAR AS DLL
     PARA SYSTEM32 OU SYSWOW64 AI ACABA POR NÃO REGISTRAR AS DLL, E AS VEZ TEM QUE DESATIVAR O CONTROLE DE USUARIO DO WINDOWS
     CONFORME MOSTRA A IMAGEM DENTRO DA PASTA DLL.
   - PRECISA REGISTRAR AS DLL(CAPICOM.DLL, MSXML6.DLL E MSXML6R.DLL) UMA VEZ NOS WINDOWS QUE FOR USAR O SISTEMA DE CTE.   
   - ATUALMENTE TEMOS IMPRESSÃO DO DACTE APENAS COM FASTREPORT:  SAGI_DACTE.FR3
*/

#include "common.ch"
#include "hbclass.ch"
#Include "hwgui.ch"
#include "HBXML.ch"
#include "hbCTe.ch"

Class oCTe_SEFAZ
   DATA oFuncoes INIT hbNFeFuncoes()   // DO PROJETO HBNFE
   DATA oCTe_GERAIS INIT oCTe_GERAIS() // CLASSE COM ROTINAS GERAIS

   DATA nCte_NUMERO
   DATA cCte_CNPJ
   DATA cCte_IE
   DATA cCte_RAZAO
   DATA cCte_FANTASIA
   DATA cCte_ENDERECO
   DATA cCte_NUMERO
   DATA cCte_BAIRRO
   DATA cCte_Cidade
   DATA cCte_Estado
   DATA cCte_CEP
   DATA cCte_FONE
   DATA cCte_Chave
   
   DATA cCte_DACTE     READONLY  INIT PEGA_ARQUIVO_SAGI(387) // CAMINHO DO ARQUIVO FR3 DO DACTE
   DATA cCte_FAST_LANG READONLY  INIT 'res\brazil.xml'            // CAMINHO DO ARQUIVO DE LINGUA PARA O FASTREPORT
   
   DATA tpEmis
   DATA tpAmb
   DATA cCte_DV     READONLY     // DIGITO DV DA CHAVE DA CTE
   DATA cVersao_DADOS
   DATA cVersao_CTe
   DATA cVersao_Modal_RODOVIARIO
   DATA versaoApp
   DATA cJustCont
   DATA cPastaSchemas
   DATA cSerialCert
   DATA nCte_Icon_resorce INIT 1001 // SUBSTITUIR POR RESORCE DO ICONE DO SISTEMA PARA A IMPRESSAO DA DACTE NO FASTREPORT
   DATA cCancelada   // Luca Monticelli - 08/08/2013           cte cancelada

   DATA xml_numerodacte
   DATA xml_cfop_id                         
   DATA xml_formapagamento              
   DATA xml_modelo                      
   DATA xml_serie                       
   DATA xml_dataemissao                 
   DATA xml_horaemissao                 
   DATA xml_ibgeorigemprestacao         
   DATA xml_ibgedestinoprestacao        
   DATA xml_tomadorservico              
   DATA xml_CNP_remetente               
   DATA xml_IERG_remetente              
   DATA xml_nome_remetente              
   DATA xml_fantasia_rementente         
   DATA xml_fone_rementente             
   DATA xml_endereco_rementente         
   DATA xml_numero_rementente           
   DATA xml_bairro_rementente           
   DATA xml_cidade_rementente           
   DATA xml_cep_rementente              
   DATA xml_uf_rementente               
   DATA xml_pais_rementente             
   DATA xml_email_rementente            
   DATA xml_outrascaracter              
   DATA xml_observacao                  
   DATA xml_obs_fisco                   
   DATA xml_CNP_destinatario            
   DATA xml_IERG_destinatario           
   DATA xml_nome_destinatario           
   DATA xml_fone_destinatario           
   DATA xml_endereco_destinatario       
   DATA xml_numero_destinatario         
   DATA xml_bairro_destinatario         
   DATA xml_cidade_destinatario         
   DATA xml_cep_destinatario            
   DATA xml_uf_destinatario             
   DATA xml_pais_destinatario           
   DATA xml_email_destinatario          
   DATA xml_CNP_expedidor
   DATA xml_IERG_expedidor
   DATA xml_nome_expedidor
   DATA xml_fone_expedidor
   DATA xml_endereco_expedidor
   DATA xml_numero_expedidor
   DATA xml_bairro_expedidor
   DATA xml_cidade_expedidor
   DATA xml_cep_expedidor
   DATA xml_uf_expedidor
   DATA xml_pais_expedidor
   DATA xml_email_expedidor
   DATA xml_CNP_recebedor
   DATA xml_IERG_recebedor
   DATA xml_nome_recebedor
   DATA xml_fone_recebedor
   DATA xml_endereco_recebedor
   DATA xml_numero_recebedor
   DATA xml_bairro_recebedor
   DATA xml_cidade_recebedor
   DATA xml_cep_recebedor
   DATA xml_uf_recebedor
   DATA xml_pais_recebedor
   DATA xml_email_recebedor
   DATA xml_valorservico                
   DATA xml_valorreceber                
   DATA xml_imposto                     
   DATA xml_icmsbasecalc                
   DATA xml_icmsaliq                    
   DATA xml_icmsvalor                   
   DATA xml_icmsreducaobc               
   DATA xml_vbcstret                    
   DATA xml_vicmsstret                  
   DATA xml_picmsstret                  
   DATA xml_vcred                       
   DATA xml_vbc                         
   DATA xml_predbcoutrauf               
   DATA xml_vbcoutrauf                  
   DATA xml_picmsoutrauf                
   DATA xml_vicmsoutrauf                
   DATA xml_valortotalmercad            
   DATA xml_descricaopredominante       
   //DATA xml_volumes                     
   DATA xml_responsavel_seguro          
   DATA xml_seguradora                      
   DATA xml_apolice_seguro              
   DATA xml_averbacao_seguro            
   DATA xml_valorcarga_averbacao        
   DATA xml_peso_bruto
   DATA xml_Tipo_Servico
   DATA xml_unidade
   DATA xml_tipo_medida

   DATA xml_modal_rntrc
   DATA xml_modal_dataprevistaentrega
   DATA xml_modal_lotacao
   
   DATA xml_DOCUMENTOS
   DATA xml_SERVICOS
   
   DATA aCte_INUTILIZAR  //{NUMERO,SERIE,MODELO}
   DATA cCte_MOTIVO
   DATA cCte_PROTOCOLO
   
   DATA lCte_Emulador
   
   DATA tpEvento
   DATA nSeqEvento
   
   DATA cUTC
   
   DATA aCartaCorrecao
   
   
   Method ctXMLGeral()
   Method ctXMLRodoviario()
   Method ctValidaXML(cXML)
   Method ctAssinaXML(cXML,cID,cURI)
   Method ctPegaObjetoCertificado()
   Method ctComunicaWebService(cXML,cSoap,cService)
   Method ctPegaCNCertificado()
   Method ctLinkWebService(cServ)
   Method ctSoapAction(cXML,cServ)
   Method ctPegaRetornoSEFAZ(cXML)
   Method ctRetornoRecepcao(cREC)
   Method ctConsultaProtocolo()
   Method ctStatusServico()
   Method ctImprimeFastReport(cArqXml,lDESIGN,cARQpdf,lCANC)
   Method ctInutilizaCTe()
   Method ctCancelaCTe()
   Method ctEventos(cXMLevento)
   Method ctEventoCancelamento()
   Method ctEventoCartaCorrecao()

   // substitur por rotina de tratamento e consulta do status do sefaz
   Method ctConsultaStatusSEFAZ() INLINE CONSULTA_STATUS_CTE()
EndClass



Method ctXMLGeral() Class oCTe_SEFAZ
/*
   Gera o arquivo XML da CT-e
   Mauricio Cruz - 18/07/2013
*/
LOCAL mI:=0
LOCAL cXML:='', cXMLexp:=''
LOCAL aRET:=HASH()

aRET['XML']:=cXML
aRET['STATUS']:=.F.


::cCte_CNPJ:=STRTRAN(STRTRAN(STRTRAN(::cCte_CNPJ,'/'),'-'),'.')
::cCte_Chave:=ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2)))+;                          // CODIGO DA UF DE EMISSAO
              RIGHT(ALLTRIM(STR(YEAR(::xml_dataemissao))),2)+STRZERO(MONTH(::xml_dataemissao),2)+; // AAMM ANO E MES DA EMISSAO
              ::cCte_CNPJ+;                                                                        // CNPJ DO EMISSOR 
              STRZERO(::xml_modelo,2)+;                                                            // MODELO DA CTE
              STRZERO(::xml_serie,3)+;                                                             // SERIE DA CTE
              STRZERO(::nCte_NUMERO,9)+;                                                           // NUMERO DA CTE     
              ::tpEmis+;                                                                           // FORMA DE EMISSAO
              STRZERO(::nCte_NUMERO,8)                                                             // CODIGO SEQUENCIAL (USADO O MESMO NUMERO DA CTE)

::cCte_DV:= ::oFuncoes:modulo11(::cCte_Chave,2,9)
::cCte_Chave+=::cCte_DV
// 42 1307 10694772000124 57 001 000000015 1 00000015 5
// UF AAMM CNPJ           MD SER NUM CT-e  | SERIAL   |--> DIGITO
//                                         |-> ::tpEmis
::cVersao_CTe:=ALLTRIM(::cVersao_CTe)

cXML+='<CTe xmlns="http://www.portalfiscal.inf.br/cte">'
cXML+='<infCte Id="CTe'+::cCte_Chave+'" versao="'+::cVersao_CTe+'">'

// IDE
cXML+='<ide>'
cXML+=   '<cUF>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2)))+'</cUF>'
cXML+=   '<cCT>'+STRZERO(::nCte_NUMERO,8)+'</cCT>'
cXML+=   '<CFOP>'+ALLTRIM(STR(::xml_cfop_id))+'</CFOP>'
cXML+=   '<natOp>'+ALLTRIM(::oCTe_GERAIS:rgLimpaString(::oCTe_GERAIS:rgDesccfop(::xml_cfop_id)))+'</natOp>'
cXML+=   '<forPag>'+ALLTRIM(STR(::xml_formapagamento))+'</forPag>'
cXML+=   '<mod>'+ALLTRIM(STR(::xml_modelo))+'</mod>'
cXML+=   '<serie>'+ALLTRIM(STR(::xml_serie))+'</serie>'
cXML+=   '<nCT>'+ALLTRIM(STR(::nCte_NUMERO))+'</nCT>'
cXML+=   '<dhEmi>'+::oFuncoes:FormatDate(::xml_dataemissao,'YYYY-MM-DD','-')+'T'+::xml_horaemissao+'</dhEmi>'   //YYYY-MM-DDTHH:MM:SS
cXML+=   '<tpImp>1</tpImp>'   // ESTA FIXO RETRATO - DEVE SER IMPLEMENTADO NO ARQUIVO DO FASTREPORT PARA IMPRESSAO DE PAISAGEM.
cXML+=   '<tpEmis>'+::tpEmis+'</tpEmis>'
cXML+=   '<cDV>'+::cCte_DV+'</cDV>'
cXML+=   '<tpAmb>'+::tpAmb+'</tpAmb>'
cXML+=   '<tpCTe>0</tpCTe>'   // FIXO 0-NOMAL, PRECISA SER IMPLEMENTADO OUTRAS OPCOES
cXML+=   '<procEmi>0</procEmi>'   // FIXO 0-EMISSO DO CONTRIBUINTE
cXML+=   '<verProc>'+::versaoApp+'</verProc>'
cXML+=   '<cMunEnv>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_municipio(::cCte_Cidade,2,::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2))))+'</cMunEnv>'
cXML+=   '<xMunEnv>'+::cCte_Cidade+'</xMunEnv>'
cXML+=   '<UFEnv>'+::cCte_Estado+'</UFEnv>'
cXML+=   '<modal>01</modal>'   // FIXO 01-RODOVIARIO, PRESISA SER IMPLEMETADO OS DEMAIS MODAIS
cXML+=   '<tpServ>'+ALLTRIM(STR(::xml_Tipo_Servico))+'</tpServ>'
cXML+=   '<cMunIni>'+ALLTRIM(STR(::xml_ibgeorigemprestacao))+'</cMunIni>'
cXML+=   '<xMunIni>'+ALLTRIM(::oCTe_GERAIS:rgRetorna_municipio(::xml_ibgeorigemprestacao,1))+'</xMunIni>'
cXML+=   '<UFIni>'+::oCTe_GERAIS:rgRetorna_uf(VAL(LEFT(ALLTRIM(STR(::xml_ibgeorigemprestacao)),2)),1)+'</UFIni>'   
cXML+=   '<cMunFim>'+ALLTRIM(STR(::xml_ibgedestinoprestacao))+'</cMunFim>'
cXML+=   '<xMunFim>'+ALLTRIM(::oCTe_GERAIS:rgRetorna_municipio(::xml_ibgedestinoprestacao,1))+'</xMunFim>'
cXML+=   '<UFFim>'+::oCTe_GERAIS:rgRetorna_uf(VAL(LEFT(ALLTRIM(STR(::xml_ibgedestinoprestacao)),2)),1)+'</UFFim>'
cXML+=   '<retira>1</retira>'   // FIXO 1-NAO RETIRA NO LOCAL
cXML+=   '<toma03>'
cXML+=      '<toma>'+ALLTRIM(STR(::xml_tomadorservico))+'</toma>'
cXML+=   '</toma03>'

/*
cXML+=   '<toma04>'
cXML+=      '<toma>4</toma>'  //4-OUTROS
IF !LEN(ALLTRIM(::xml_CNP_remetente))>11
   cXML+=   '<CNPJ>'+ALLTRIM(::xml_CNP_remetente)+'</CNPJ>'
ELSE
   cXML+=   '<CPF>'+ALLTRIM(::xml_CNP_remetente)+'</CPF>'
ENDIF
IF !EMPTY(ALLTRIM(::xml_IERG_remetente))
   cXML+=   '<IE>'+ALLTRIM(::xml_IERG_remetente)+'</IE>'
ENDIF
cXML+=      '<xNome>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_nome_remetente))+'</xNome>'
IF !EMPTY(ALLTRIM(::xml_fantasia_rementente))
    cXML+=   '<xFant>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_fantasia_rementente))+'</xFant>'
ENDIF
IF !EMPTY(ALLTRIM(::xml_fone_rementente))
   cXML+=   '<fone>'+STRTRAN(STRTRAN(STRTRAN(ALLTRIM(::xml_fone_rementente),'-'),'('),')')+'</fone>'
ENDIF
cXML+=      '<enderToma>'
cXML+=         '<xLgr>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_endereco_rementente))+'</xLgr>'
cXML+=         '<nro>'+ALLTRIM(::xml_numero_rementente)+'</nro>'
cXML+=         '<xBairro>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_bairro_rementente))+'</xBairro>'
cXML+=         '<cMun>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_municipio(ALLTRIM(::xml_cidade_rementente),2, ::oCTe_GERAIS:rgRetorna_uf(::xml_uf_rementente,2))))+'</cMun>'
cXML+=         '<xMun>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_cidade_rementente))+'</xMun>'
cXML+=         '<CEP>'+ALLTRIM(::xml_cep_rementente)+'</CEP>'
cXML+=         '<UF>'+ALLTRIM(::xml_uf_rementente)+'</UF>'
cXML+=         '<cPais>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_paises(ALLTRIM(::xml_pais_rementente),2)))+'</cPais>'
cXML+=         '<xPais>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_pais_rementente))+'</xPais>'
cXML+=      '</enderToma>'
IF !EMPTY(ALLTRIM(::xml_email_rementente))
   cXML+=   '<email>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_email_rementente))+'</email>'
ENDIF
cXML+=   '</toma04>'
*/
IF !EMPTY(::cJustCont)
   cXML+='<xJust>'+::oCTe_GERAIS:rgLimpaString(::cJustCont)+'</xJust>'
ENDIF
cXML+='</ide>'

// COMPLEMENTO
cXML+='<compl>'
IF !EMPTY(::xml_outrascaracter)
   cXML+='<xCaracSer>'+LEFT(::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_outrascaracter)),30)+'</xCaracSer>'
ENDIF
IF !EMPTY(::xml_observacao)
   cXML+='<xObs>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_observacao),160))+'</xObs>'
ENDIF
/*
IF !EMPTY(::xml_observacao)
   cXML+='<ObsCont>'
   cXML+=   '<xCampo>COMPLEMENTAR</xCampo>'
   cXML+=   '<xTexto>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_observacao),160))+'</xTexto>'
   cXML+='</ObsCont>'
ENDIF
IF !EMPTY(::xml_obs_fisco)
   cXML+='<ObsFisco>'
   cXML+=   '<xCampo>FISCO</xCampo>'
   cXML+=   '<xTexto>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_obs_fisco),160))+'</xTexto>'
   cXML+='</ObsFisco>'
ENDIF
*/
cXML+='</compl>'


// EMITENTE
cXML+='<emit>'
cXML+=   '<CNPJ>'+::cCte_CNPJ+'</CNPJ>'
cXML+=   '<IE>'+::cCte_IE+'</IE>'
cXML+=   '<xNome>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::cCte_RAZAO),60))+'</xNome>'
cXML+=   '<xFant>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::cCte_FANTASIA),60))+'</xFant>'
cXML+=   '<enderEmit>'
cXML+=      '<xLgr>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::cCte_ENDERECO),60))+'</xLgr>'
cXML+=      '<nro>'+STRZERO(VAL(::cCte_NUMERO),5)+'</nro>'
cXML+=      '<xBairro>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::cCte_BAIRRO),60))+'</xBairro>'
cXML+=      '<cMun>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_municipio(::cCte_CIDADE,2, ::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2))))+'</cMun>'
cXML+=      '<xMun>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::cCte_CIDADE),60))+'</xMun>'
cXML+=      '<CEP>'+STRTRAN(STRTRAN(::cCte_CEP,'-'),'.')+'</CEP>'
cXML+=      '<UF>'+::cCte_Estado+'</UF>'
cXML+=      '<fone>'+STRTRAN(STRTRAN(STRTRAN(ALLTRIM(::cCte_FONE),'-'),'('),')')+'</fone>'
cXML+=   '</enderEmit>'
cXML+='</emit>'

// REMETENTE
cXML+='<rem>'
IF LEN(ALLTRIM(::xml_CNP_remetente))>11
   cXML+='<CNPJ>'+ALLTRIM(::xml_CNP_remetente)+'</CNPJ>'
ELSE
   cXML+='<CPF>'+ALLTRIM(::xml_CNP_remetente)+'</CPF>'
ENDIF
IF !EMPTY(ALLTRIM(::xml_IERG_remetente))
   cXML+='<IE>'+ALLTRIM(::xml_IERG_remetente)+'</IE>'
ENDIF
cXML+=   '<xNome>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_nome_remetente))+'</xNome>'
IF !EMPTY(ALLTRIM(::xml_fantasia_rementente))
   cXML+='<xFant>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_fantasia_rementente))+'</xFant>'
ENDIF
IF !EMPTY(ALLTRIM(::xml_fone_rementente))
   cXML+='<fone>'+STRTRAN(STRTRAN(STRTRAN(ALLTRIM(::xml_fone_rementente),'-'),'('),')')+'</fone>'
ENDIF
cXML+=   '<enderReme>'
cXML+=      '<xLgr>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_endereco_rementente))+'</xLgr>'
cXML+=      '<nro>'+ALLTRIM(::xml_numero_rementente)+'</nro>'
cXML+=      '<xBairro>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_bairro_rementente))+'</xBairro>'
cXML+=      '<cMun>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_municipio(ALLTRIM(::xml_cidade_rementente),2,::oCTe_GERAIS:rgRetorna_uf(::xml_uf_rementente,2))))+'</cMun>'
cXML+=      '<xMun>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_cidade_rementente))+'</xMun>'
cXML+=      '<CEP>'+ALLTRIM(::xml_cep_rementente)+'</CEP>'
cXML+=      '<UF>'+ALLTRIM(::xml_uf_rementente)+'</UF>'
cXML+=      '<cPais>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_paises(ALLTRIM(::xml_pais_rementente),2)))+'</cPais>'
cXML+=      '<xPais>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_pais_rementente))+'</xPais>'
cXML+=   '</enderReme>'
IF !EMPTY(::xml_email_rementente)
   cXML+='<email>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_email_rementente))+'</email>'
ENDIF

IF ::cVersao_CTe='1.04'
   FOR mI:=1 TO LEN(::xml_DOCUMENTOS)
      IF ::xml_DOCUMENTOS[mI,1]='NF'
         cXML+='<infNF>'
         cXML+=   '<mod>'+STRZERO(::xml_DOCUMENTOS[mI,2],2)+'</mod>'
         cXML+=   '<serie>'+ALLTRIM(::xml_DOCUMENTOS[mI,3])+'</serie>'
         cXML+=   '<nDoc>'+ALLTRIM(::xml_DOCUMENTOS[mI,4])+'</nDoc>'
         cXML+=   '<dEmi>'+::oFuncoes:FormatDate(::xml_DOCUMENTOS[mI,5],'YYYY-MM-DD','-')+'</dEmi>'
         cXML+=   '<vBC>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,6]))+'</vBC>'
         cXML+=   '<vICMS>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,7]))+'</vICMS>'
         cXML+=   '<vBCST>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,8]))+'</vBCST>'
         cXML+=   '<vST>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,9]))+'</vST>'
         cXML+=   '<vProd>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,10]))+'</vProd>'
         cXML+=   '<vNF>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,11]))+'</vNF>'
         cXML+=   '<nCFOP>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,12]))+'</nCFOP>'
         cXML+=   '<nPeso>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,13]))+'</nPeso>'
         cXML+='</infNF>'
      ELSEIF ::xml_DOCUMENTOS[mI,1]='NF-e'
         cXML+='<infNFe>'
         cXML+=   '<chave>'+ALLTRIM(::xml_DOCUMENTOS[mI,14])+'</chave>'
         cXML+='</infNFe>'
      ELSEIF ::xml_DOCUMENTOS[mI,1]='OUTROS'
         cXML+='<infOutros>'
         cXML+=   '<tpDoc>99</tpDoc>'  // FIXO OUTROS
         cXML+=   '<descOutros>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_DOCUMENTOS[mI,15])),100))+'</descOutros>'
         cXML+=   '<nDoc>'+ALLTRIM(::xml_DOCUMENTOS[mI,4])+'</nDoc>'
         cXML+=   '<dEmi>'+::oFuncoes:FormatDate(::xml_DOCUMENTOS[mI,5],'YYYY-MM-DD','-')+'</dEmi>'
         cXML+=   '<vDocFisc>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,11]))+'</vDocFisc>'
         cXML+='</infOutros>'
      ENDIF
   NEXT
ENDIF   
cXML+='</rem>'


// EXPEDIDOR
TRY
   cXMLexp:='<exped>'
   IF LEN(ALLTRIM(::xml_CNP_expedidor))>11
      cXMLexp+='<CNPJ>'+ALLTRIM(::xml_CNP_expedidor)+'</CNPJ>'
   ELSE   
      cXMLexp+='<CPF>'+ALLTRIM(::xml_CNP_expedidor)+'</CPF>'
   ENDIF
   cXMLexp+=   '<IE>'+ALLTRIM(::xml_IERG_expedidor)+'</IE>'
   cXMLexp+=   '<xNome>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_nome_expedidor),60))+'</xNome>'
   cXMLexp+=   '<fone>'+STRTRAN(STRTRAN(STRTRAN(ALLTRIM(::xml_fone_expedidor),'-'),'('),')')+'</fone>'
   cXMLexp+=   '<enderExped>'
   cXMLexp+=         '<xLgr>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_endereco_expedidor))+'</xLgr>'
   cXMLexp+=         '<nro>'+ALLTRIM(::xml_numero_expedidor)+'</nro>'
   cXMLexp+=         '<xBairro>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_bairro_expedidor))+'</xBairro>'
   cXMLexp+=         '<cMun>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_municipio(ALLTRIM(::xml_cidade_expedidor),2,::oCTe_GERAIS:rgRetorna_uf(::xml_uf_expedidor,2))))+'</cMun>'
   cXMLexp+=         '<xMun>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_cidade_expedidor))+'</xMun>'
   cXMLexp+=         '<CEP>'+ALLTRIM(::xml_cep_expedidor)+'</CEP>'
   cXMLexp+=         '<UF>'+ALLTRIM(::xml_uf_expedidor)+'</UF>'
   cXMLexp+=         '<cPais>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_paises(ALLTRIM(::xml_pais_expedidor),2)))+'</cPais>'
   cXMLexp+=         '<xPais>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_pais_expedidor))+'</xPais>'
   cXMLexp+=   '</enderExped>'
   IF !EMPTY(::xml_email_expedidor)
      cXMLexp+='<email>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_email_expedidor))+'</email>'
   ENDIF
   cXMLexp+='</exped>'
CATCH
   cXMLexp:=''
END
cXML+=cXMLexp

// RECEBEDOR
TRY
   cXML+='<receb>'
   IF LEN(ALLTRIM(::xml_CNP_recebedor))>11
      cXML+='<CNPJ>'+ALLTRIM(::xml_CNP_recebedor)+'</CNPJ>'
   ELSE   
      cXML+='<CPF>'+ALLTRIM(::xml_CNP_recebedor)+'</CPF>'
   ENDIF
   IF !EMPTY(::xml_IERG_recebedor)
      cXML+='<IE>'+ALLTRIM(::xml_IERG_recebedor)+'</IE>'
   ENDIF
   cXML+=   '<xNome>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_nome_recebedor),60))+'</xNome>'
   cXML+=   '<fone>'+STRTRAN(STRTRAN(STRTRAN(ALLTRIM(::xml_fone_recebedor),'-'),'('),')')+'</fone>'
   cXML+=   '<enderReceb>'
   cXML+=         '<xLgr>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_endereco_recebedor))+'</xLgr>'
   cXML+=         '<nro>'+ALLTRIM(::xml_numero_recebedor)+'</nro>'
   cXML+=         '<xBairro>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_bairro_recebedor))+'</xBairro>'
   cXML+=         '<cMun>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_municipio(ALLTRIM(::xml_cidade_recebedor),2,::oCTe_GERAIS:rgRetorna_uf(::xml_uf_recebedor,2))))+'</cMun>'
   cXML+=         '<xMun>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_cidade_recebedor))+'</xMun>'
   cXML+=         '<CEP>'+ALLTRIM(::xml_cep_recebedor)+'</CEP>'
   cXML+=         '<UF>'+ALLTRIM(::xml_uf_recebedor)+'</UF>'
   cXML+=         '<cPais>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_paises(ALLTRIM(::xml_pais_recebedor),2)))+'</cPais>'
   cXML+=         '<xPais>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_pais_recebedor))+'</xPais>'
   cXML+=   '</enderReceb>'
   IF !EMPTY(::xml_email_recebedor)
      cXML+='<email>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_email_recebedor))+'</email>'
   ENDIF
   cXML+='</receb>'
CATCH
END   

// DESTINATARIO
cXML+='<dest>'
IF LEN(ALLTRIM(::xml_CNP_destinatario))>11
   cXML+='<CNPJ>'+ALLTRIM(::xml_CNP_destinatario)+'</CNPJ>'
ELSE   
   cXML+='<CPF>'+ALLTRIM(::xml_CNP_destinatario)+'</CPF>'
ENDIF
IF !EMPTY(::xml_IERG_destinatario)
   cXML+='<IE>'+ALLTRIM(::xml_IERG_destinatario)+'</IE>'
ENDIF
cXML+=   '<xNome>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_nome_destinatario),60))+'</xNome>'
cXML+=   '<fone>'+STRTRAN(STRTRAN(STRTRAN(ALLTRIM(::xml_fone_destinatario),'-'),'('),')')+'</fone>'
//cXML+=   '<ISUF>'++'<ISUF>'
cXML+=   '<enderDest>'
cXML+=         '<xLgr>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_endereco_destinatario))+'</xLgr>'
cXML+=         '<nro>'+ALLTRIM(::xml_numero_destinatario)+'</nro>'
cXML+=         '<xBairro>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_bairro_destinatario))+'</xBairro>'
cXML+=         '<cMun>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_municipio(ALLTRIM(::xml_cidade_destinatario),2,::oCTe_GERAIS:rgRetorna_uf(::xml_uf_destinatario,2))))+'</cMun>'
cXML+=         '<xMun>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_cidade_destinatario))+'</xMun>'
cXML+=         '<CEP>'+ALLTRIM(::xml_cep_destinatario)+'</CEP>'
cXML+=         '<UF>'+ALLTRIM(::xml_uf_destinatario)+'</UF>'
cXML+=         '<cPais>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_paises(ALLTRIM(::xml_pais_destinatario),2)))+'</cPais>'
cXML+=         '<xPais>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_pais_destinatario))+'</xPais>'
cXML+=   '</enderDest>'
IF !EMPTY(::xml_email_destinatario)
   cXML+='<email>'+::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_email_destinatario))+'</email>'
ENDIF
cXML+='</dest>'

// VALOR DA PRESTACAO DE SERVICO
cXML+='<vPrest>'
cXML+=   '<vTPrest>'+ALLTRIM(STR(::xml_valorservico))+'</vTPrest>'
cXML+=   '<vRec>'+ALLTRIM(STR(::xml_valorreceber))+'</vRec>'

FOR mI:=1 TO LEN(::xml_SERVICOS)
   cXML+='<Comp>'
   cXML+=   '<xNome>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_SERVICOS[mI,1]),15))+'</xNome>'
   cXML+=   '<vComp>'+ALLTRIM(STR(ROUND(::xml_SERVICOS[mI,2],2)))+'</vComp>'
   cXML+='</Comp>'
NEXT
                
cXML+='</vPrest>'

// INFO. RELATIVAS AO IMPOSTO
cXML+='<imp>'
cXML+=   '<ICMS>'
IF ::xml_imposto=99
cXML+=      '<ICMSSN>'
cXML+=         '<indSN>1</indSN>'
cXML+=      '</ICMSSN>'
ELSEIF ::xml_imposto=90 .AND. (::xml_predbcoutrauf>0 .OR. ::xml_vbcoutrauf>0 .OR. ::xml_picmsoutrauf>0 .OR. ::xml_vicmsoutrauf>0)
   cXML+=      '<ICMSOutraUF>'
   cXML+=         '<CST>90</CST>'   
   cXML+=         '<pRedBCOutraUF>'+ALLTRIM(STR(ROUND(::xml_predbcoutrauf,2)))+'</pRedBCOutraUF>'
   cXML+=         '<vBCOutraUF>'+ALLTRIM(STR(ROUND(::xml_vbcoutrauf,2)))+'</vBCOutraUF>'
   cXML+=         '<pICMSOutraUF>'+ALLTRIM(STR(ROUND(::xml_picmsoutrauf,2)))+'</pICMSOutraUF>'
   cXML+=         '<vICMSOutraUF>'+ALLTRIM(STR(ROUND(::xml_vicmsoutrauf,2)))+'</vICMSOutraUF>'
   cXML+=      '</ICMSOutraUF>'
ELSE
   cXML+=      '<ICMS'+STRZERO(IF(::xml_imposto=40 .OR. ::xml_imposto=41 .OR. ::xml_imposto=51,45,::xml_imposto),2)+'>'
   IF ::xml_imposto=0
      cXML+=      '<CST>00</CST>'
      cXML+=      '<vBC>'+ALLTRIM(STR(ROUND(::xml_icmsbasecalc,2)))+'</vBC>'
      cXML+=      '<pICMS>'+ALLTRIM(STR(ROUND(::xml_icmsaliq,2)))+'</pICMS>'
      cXML+=      '<vICMS>'+ALLTRIM(STR(ROUND(::xml_icmsvalor,2)))+'</vICMS>'
   ELSEIF ::xml_imposto=20
      cXML+=      '<CST>20</CST>'
      cXML+=      '<pRedBC>'+ALLTRIM(STR(ROUND(::xml_icmsreducaobc,2)))+'</pRedBC>'
      cXML+=      '<vBC>'+ALLTRIM(STR(ROUND(::xml_icmsbasecalc,2)))+'</vBC>'
      cXML+=      '<pICMS>'+ALLTRIM(STR(ROUND(::xml_icmsaliq,2)))+'</pICMS>'
      cXML+=      '<vICMS>'+ALLTRIM(STR(ROUND(::xml_icmsvalor,2)))+'</vICMS>'
   ELSEIF ::xml_imposto=40 .OR. ::xml_imposto=41 .OR. ::xml_imposto=51
      cXML+=      '<CST>'+STRZERO(::xml_imposto,2)+'</CST>'
   ELSEIF ::xml_imposto=60
      cXML+=      '<CST>60</CST>'
      cXML+=      '<vBCSTRet>'+ALLTRIM(STR(ROUND(::xml_vbcstret,2)))+'</vBCSTRet>'
      cXML+=      '<vICMSSTRet>'+ALLTRIM(STR(ROUND(::xml_vicmsstret,2)))+'</vICMSSTRet>'
      cXML+=      '<pICMSSTRet>'+ALLTRIM(STR(ROUND(::xml_picmsstret,2)))+'</pICMSSTRet>'
      cXML+=      '<vCred>'+ALLTRIM(STR(ROUND(::xml_vcred,2)))+'</vCred>'
   ELSEIF ::xml_imposto=90
      cXML+=      '<CST>90</CST>'
      IF ::xml_icmsreducaobc>0 
         cXML+=      '<pRedBC>'+ALLTRIM(STR(ROUND(::xml_icmsreducaobc,2)))+'</pRedBC>'
      ENDIF
      cXML+=      '<vBC>'+ALLTRIM(STR(ROUND(::xml_icmsbasecalc,2)))+'</vBC>'
      cXML+=      '<pICMS>'+ALLTRIM(STR(ROUND(::xml_icmsaliq,2)))+'</pICMS>'
      cXML+=      '<vICMS>'+ALLTRIM(STR(ROUND(::xml_icmsvalor,2)))+'</vICMS>'
      cXML+=      '<vCred>'+ALLTRIM(STR(ROUND(::xml_vcred,2)))+'</vCred>'
   ENDIF
   cXML+=      '</ICMS'+STRZERO(IF(::xml_imposto=40 .OR. ::xml_imposto=41 .OR. ::xml_imposto=51,45,::xml_imposto),2)+'>'
ENDIF
cXML+=   '</ICMS>'
//cXML+=  '<vTotTrib>'++'</vTotTrib>'
//cXML+=  '<infAdFisco>'++'</infAdFisco>'
cXML+='</imp>'

// INFO. DO CT NORMAL E SUBSTITUTO
cXML+='<infCTeNorm>'
cXML+=   '<infCarga>'
cXML+=      '<vCarga>'+ALLTRIM(STR(::xml_valortotalmercad))+'</vCarga>'
cXML+=      '<proPred>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_descricaopredominante),60))+'</proPred>'
cXML+=      '<xOutCat>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_outrascaracter)),30))+'</xOutCat>'
cXML+=      '<infQ>'
cXML+=         '<cUnid>'+LEFT(::xml_unidade,2)+'</cUnid>'
cXML+=         '<tpMed>'+ALLTRIM(LEFT(::xml_tipo_medida,20))+'</tpMed>'
cXML+=         '<qCarga>'+ALLTRIM(STR(ROUND(::xml_peso_bruto,4)))+'</qCarga>'
cXML+=      '</infQ>'
cXML+=   '</infCarga>'

// DOCUMENTOS
IF ::cVersao_CTe='2.00'
   cXML+=   '<infDoc>'
   FOR mI:=1 TO LEN(::xml_DOCUMENTOS)
      IF ::xml_DOCUMENTOS[mI,1]='NF'
         cXML+='<infNF>'
         cXML+=   '<mod>'+STRZERO(::xml_DOCUMENTOS[mI,2],2)+'</mod>'
         cXML+=   '<serie>'+ALLTRIM(::xml_DOCUMENTOS[mI,3])+'</serie>'
         cXML+=   '<nDoc>'+ALLTRIM(::xml_DOCUMENTOS[mI,4])+'</nDoc>'
         cXML+=   '<dEmi>'+::oFuncoes:FormatDate(::xml_DOCUMENTOS[mI,5],'YYYY-MM-DD','-')+'</dEmi>'
         cXML+=   '<vBC>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,6]))+'</vBC>'
         cXML+=   '<vICMS>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,7]))+'</vICMS>'
         cXML+=   '<vBCST>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,8]))+'</vBCST>'
         cXML+=   '<vST>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,9]))+'</vST>'
         cXML+=   '<vProd>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,10]))+'</vProd>'
         cXML+=   '<vNF>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,11]))+'</vNF>'
         cXML+=   '<nCFOP>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,12]))+'</nCFOP>'
         cXML+=   '<nPeso>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,13]))+'</nPeso>'
         cXML+='</infNF>'
      ELSEIF ::xml_DOCUMENTOS[mI,1]='NF-e'
         cXML+='<infNFe>'
         cXML+=   '<chave>'+ALLTRIM(::xml_DOCUMENTOS[mI,14])+'</chave>'
         cXML+='</infNFe>'
      ELSEIF ::xml_DOCUMENTOS[mI,1]='OUTROS'
         cXML+='<infOutros>'
         cXML+=   '<tpDoc>99</tpDoc>'  // FIXO OUTROS
         cXML+=   '<descOutros>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(ALLTRIM(::xml_DOCUMENTOS[mI,15])),100))+'</descOutros>'
         cXML+=   '<nDoc>'+ALLTRIM(::xml_DOCUMENTOS[mI,4])+'</nDoc>'
         cXML+=   '<dEmi>'+::oFuncoes:FormatDate(::xml_DOCUMENTOS[mI,5],'YYYY-MM-DD','-')+'</dEmi>'
         cXML+=   '<vDocFisc>'+ALLTRIM(STR(::xml_DOCUMENTOS[mI,11]))+'</vDocFisc>'
         cXML+='</infOutros>'
      ENDIF
   NEXT
   cXML+=   '</infDoc>'
ENDIF


// SEGURO
cXML+=   '<seg>'
cXML+=      '<respSeg>'+ALLTRIM(STR(::xml_responsavel_seguro))+'</respSeg>'
cXML+=      '<xSeg>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_seguradora),30))+'</xSeg>'
cXML+=      '<nApol>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_apolice_seguro),20))+'</nApol>'
IF !EMPTY(::xml_averbacao_seguro)
   cXML+=   '<nAver>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_averbacao_seguro),20))+'</nAver>'
ENDIF
IF ::xml_valorcarga_averbacao>0
   cXML+=      '<vCarga>'+ALLTRIM(STR(::xml_valorcarga_averbacao))+'</vCarga>'
ENDIF
cXML+=   '</seg>'

// modal
cXML+=   '<infModal versaoModal="'+::cVersao_Modal_RODOVIARIO+'">'
aRET:=::ctXMLRodoviario()
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF
cXML+=      aRET['XML']
cXML+=   '</infModal>'

cXML+='</infCTeNorm>'
cXML+='</infCte>'
cXML+='<Signature></Signature>'
cXML+='</CTe>'

aRET['XML']:=cXML
aRET['STATUS']:=.T.

RETURN(aRET)



Method ctXMLRodoviario() Class oCTe_SEFAZ
/*
   Gera o XML do modal rodoviario
   Mauricio Cruz - 19/07/2013
*/
LOCAL cXML:=''
LOCAL aRET:=HASH()

cXML+='<rodo>'
cXML+=   '<RNTRC>'+ALLTRIM(LEFT(::oCTe_GERAIS:rgLimpaString(::xml_modal_rntrc),8))+'</RNTRC>'
cXML+=   '<dPrev>'+::oFuncoes:FormatDate(::xml_modal_dataprevistaentrega,'YYYY-MM-DD','-')+'</dPrev>'
cXML+=   '<lota>'+ALLTRIM(STR(::xml_modal_lotacao))+'</lota>'
cXML+='</rodo>'

aRET:=::ctValidaXML(strtran(cXML,'<rodo>','<rodo xmlns="http://www.portalfiscal.inf.br/cte">'))

aRET['XML']:=cXML

RETURN(aRET)




Method ctValidaXML(cXML) Class oCTe_SEFAZ
/*
   Valida o XML da Ct-e
   Mauricio Cruz - 19/07/2013
*/
LOCAL oDOMDoc, oSchema, ParseError
LOCAL aRETORNO:=HASH()
LOCAL cSchemaFilename:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

TRY
   oDOMDoc := xhb_CreateObject( _MSXML2_DOMDocument ) 
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
   aRETORNO['MSG']:='Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_OsNewLine()+;
                    'Linha: '+STR(oDOMDoc:parseError:line)                                        +HB_OsNewLine()+;
                    'Caractere na linha: '+STR(oDOMDoc:parseError:linepos)                        +HB_OsNewLine()+;
                    'Causa do erro: '+oDOMDoc:parseError:reason                                   +HB_OsNewLine()+;
                    'Code: '+STR(oDOMDoc:parseError:errorCode)
  RETURN(aRETORNO)
ENDIF

TRY
   oSchema := xhb_CreateObject( _MSXML2_XMLSchemaCache )
CATCH
   aRETORNO['MSG']:='Não foi possível carregar o MSXML para o schema do XML.'
   RETURN(aRETORNO)
END

IF '</enviCTe>'$cXML  // Envio de lote da CT-e
   cSchemaFilename := ::cPastaSchemas+'\CTe\enviCte_v'+::cVersao_CTe+'.xsd'
ELSEIF '</CTe>'$cXML  // CT-e
   cSchemaFilename := ::cPastaSchemas+'\CTe\cte_v'+::cVersao_CTe+'.xsd'
ELSEIF '</rodo>'$cXML  // Modal Rodoviario
   cSchemaFilename := ::cPastaSchemas+'\CTe\cteModalRodoviario_v'+::cVersao_CTe+'.xsd'
ELSEIF '</consReciCTe>'$cXML  // retorno da recepcao
   cSchemaFilename := ::cPastaSchemas+'\CTe\consReciCTe_v'+::cVersao_CTe+'.xsd'
ELSEIF '</consSitCTe>'$cXML  // consulta de protocolo
   cSchemaFilename := ::cPastaSchemas+'\CTe\consSitCte_v'+::cVersao_CTe+'.xsd'
ELSEIF '</inutCTe>'$cXML  // Inutilização
   cSchemaFilename := ::cPastaSchemas+'\CTe\inutCte_v'+::cVersao_CTe+'.xsd'
ELSEIF '</cancCTe>'$cXML  // Cancelamento
   cSchemaFilename := ::cPastaSchemas+'\CTe\cancCte_v'+::cVersao_CTe+'.xsd'
ELSEIF '</consStatServCte>'$cXML  // Consulta status
   cSchemaFilename := ::cPastaSchemas+'\CTe\consStatServCte_v'+::cVersao_CTe+'.xsd'
ELSEIF '</eventoCTe>'$cXML  // Registro de evento
   cSchemaFilename := ::cPastaSchemas+'\CTe\eventoCTe_v'+::cVersao_CTe+'.xsd'
ELSEIF '</evCancCTe>'$cXML  // Cancelamento por evento
   cSchemaFilename := ::cPastaSchemas+'\CTe\evCancCTe_v'+::cVersao_CTe+'.xsd'
ELSEIF '</evCCeCTe>'$cXML  // Carta de correção por evento
   cSchemaFilename := ::cPastaSchemas+'\CTe\evCCeCTe_v'+::cVersao_CTe+'.xsd'
ELSEIF '</Signature>'$cXML .AND. !'</enviCTe>'$cXML .AND. !'</rodo>'$cXML .AND. !'</inutCTe>'$cXML .AND. !'</cancCTe>'$cXML .AND. !'</eventoCTe>'$cXML // Assinatura
   cSchemaFilename := ::cPastaSchemas+'\CTe\xmldsig-core-schema_v1.01.xsd'
ENDIF

IF !FILE(cSchemaFilename)
  aRETORNO['MSG']:='Arquivo do schema não encontrado '+cSchemaFilename
  RETURN(aRETORNO)
ENDIF

TRY
  IF '</Signature>' $ cXML .AND. !'</enviCTe>' $ cXML .AND. !'</rodo>' $ cXML .AND. !'</inutCTe>'$cXML .AND. !'</cancCTe>'$cXML .AND. !'</eventoCTe>'$cXML
      oSchema:add( 'http://www.w3.org/2000/09/xmldsig#', cSchemaFilename )
   ELSE
      oSchema:add( 'http://www.portalfiscal.inf.br/cte', cSchemaFilename )
   ENDIF
CATCH oError
   aRETORNO['MSG']:='Falha '+HB_OsNewLine()+ ;
                    'Error: '+Transform(oError:GenCode, nil)       + ';' +HB_OsNewLine()+;
                    'SubC: '+Transform(oError:SubCode, nil)        + ';' +HB_OsNewLine()+;
                    'OSCode: '+Transform(oError:OsCode,  nil)      + ';' +HB_OsNewLine()+;
                    'SubSystem: '+Transform(oError:SubSystem, nil) + ';' +HB_OsNewLine()+;
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
aRETORNO['STATUS']:=.T.

RETURN(aRETORNO)



Method ctAssinaXML(cXML,cID,cURI) Class oCTe_SEFAZ
/*
   Assina o XML
   Mauricio Cruz - 19/07/2013
*/
LOCAL oDOMDoc, oXmldsig, DSIGNS, oCert, oStoreMem, dsigKey, signedKey
LOCAL cXMLSig:=''
LOCAL PosIni:=0, PosFim:=0, nP:=0, nResult:=0
LOCAL aRETORNO:=HASH()

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

cXML:=STRTRAN(cXML,'<Signature></Signature>','<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">'+;
                                                '<SignedInfo>'+;
                                                   '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'+;
                                                   '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>'+;
                                                   '<Reference URI="#'+cURI+cID+'">'+;
                                                      '<Transforms>'+;
                                                         '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>'+;
                                                         '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'+;
                                                      '</Transforms>'+;
                                                      '<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>'+;
                                                      '<DigestValue></DigestValue>'+;
                                                   '</Reference>'+;
                                                '</SignedInfo>'+;
                                                '<SignatureValue></SignatureValue>'+;
                                                '<KeyInfo>'+;
                                                   '<X509Data>'+;
                                                   '<X509Certificate></X509Certificate>'+;
                                                   '</X509Data>'+;
                                                '</KeyInfo>'+;
                                             '</Signature>')

IF ::lCte_Emulador
   aRETORNO['STATUS']:=.T.
   aRETORNO['XML']:=cXML
   RETURN(aRETORNO)
ENDIF

// Inicializa o objeto do DOMDocument
TRY
   #ifdef __XHARBOUR__
      oDOMDoc := xhb_CreateObject(_MSXML2_DOMDocument_Ass)
   #else
      oDOMDoc := win_oleCreateObject(_MSXML2_DOMDocument_Ass)
   #endif
CATCH
   aRETORNO['MSG']:='Nao foi possível carregar '+ _MSXML2_DOMDocument_Ass
   RETURN(aRETORNO)
END
oDOMDoc:async = .F.
oDOMDoc:resolveExternals := .F.
oDOMDoc:validateOnParse  = .T.
oDOMDoc:preserveWhiteSpace = .T.

// inicializa o objeto do MXDigitalSignature
TRY
   #ifdef __XHARBOUR__
      oXmldsig := xhb_CreateObject( _MSXML2_MXDigitalSignature )
   #else
      oXmldsig := win_oleCreateObject( _MSXML2_MXDigitalSignature )
   #endif
CATCH
   aRETORNO['MSG']:='Nao foi possível carregar ' + _MSXML2_MXDigitalSignature
   RETURN(aRETORNO)
END

// carrega o arquivo XML para o DOM
oDOMDoc:LoadXML(cXML)
IF oDOMDoc:parseError:errorCode<>0
   aRETORNO['MSG']:=' Assinar: Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_OsNewLine()+;
                    ' Linha: '              + STR(oDOMDoc:parseError:line)+HB_OsNewLine()+;
                    ' Caractere na linha: ' + STR(oDOMDoc:parseError:linepos)+HB_OsNewLine()+;
                    ' Causa do erro: '      + oDOMDoc:parseError:reason+HB_OsNewLine()+;
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
oCert:=::ctPegaObjetoCertificado()
IF oCert == Nil
   aRETORNO['MSG']  := 'Certificado não encontrado, Favor revisar a instalação do Certificado.'
   RETURN(aRETORNO)
ENDIF

// cria o objeto de Store da capicom
#ifdef __XHARBOUR__
   oStoreMem := xhb_CreateObject('CAPICOM.Store')
#else
   oStoreMem := win_oleCreateObject('CAPICOM.Store')
#endif

// Aloca o certificado na memoria
TRY
   oStoreMem:open(_CAPICOM_MEMORY_STORE,'Memoria',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
CATCH oError
   aRETORNO['MSG']:='Falha ao alocar o certificado na memoria '+HB_OsNewLine()+ ;
                    'Error: '     + Transform(oError:GenCode, nil)   + ';' +HB_OsNewLine()+ ;
                    'SubC: '      + Transform(oError:SubCode, nil)   + ';' +HB_OsNewLine()+ ;
                    'OSCode: '    + Transform(oError:OsCode,  nil)   + ';' +HB_OsNewLine()+ ;
                    'SubSystem: ' + Transform(oError:SubSystem, nil) + ';' +HB_OsNewLine()+ ;
                    'Mensangem: ' + oError:Description
   RETURN(aRETORNO)
END

// Aloca o certificado na Capicom
TRY
   oStoreMem:Add(oCert)
CATCH oError
   aRETORNO['MSG']:='Falha ao aloca o certificado na memoria da Capicom '+HB_OsNewLine()+;
                    'Error: '     + Transform(oError:GenCode, nil)   + ';' +HB_OsNewLine()+;
                    'SubC: '      + Transform(oError:SubCode, nil)   + ';' +HB_OsNewLine()+;
                    'OSCode: '    + Transform(oError:OsCode,  nil)   + ';' +HB_OsNewLine()+;
                    'SubSystem: ' + Transform(oError:SubSystem, nil) + ';' +HB_OsNewLine()+;
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

aRETORNO:=::ctValidaXML('<Signature '+::oFuncoes:pegaTag(cXMLSig,'Signature')+'</Signature>')
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=cXMLSig

RETURN(aRETORNO)


METHOD ctPegaObjetoCertificado() Class oCTe_SEFAZ
/*
   Carrega o objeto do certificado - do projeto hbNFE
   Mauricio Cruz - 22/07/2013
*/
LOCAL oStore, oCertificados, oResult, nI
LOCAL SubjectName:=''
   
TRY
   #ifdef __XHARBOUR__
      oStore := xhb_CreateObject( "CAPICOM.Store" )
   #else
      oStore := win_oleCreateObject( "CAPICOM.Store" )
   #endif
CATCH
   oResult := 'Certificado não identificado'
END

oStore:open(_CAPICOM_CURRENT_USER_STORE,'My',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
oCertificados:=oStore:Certificates()
   
FOR nI=1 TO oCertificados:Count()
   IF !EMPTY( ::cSerialCert )
      IF oCertificados:Item(nI):SerialNumber == ::cSerialCert
         oResult := oCertificados:Item(nI)
         EXIT
      ENDIF
   ELSEIF !EMPTY( SubjectName )
      IF Upper( Alltrim(oCertificados:Item(nI):SubjectName) ) == SubjectName
         oResult := oCertificados:Item(nI)
         EXIT
      ENDIF
   ENDIF
NEXT
oCertificados := Nil
oStore := Nil

RETURN (oResult)


Method ctComunicaWebService(cXML,cSoap,cService) Class oCTe_SEFAZ
/*
   Faz a comunicação com o webservice
   Mauricio Cruz - 23/05/2013
*/
LOCAL oServerWS
LOCAL aRETORNO:=HASH()
LOCAL cCERT:='', cUrlWS:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF cXML=NIL .OR. EMPTY(cXML)
   aRETORNO['MSG']:='Favor informar o arquivo de XML.'
   RETURN(aRETORNO)
ENDIF

TRY
   cCERT := ::ctPegaCNCertificado()
CATCH
END
IF EMPTY(cCERT)
   aRETORNO['MSG']:='Não foi possível carregar as informações do certificado.'
   RETURN(aRETORNO)
ENDIF

IF 'https' $ cService
   cUrlWS:=cService
ELSE
   cUrlWS:=::ctLinkWebService(cService)
ENDIF
IF EMPTY(cUrlWS)
   aRETORNO['MSG']:='Webservice não localizado'
   RETURN(aRETORNO)
ENDIF

TRY
   oServerWS:=xhb_CreateObject( _MSXML2_ServerXMLHTTP )
   oServerWS:setOption( 3, 'CURRENT_USER\MY\'+cCERT )
   oServerWS:open('POST', cUrlWS, .F.)
   oServerWS:setRequestHeader('SOAPAction', cSoap )
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
   oDOMDoc:=xhb_CreateObject(_MSXML2_DOMDocument)
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
   aRETORNO['MSG']:='Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_OsNewLine()+;
                    ' Linha: '+STR(oDOMDoc:parseError:line)                                       +HB_OsNewLine()+;
                    ' Caractere na linha: '+STR(oDOMDoc:parseError:linepos)                       +HB_OsNewLine()+;
                    ' Causa do erro: '+oDOMDoc:parseError:reason                                  +HB_OsNewLine()+;
                    ' Code: '+STR(oDOMDoc:parseError:errorCode)
  RETURN(aRETORNO)
ENDIF

TRY
  oServerWS:send(oDOMDoc:xml)
CATCH e
   aRETORNO['MSG']:='Falha: Não foi possível conectar-se ao servidor do SEFAZ, Servidor inativou ou inoperante.'+HB_OsNewLine()+;
                    'Error: '+Transform(e:GenCode,nil)                                                      +';'+HB_OsNewLine()+;
                    'SubC: '+Transform(e:SubCode,nil)                                                       +';'+HB_OsNewLine()+;
                    'OSCode: '+Transform(e:OsCode,nil)                                                      +';'+HB_OsNewLine()+;
                    'SubSystem: '+Transform(e:SubSystem,nil)                                                +';'+HB_OsNewLine()+;
                    'Mensangem: '+e:Description
  RETURN(aRETORNO)
END
DO WHILE oServerWS:readyState <> 4
  millisec(500)
ENDDO
aRETORNO['MSG']:='Comunicação com o webservice finalizada com sucesso.'
aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=::oFuncoes:RemoveAcentuacao(oServerWS:responseText)

RETURN(aRETORNO)



Method ctPegaCNCertificado() Class oCTe_SEFAZ
/*
   Pega o CN do certificado - do projeto hbNFE
   Mauricio Cruz - 22/07/2013
*/
LOCAL oStore, oResult, oCertificados
LOCAL cSubjectName:='', cCN:=''
LOCAL mI:=0

TRY
   #ifdef __XHARBOUR__
      oStore := xhb_CreateObject( "CAPICOM.Store" )
   #else
      oStore := win_oleCreateObject( "CAPICOM.Store" )
   #endif
CATCH
END

IF oStore = Nil
   RETURN('')
ENDIF

oStore:open(_CAPICOM_CURRENT_USER_STORE,'My',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
oCertificados:=oStore:Certificates()
FOR mI=1 TO oCertificados:Count()
   IF oCertificados:Item(mI):SerialNumber = ::cSerialCert
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


Method ctLinkWebService(cServ) Class oCTe_SEFAZ
/*
   Links dos webservices do MDFe
   Mauricio Cruz - 22/05/2013
*/
LOCAL aWEB:={}
LOCAL nSCAN:=0
LOCAL cRET:=''

//             Serviço                 Verc   Produção                                                                Homologação
IF ::tpEmis='7' .OR. ::cCte_Estado='AC' .OR. ::cCte_Estado='AL'.OR. ::cCte_Estado='AM' .OR.;
   ::cCte_Estado='BA' .OR. ::cCte_Estado='CE' .OR. ::cCte_Estado='DF' .OR. ::cCte_Estado='ES' .OR.;
   ::cCte_Estado='GO' .OR. ::cCte_Estado='MA' .OR. ::cCte_Estado='PA' .OR. ::cCte_Estado='PB' .OR.;
   ::cCte_Estado='PI' .OR. ::cCte_Estado='RJ' .OR. ::cCte_Estado='RN' .OR. ::cCte_Estado='RO' .OR.;
   ::cCte_Estado='SC' .OR. ::cCte_Estado='SE' .OR. ::cCte_Estado='TO' // SVRS
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://cte.sefaz.rs.gov.br/ws/cterecepcao/CteRecepcao.asmx'            ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cterecepcao/CteRecepcao.asmx'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://cte.sefaz.rs.gov.br/ws/cteretrecepcao/CteRetRecepcao.asmx'      ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cteretrecepcao/CteRetRecepcao.asmx'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://cte.sefaz.rs.gov.br/ws/ctecancelamento/ctecancelamento.asmx'    ,'https://homologacao.cte.sefaz.rs.gov.br/ws/ctecancelamento/ctecancelamento.asmx'})
   AADD(aWEB,{'CteInutilizacao'      ,'1.00','https://cte.sefaz.rs.gov.br/ws/cteinutilizacao/cteinutilizacao.asmx'    ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cteinutilizacao/cteinutilizacao.asmx'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://cte.sefaz.rs.gov.br/ws/cteconsulta/cteconsulta.asmx'            ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cteconsulta/cteconsulta.asmx'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://cte.sefaz.rs.gov.br/ws/ctestatusservico/ctestatusservico.asmx'  ,'https://homologacao.cte.sefaz.rs.gov.br/ws/ctestatusservico/ctestatusservico.asmx'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://cte.sefaz.rs.gov.br/ws/CteRecepcaoEvento/CteRecepcaoEvento.asmx','https://homologacao.cte.sefaz.rs.gov.br/ws/CteRecepcaoEvento/CteRecepcaoEvento.asmx'})         
ELSEIF ::tpEmis='8' .OR. ::cCte_Estado='AP' .OR. ::cCte_Estado='PE' .OR. ::cCte_Estado='RR'  // SVSP
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcao.asmx'       ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/CteRecepcao.asmx'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/CteRetRecepcao.asmx'    ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/CteRetRecepcao.asmx'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/CteCancelamento.asmx'   ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/CteCancelamento.asmx'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/CteConsulta.asmx'       ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/CteConsulta.asmx'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/CteStatusServico.asmx'  ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/CteStatusServico.asmx'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/CteRecepcaoEvento.asmx' ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/CteRecepcaoEvento.asmx'})
ELSEIF ::cCte_Estado='MT'
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://cte.sefaz.mt.gov.br/ctews/services/CteRecepcao'      ,'https://homologacao.sefaz.mt.gov.br/ctews/services/CteRecepcao'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://cte.sefaz.mt.gov.br/ctews/services/CteRetRecepcao'   ,'https://homologacao.sefaz.mt.gov.br/ctews/services/CteRetRecepcao'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://cte.sefaz.mt.gov.br/ctews/services/CteCancelamento'  ,'https://homologacao.sefaz.mt.gov.br/ctews/services/CteCancelamento'})   
   AADD(aWEB,{'CteInutilizacao'      ,'1.00','https://cte.sefaz.mt.gov.br/ctews/services/CteInutilizacao'  ,'https://homologacao.sefaz.mt.gov.br/ctews/services/CteInutilizacao'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://cte.sefaz.mt.gov.br/ctews/services/CteConsulta'      ,'https://homologacao.sefaz.mt.gov.br/ctews/services/CteConsulta'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://cte.sefaz.mt.gov.br/ctews/services/CteStatusServico' ,'https://homologacao.sefaz.mt.gov.br/ctews/services/CteStatusServico'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://cte.sefaz.mt.gov.br/ctews/services/cteRecepcaoEvento','https://homologacao.sefaz.mt.gov.br/ctews/services/cteRecepcaoEvento'})   
ELSEIF ::cCte_Estado='MS'
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://producao.cte.ms.gov.br/cteWEB/CteRecepcao.asmx'      ,'https://homologacao.cte.ms.gov.br/cteWEB/CteRecepcao.asmx'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://producao.cte.ms.gov.br/cteWEB/CteRetRecepcao.asmx'   ,'https://homologacao.cte.ms.gov.br/cteWEB/CteRetRecepcao.asmx'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://producao.cte.ms.gov.br/cteWEB/CteCancelamento.asmx'  ,'https://homologacao.cte.ms.gov.br/cteWEB/CteCancelamento.asmx'})
   AADD(aWEB,{'CteInutilizacao'      ,'1.00','https://producao.cte.ms.gov.br/cteWEB/CteInutilizacao.asmx'  ,'https://homologacao.cte.ms.gov.br/cteWEB/CteInutilizacao.asmx'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://producao.cte.ms.gov.br/cteWEB/CteConsulta.asmx'      ,'https://homologacao.cte.ms.gov.br/cteWEB/CteConsulta.asmx'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://producao.cte.ms.gov.br/cteWEB/CteStatusServico.asmx' ,'https://homologacao.cte.ms.gov.br/cteWEB/CteStatusServico.asmx'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://producao.cte.ms.gov.br/cteWEB/cteRecepcaoEvento.asmx','https://homologacao.cte.ms.gov.br/cteWEB/cteRecepcaoEvento.asmx'})   
ELSEIF ::cCte_Estado='MG'
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://cte.fazenda.mg.gov.br/cte/services/CteRecepcao'      ,'https://hcte.fazenda.mg.gov.br/cte/services/CteRecepcao'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://cte.fazenda.mg.gov.br/cte/services/CteRetRecepcao'   ,'https://hcte.fazenda.mg.gov.br/cte/services/CteRetRecepcao'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://cte.fazenda.mg.gov.br/cte/services/CteCancelamento'  ,'https://hcte.fazenda.mg.gov.br/cte/services/CteCancelamento'})
   AADD(aWEB,{'CteInutilizacao'      ,'1.00','https://cte.fazenda.mg.gov.br/cte/services/CteInutilizacao'  ,'https://hcte.fazenda.mg.gov.br/cte/services/CteInutilizacao'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://cte.fazenda.mg.gov.br/cte/services/CteConsulta'      ,'https://hcte.fazenda.mg.gov.br/cte/services/CteConsulta'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://cte.fazenda.mg.gov.br/cte/services/CteStatusServico' ,'https://hcte.fazenda.mg.gov.br/cte/services/CteStatusServico'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://cte.fazenda.mg.gov.br/cte/services/RecepcaoEvento'   ,'https://hcte.fazenda.mg.gov.br/cte/services/cteRecepcaoEvento'})
ELSEIF ::cCte_Estado='PR'
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://cte.fazenda.pr.gov.br/cte/CteRecepcao'           ,'https://homologacao.cte.fazenda.pr.gov.br/cte/CteRecepcao'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://cte.fazenda.pr.gov.br/cte/CteRetRecepcao'        ,'https://homologacao.cte.fazenda.pr.gov.br/cte/CteRetRecepcao'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://cte.fazenda.pr.gov.br/cte/CteCancelamento'       ,'https://homologacao.cte.fazenda.pr.gov.br/cte/CteCancelamento'})
   AADD(aWEB,{'CteInutilizacao'      ,'1.00','https://cte.fazenda.pr.gov.br/cte/CteInutilizacao'       ,'https://homologacao.cte.fazenda.pr.gov.br/cte/CteInutilizacao'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://cte.fazenda.pr.gov.br/cte/CteConsulta'           ,'https://homologacao.cte.fazenda.pr.gov.br/cte/CteConsulta'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://cte.fazenda.pr.gov.br/cte/CteStatusServico'      ,'https://homologacao.cte.fazenda.pr.gov.br/cte/CteStatusServico'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://cte.fazenda.pr.gov.br/cte/cteRecepcaoEvento?wsdl','https://homologacao.cte.fazenda.pr.gov.br/cte/cteRecepcaoEvento?wsdl'})   
ELSEIF ::cCte_Estado='RS'
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://cte.sefaz.rs.gov.br/ws/cterecepcao/CteRecepcao.asmx'             ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cterecepcao/CteRecepcao.asmx'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://cte.sefaz.rs.gov.br/ws/cteretrecepcao/CteRetRecepcao.asmx'       ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cteretrecepcao/CteRetRecepcao.asmx'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://cte.sefaz.rs.gov.br/ws/ctecancelamento/ctecancelamento.asmx'     ,'https://homologacao.cte.sefaz.rs.gov.br/ws/ctecancelamento/ctecancelamento.asmx'})
   AADD(aWEB,{'CteInutilizacao'      ,'1.00','https://cte.sefaz.rs.gov.br/ws/cteinutilizacao/cteinutilizacao.asmx'     ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cteinutilizacao/cteinutilizacao.asmx'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://cte.sefaz.rs.gov.br/ws/cteconsulta/cteconsulta.asmx'             ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cteconsulta/cteconsulta.asmx'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://cte.sefaz.rs.gov.br/ws/ctestatusservico/ctestatusservico.asmx'   ,'https://homologacao.cte.sefaz.rs.gov.br/ws/ctestatusservico/ctestatusservico.asmx'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://cte.sefaz.rs.gov.br/ws/cteRecepcaoEvento/cteRecepcaoEvento.asmx' ,'https://homologacao.cte.sefaz.rs.gov.br/ws/cteRecepcaoEvento/cteRecepcaoEvento.asmx'})   
ELSEIF ::cCte_Estado='SP'   
   AADD(aWEB,{'CteRecepcao'          ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcao.asmx'      ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcao.asmx'})
   AADD(aWEB,{'CteRetRecepcao'       ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteRetRecepcao.asmx'   ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteRetRecepcao.asmx'})
   AADD(aWEB,{'CteCancelamento'      ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteCancelamento.asmx'  ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteCancelamento.asm'})
   AADD(aWEB,{'CteInutilizacao'      ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteInutilizacao.asmx'  ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteInutilizacao.asmx'})
   AADD(aWEB,{'CteConsultaProtocolo' ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteConsulta.asmx'      ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteConsulta.asmx'})
   AADD(aWEB,{'CteStatusServico'     ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteStatusServico.asmx' ,'https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteStatusServico.asmx'})
   AADD(aWEB,{'cteRecepcaoEvento'    ,'1.00','https://nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcaoEvento.asmx','https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcaoEvento.asmx'})   
ENDIF

nSCAN:=ASCAN(aWEB,{|x| x[1]=cServ})
IF nSCAN>0
   cRET:=aWEB[nSCAN,IF(::tpAmb='1',3,4)]
ENDIF
return(cRET)


Method ctSoapAction(cXML,cServ) Class oCTe_SEFAZ
/*
   Empacota do XML no soup action correspondente
   Mauricio Cruz - 22/07/2013
*/
cXML:='<?xml version="1.0" encoding="utf-8"?>'+;
      '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'+;
         '<soap12:Header>'+;
            '<cteCabecMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/'+cServ+'">'+;
               '<cUF>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2)))+'</cUF>'+;
               '<versaoDados>'+::cVersao_DADOS+'</versaoDados>'+;
            '</cteCabecMsg>'+;
         '</soap12:Header>'+;
         '<soap12:Body>'+;
            '<cteDadosMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/'+cServ+'">'+;
                cXML+;
            '</cteDadosMsg>'+;
         '</soap12:Body>'+;
      '</soap12:Envelope>'
RETURN(cXML)



Method ctPegaRetornoSEFAZ(cXML) Class oCTe_SEFAZ
/*
   Lê o retorno do sefaz
   Mauricio Cruz - 22/07/2013
*/
LOCAL aRETORNO:=HASH()

IF 'cteRecepcaoLoteResult'$cXML
   cXML:=::oFuncoes:pegaTag(cXML,'retEnviCte')
   aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXML,'tpAmb')   
   aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXML,'cUF')
   aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXML,'xMotivo')
   cXML:=::oFuncoes:pegaTag(cXML,'infRec')
   aRETORNO['nRec']     := ::oFuncoes:pegaTag(cXML,'nRec')
   aRETORNO['dhRecbto'] := ::oFuncoes:pegaTag(cXML,'dhRecbto')
   aRETORNO['tMed']     := ::oFuncoes:pegaTag(cXML,'tMed')
ELSEIF 'cteRetRecepcaoResult'$cXML
   cXML:=::oFuncoes:pegaTag(cXML,'retConsReciCTe')
   aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXML,'tpAmb')
   aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['nRec']     := ::oFuncoes:pegaTag(cXML,'nRec')
   aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXML,'xMotivo')
   aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXML,'cUF')
   cXML:=::oFuncoes:pegaTag(cXML,'infProt')
   aRETORNO['infProt']    := '<infProt '+cXML+'</infProt>'
   IF '<infProt <tpAmb>'$aRETORNO['infProt']
      aRETORNO['infProt']:=STRTRAN(aRETORNO['infProt'],'<infProt <tpAmb>','<infProt><tpAmb>')
   ENDIF
   aRETORNO['tpAmb_cte']    := ::oFuncoes:pegaTag(cXML,'tpAmb')
   aRETORNO['verAplic_cte'] := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['chCTe']        := ::oFuncoes:pegaTag(cXML,'chCTe')
   aRETORNO['dhRecbto']     := ::oFuncoes:pegaTag(cXML,'dhRecbto')
   aRETORNO['nProt']        := ::oFuncoes:pegaTag(cXML,'nProt')
   aRETORNO['digVal']       := ::oFuncoes:pegaTag(cXML,'digVal')
   aRETORNO['cStat_cte']    := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo_cte']  := ::oFuncoes:pegaTag(cXML,'xMotivo')
ELSEIF 'cteInutilizacaoCTResult'$cXML   
   cXML:=::oFuncoes:pegaTag(cXML,'infInut')
   aRETORNO['infInut']    := '<infInut '+cXML+'</infInut>'
   IF '<infInut <tpAmb>'$aRETORNO['infInut']
      aRETORNO['infInut']:=STRTRAN(aRETORNO['infInut'],'<infInut <tpAmb>','<infInut><tpAmb>')
   ENDIF
   aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXML,'tpAmb')
   aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXML,'xMotivo')
   aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXML,'cUF')
   aRETORNO['ano']      := ::oFuncoes:pegaTag(cXML,'ano')
   aRETORNO['CNPJ']     := ::oFuncoes:pegaTag(cXML,'CNPJ')
   aRETORNO['mod']      := ::oFuncoes:pegaTag(cXML,'mod')
   aRETORNO['serie']    := ::oFuncoes:pegaTag(cXML,'serie')
   aRETORNO['nCTIni']   := ::oFuncoes:pegaTag(cXML,'nCTIni')
   aRETORNO['CTFin']    := ::oFuncoes:pegaTag(cXML,'CTFin')
   aRETORNO['dhRecbto'] := ::oFuncoes:pegaTag(cXML,'dhRecbto')
   aRETORNO['nProt']    := ::oFuncoes:pegaTag(cXML,'nProt')
ELSEIF 'cteCancelamentoCTResult'$cXML   
   cXML:=::oFuncoes:pegaTag(cXML,'infCanc')
   aRETORNO['infCanc']  := '<infCanc '+cXML+'</infCanc>'
   IF '<infCanc <tpAmb>'$aRETORNO['infCanc']
      aRETORNO['infCanc']:=STRTRAN(aRETORNO['infCanc'],'<infCanc <tpAmb>','<infCanc><tpAmb>')
   ENDIF
   aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXML,'tpAmb')
   aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXML,'cUF')
   aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXML,'xMotivo')
   aRETORNO['chCTe']    := ::oFuncoes:pegaTag(cXML,'chCTe')
   aRETORNO['dhRecbto'] := ::oFuncoes:pegaTag(cXML,'dhRecbto')
   aRETORNO['nProt']    := ::oFuncoes:pegaTag(cXML,'nProt')
ELSEIF 'cteConsultaCTResult'$cXML
   cXML:=::oFuncoes:pegaTag(cXML,'retConsSitCTe')
   aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXML,'tpAmb')
   aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXML,'xMotivo')
   aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXML,'cUF')
   IF 'infCanc'$cXML
      aRETORNO['infCanc']:='<cteCancelamentoCTResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteCancelamento">'+;
                           '<retCancCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'">'+;
                           '<infCanc '+::oFuncoes:pegaTag(cXML,'infCanc')+'</infCanc>'+;
                           '</retCancCTe></cteCancelamentoCTResult>'
      IF '<infCanc <tpAmb>'$aRETORNO['infCanc']
         aRETORNO['infCanc']:=STRTRAN(aRETORNO['infCanc'],'<infCanc <tpAmb>','<infCanc><tpAmb>')
      ENDIF
      cXML:=::oFuncoes:pegaTag(aRETORNO['infCanc'],'infCanc')
      aRETORNO['nProt']    := ::oFuncoes:pegaTag(cXML,'nProt')
   ELSEIF 'retEventoCTe'$cXML
      cXML:=::oFuncoes:pegaTag(cXML,'retEventoCTe')  
      cXML:='<infEvento '+::oFuncoes:pegaTag(cXML,'infEvento')+'</infEvento>'
      aRETORNO['infEvento'] := cXML
      aRETORNO['tpAmb'] := ::oFuncoes:pegaTag(cXML,'tpAmb')
      aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXML,'verAplic')
      aRETORNO['cOrgao'] := ::oFuncoes:pegaTag(cXML,'cOrgao')
      aRETORNO['cStat'] := ::oFuncoes:pegaTag(cXML,'cStat')
      aRETORNO['xMotivo'] := ::oFuncoes:pegaTag(cXML,'xMotivo')
      aRETORNO['chCTe'] := ::oFuncoes:pegaTag(cXML,'chCTe')
      aRETORNO['tpEvento'] := ::oFuncoes:pegaTag(cXML,'tpEvento')
      aRETORNO['xEvento'] := ::oFuncoes:pegaTag(cXML,'xEvento')
      aRETORNO['nSeqEvento'] := ::oFuncoes:pegaTag(cXML,'nSeqEvento')
      aRETORNO['dhRegEvento'] := ::oFuncoes:pegaTag(cXML,'dhRegEvento')
      aRETORNO['nProt'] := ::oFuncoes:pegaTag(cXML,'nProt')
   ENDIF
ELSEIF 'cteStatusServicoCTResult'$cXML
   cXML:=::oFuncoes:pegaTag(cXML,'retConsStatServCte')
   aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXML,'tpAmb')
   aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXML,'xMotivo')
   aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXML,'cUF')
   aRETORNO['dhRecbto'] := ::oFuncoes:pegaTag(cXML,'dhRecbto')
   aRETORNO['tMed']     := ::oFuncoes:pegaTag(cXML,'tMed')
ELSEIF 'cteRecepcaoEventoResult'$cXML
   cXML:=::oFuncoes:pegaTag(cXML,'infEvento')
   aRETORNO['infEvento']   := '<infEvento '+cXML+'</infEvento>'
   aRETORNO['tpAmb']       := ::oFuncoes:pegaTag(cXML,'tpAmb')
   aRETORNO['verAplic']    := ::oFuncoes:pegaTag(cXML,'verAplic')
   aRETORNO['cOrgao']      := ::oFuncoes:pegaTag(cXML,'cOrgao')
   aRETORNO['cStat']       := ::oFuncoes:pegaTag(cXML,'cStat')
   aRETORNO['xMotivo']     := ::oFuncoes:pegaTag(cXML,'xMotivo')
   aRETORNO['chCTe']       := ::oFuncoes:pegaTag(cXML,'chCTe')
   aRETORNO['tpEvento']    := ::oFuncoes:pegaTag(cXML,'tpEvento')
   aRETORNO['xEvento']     := ::oFuncoes:pegaTag(cXML,'xEvento')
   aRETORNO['nSeqEvento']  := ::oFuncoes:pegaTag(cXML,'nSeqEvento')
   aRETORNO['dhRegEvento'] := ::oFuncoes:pegaTag(cXML,'dhRegEvento')
   aRETORNO['nProt']       := ::oFuncoes:pegaTag(cXML,'nProt')
ENDIF

RETURN(aRETORNO)


Method ctRetornoRecepcao(cREC) Class oCTe_SEFAZ
/*
   Retorno da recepção
   Mauricio Cruz - 22/07/2013
*/
LOCAL aRETORNO:=HASH(), aRET:=HASH()
LOCAL cXML:='', cXMLret:='', cRECIBO:='', cMOT2:=''
LOCAL lERRO:=.F.

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''
cXML+='<consReciCTe versao="'+::cVersao_CTe+'" xmlns="http://www.portalfiscal.inf.br/cte">'
cXML+=   '<tpAmb>'+::tpAmb+'</tpAmb>'
cXML+=   '<nRec>'+ALLTRIM(cREC)+'</nRec>'
cXML+='</consReciCTe>'

// valida XML da consulta
aRET:=::ctValidaXML(cXML)
IF !aRET['STATUS']
   RETURN(aRETORNO)
ENDIF

IF !::lCte_Emulador
   // empacota com SOAP ACTION
   cXML:=::ctSoapAction(cXML,'CteRetRecepcao')

   // envia o pedido de retorno de recepcao
   aRET:=::ctComunicaWebService(cXML,'http://www.portalfiscal.inf.br/cte/wsdl/CteRetRecepcao','CteRetRecepcao')
   IF !aRET['STATUS']
      RETURN(aRET)
   ENDIF
   cXMLret:=aRET['XML']
ELSE
   cXMLret:='<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Header><cteCabecMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteRetRecepcao"><cUF>50</cUF><versaoDados>'+::cVersao_CTe+'</versaoDados></cteCabecMsg></soap:Header><soap:Body><cteRetRecepcaoResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteRetRecepcao"><retConsReciCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'"><tpAmb>2</tpAmb><verAplic>MS_PL_CTe_104</verAplic><nRec>EMULACAO</nRec><cStat>104</cStat><xMotivo>Lote processado</xMotivo><cUF>50</cUF><protCTe versao="'+::cVersao_CTe+'"><infProt><tpAmb>2</tpAmb><verAplic>MS_PL_CTe_104</verAplic><chCTe>EMULACAO</chCTe><dhRecbto>2013-08-23T10:19:53</dhRecbto><nProt>EMULACAO</nProt><digVal>NcKKD+slBx42yyYfdpU5W6Wu4/w=</digVal><cStat>100</cStat><xMotivo>Autorizado o uso do CT-e</xMotivo></infProt></protCTe></retConsReciCTe></cteRetRecepcaoResult></soap:Body></soap:Envelope>'
ENDIF

IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"         
   SHOWMSG_EDIT(cXMLret,'RETORNO DE RECEPCAO')
ENDIF

// le a resposta
aRET:=::ctPegaRetornoSEFAZ(cXMLret)
TRY   // RESPONDEU SEM NADA NO XML
   IF VAL(aRET['cStat'])>=200 .OR. VAL(aRET['cStat'])=105
   ENDIF
CATCH
   aRETORNO['MSG']:='O SEFAZ não respondeu ao pedido da CT-e. Favor retentar o envio.'
   lERRO:=.T.
END   
IF lERRO
   RETURN(aRETORNO)
ENDIF


IF VAL(aRET['cStat'])>=200 .OR. VAL(aRET['cStat'])=105
   aRETORNO['MSG']:=aRET['cStat']+'-'+aRET['xMotivo']
   RETURN(aRETORNO)
ENDIF


IF VAL(aRET['cStat_cte'])=204 .OR. VAL(aRET['cStat_cte'])=539   // duplicidade de evento
   IF VAL(aRET['cStat_cte'])=539
      IF !::oCTe_GERAIS:uiSN(aRET['cStat_cte']+'-'+aRET['xMotivo_cte']+HB_OsNewLine()+;
                             'Chave Gerada: '+::cCte_Chave+HB_OsNewLine()+;
                             'Deseja tratar a duplicidade ?')
         aRETORNO['MSG']:=aRET['cStat_cte']+'-'+aRET['xMotivo_cte']
         RETURN(aRETORNO)
      ENDIF
   ENDIF

   cRECIBO:=ALLTRIM(SUBSTR(aRET['xMotivo_cte'],AT('nRec:',aRET['xMotivo_cte'])+5,AT(']',SUBSTR(aRET['xMotivo_cte'],AT('nRec:',aRET['xMotivo_cte'])+5,LEN(aRET['xMotivo_cte'])))-1))
   WHILE cRECIBO='999999999999999' 
      cMOT2:=SUBSTR(aRET['xMotivo_cte'],AT('nRec:'+cRECIBO,aRET['xMotivo_cte'])+15,LEN(aRET['xMotivo_cte']))
      cRECIBO:=ALLTRIM(SUBSTR(cMOT2,AT('nRec:',cMOT2)+5,AT(']',SUBSTR(cMOT2,AT('nRec:',cMOT2)+5,LEN(cMOT2)))-1))
   ENDDO

   aRET:=::ctRetornoRecepcao(cRECIBO)    //ALLTRIM(SUBSTR(aRET['xMotivo_cte'],AT('nRec:',aRET['xMotivo_cte'])+5,AT(']',SUBSTR(aRET['xMotivo_cte'],AT('nRec:',aRET['xMotivo_cte'])+5,LEN(aRET['xMotivo_cte'])))-1))
   IF !aRET['STATUS']
      RETURN(aRETORNO)
   ENDIF
   IF VAL(aRET['cStat'])>=200 .OR. VAL(aRET['cStat'])=105
      aRETORNO['MSG']:=aRET['cStat']+'-'+aRET['xMotivo']
      RETURN(aRETORNO)
   ENDIF
ENDIF

IF VAL(aRET['cStat_cte'])>=200 .OR. VAL(aRET['cStat_cte'])=105
   aRETORNO['MSG']:=aRET['cStat_cte']+'-'+aRET['xMotivo_cte']
   RETURN(aRETORNO)
ENDIF

aRETORNO['STATUS']:=.T.
aRETORNO['nRec']:=aRET['nRec']
aRETORNO['cStat']:=aRET['cStat']
aRETORNO['cStat_cte']:=aRET['cStat_cte']
aRETORNO['nProt']:=aRET['nProt']
aRETORNO['dhRecbto']:=aRET['dhRecbto']
aRETORNO['infProt']:=aRET['infProt']
aRETORNO['xMotivo_cte']:=aRET['xMotivo_cte']
aRETORNO['MSG']:=aRET['xMotivo_cte']

RETURN(aRETORNO)



Method ctConsultaProtocolo() Class oCTe_SEFAZ
/*
   Consulta de protocolo da CT-e
   Mauricio Cruz - 23/07/2013
*/
LOCAL aRET:=HASH()
LOCAL cXML:=''

cXML+='<consSitCTe versao="'+::cVersao_CTe+'" xmlns="http://www.portalfiscal.inf.br/cte">'
cXML+=   '<tpAmb>'+::tpAmb+'</tpAmb>'
cXML+=   '<xServ>CONSULTAR</xServ>'
cXML+=   '<chCTe>'+::cCte_Chave+'</chCTe>'
cXML+='</consSitCTe>'

// valida XML da consulta
aRET:=::ctValidaXML(cXML)
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

// empacota com SOAP ACTION
cXML:=::ctSoapAction(cXML,'CteConsulta')

// envia o pedido de consulta de protocolo
aRET:=::ctComunicaWebService(cXML,'http://www.portalfiscal.inf.br/cte/wsdl/CteConsulta','CteConsultaProtocolo')

IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

// le a resposta
aRET:=::ctPegaRetornoSEFAZ(aRET['XML'])
aRET['STATUS']:=.T.

RETURN(aRET)




Method ctStatusServico() Class oCTe_SEFAZ
/*
   Consulta o status do servico
   Mauricio Cruz
*/
LOCAL aRET:=HASH()
LOCAL cXML:=''

aRET['STATUS']:=.F.

cXML+='<consStatServCte versao="'+::cVersao_CTe+'" xmlns="http://www.portalfiscal.inf.br/cte">'
cXML+=   '<tpAmb>'+::tpAmb+'</tpAmb>'
cXML+=   '<xServ>STATUS</xServ>'
cXML+='</consStatServCte>'

// valida XML da consulta
aRET:=::ctValidaXML(cXML)
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

// empacota com SOAP ACTION
cXML:=::ctSoapAction(cXML,'CteStatusServico')

// envia o pedido de retorno de recepcao
aRET:=::ctComunicaWebService(cXML,'http://www.portalfiscal.inf.br/cte/wsdl/CteStatusServico','CteStatusServico')
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

// le a resposta
aRET:=::ctPegaRetornoSEFAZ(aRET['XML'])
IF VAL(aRET['cStat'])>=200
   RETURN(aRET)
ENDIF
aRET['STATUS']:=.T.

RETURN(aRET)



Method ctImprimeFastReport(cArqXml,lDESIGN,cARQpdf,lCANC) Class oCTe_SEFAZ
/*
   Impressao da DACTE no FastReport
   Mauricio Cruz - 06/06/2013
*/
LOCAL oFrPrn
LOCAL hRetorno:=HASH()
LOCAL mI:=0, nSCAN:=0, nFr:=0, nDetComp:=0, nDetInfNF:=0, nDetVeic:=0, nDetValePed:=0, nDetMot:=0, nDetLacRodo:=0
LOCAL aXML:={}, aREL:={}, aCOMP:={}, aInfNF:={}, aVeic:={}, aValePed:={}, aMot:={}, aLacRodo:={}
LOCAL cSitTrib:='', cVERSAO:='', cXML:=''

IF lCANC=NIL
   lCANC:=.F.
ENDIF

hRetorno['STATUS']:=.F.

IF ::cCte_DACTE=NIL .OR. !FILE(::cCte_DACTE)
   hRetorno['MSG']  := 'Favor informar o arquivo de XML da DACTE'
   Return(hRetorno)
ENDIF
IF ::cCte_FAST_LANG=NIL .OR. !FILE(::cCte_FAST_LANG)
   hRetorno['MSG']  := 'Favor informar o arquivo de linguagem do fastreport'
   Return(hRetorno)
ENDIF

AADD(aREL,{'ide.mod',''})
AADD(aREL,{'ide.serie',''})
AADD(aREL,{'ide.nCT',''})
AADD(aREL,{'ide.dhEmi',''})
AADD(aREL,{'ide.tpAmb',''})
AADD(aREL,{'ide.tpCTe',''})
AADD(aREL,{'ide.tpServ',''})
AADD(aREL,{'ide.forPag',''})
AADD(aREL,{'ide.CFOP',''})
AADD(aREL,{'ide.natOp',''})
AADD(aREL,{'ide.UFIni',''})
AADD(aREL,{'ide.xMunIni',''})
AADD(aREL,{'ide.UFFim',''})
AADD(aREL,{'ide.cMunFim',''})
AADD(aREL,{'ide.xMunFim',''})   
AADD(aREL,{'ide.cCancelada', IF(lCANC,'S','N')})   //QQQ ARRUMAR ISSO

AADD(aREL,{'toma03.toma',''})

AADD(aREL,{'enderToma.xLgr',''})
AADD(aREL,{'enderToma.nro',''})
AADD(aREL,{'enderToma.xCpl',''})
AADD(aREL,{'enderToma.xBairro',''})
AADD(aREL,{'enderToma.xMun',''})
AADD(aREL,{'enderToma.CEP',''})
AADD(aREL,{'enderToma.UF',''})
AADD(aREL,{'enderToma.xPais',''})

AADD(aREL,{'rem.CNPJ',''})
AADD(aREL,{'rem.CPF',''})
AADD(aREL,{'rem.IE',''})
AADD(aREL,{'rem.xNome',''})
AADD(aREL,{'rem.xFant',''})
AADD(aREL,{'rem.fone',''})

AADD(aREL,{'enderReme.xLgr',''})
AADD(aREL,{'enderReme.nro',''})
AADD(aREL,{'enderReme.xCpl',''})
AADD(aREL,{'enderReme.xBairro',''})
AADD(aREL,{'enderReme.xMun',''})
AADD(aREL,{'enderReme.CEP',''})
AADD(aREL,{'enderReme.UF',''})
AADD(aREL,{'enderReme.xPais',''})

AADD(aREL,{'dest.CNPJ',''})
AADD(aREL,{'dest.CPF',''})
AADD(aREL,{'dest.IE',''})
AADD(aREL,{'dest.xNome',''})
AADD(aREL,{'dest.fone',''})

AADD(aREL,{'enderDest.xLgr',''})
AADD(aREL,{'enderDest.nro',''})
AADD(aREL,{'enderDest.xCpl',''})
AADD(aREL,{'enderDest.xBairro',''})
AADD(aREL,{'enderDest.xMun',''})
AADD(aREL,{'enderDest.CEP',''})
AADD(aREL,{'enderDest.UF',''})
AADD(aREL,{'enderDest.xPais',''})

AADD(aREL,{'exped.CNPJ',''})
AADD(aREL,{'exped.CPF',''})
AADD(aREL,{'exped.IE',''})
AADD(aREL,{'exped.xNome',''})
AADD(aREL,{'exped.fone',''})

AADD(aREL,{'enderExped.xLgr',''})
AADD(aREL,{'enderExped.nro',''})
AADD(aREL,{'enderExped.xCpl',''})
AADD(aREL,{'enderExped.xBairro',''})
AADD(aREL,{'enderExped.xMun',''})
AADD(aREL,{'enderExped.CEP',''})
AADD(aREL,{'enderExped.UF',''})
AADD(aREL,{'enderExped.xPais',''})

AADD(aREL,{'receb.CNPJ',''})
AADD(aREL,{'receb.CPF',''})
AADD(aREL,{'receb.IE',''})
AADD(aREL,{'receb.xNome',''})
AADD(aREL,{'receb.fone',''})

AADD(aREL,{'enderReceb.xLgr',''})
AADD(aREL,{'enderReceb.nro',''})
AADD(aREL,{'enderReceb.xCpl',''})
AADD(aREL,{'enderReceb.xBairro',''})
AADD(aREL,{'enderReceb.xMun',''})
AADD(aREL,{'enderReceb.CEP',''})
AADD(aREL,{'enderReceb.UF',''})
AADD(aREL,{'enderReceb.xPais',''})

AADD(aREL,{'emit.CNPJ',''})
AADD(aREL,{'emit.IE',''})
AADD(aREL,{'emit.xNome',''})
AADD(aREL,{'emit.xFant',''})

AADD(aREL,{'enderEmit.xLgr',''})
AADD(aREL,{'enderEmit.nro',''})
AADD(aREL,{'enderEmit.xBairro',''})
AADD(aREL,{'enderEmit.cMun',''})
AADD(aREL,{'enderEmit.xMun',''})
AADD(aREL,{'enderEmit.CEP',''})
AADD(aREL,{'enderEmit.UF',''})
AADD(aREL,{'enderEmit.fone',''})

AADD(aREL,{'infCarga.proPred',''})
AADD(aREL,{'infCarga.xOutCat',''})
AADD(aREL,{'infCarga.vCarga',''})

AADD(aREL,{'infQ.cUnid',''})
AADD(aREL,{'infQ.tpMed',''})
AADD(aREL,{'infQ.qCarga',''})

AADD(aREL,{'seg.xSeg',''})
AADD(aREL,{'seg.respSeg',''})
AADD(aREL,{'seg.nApol',''})
AADD(aREL,{'seg.nAver',''})

AADD(aREL,{'vPrest.vTPrest',''})
AADD(aREL,{'vPrest.vRec',''})

AADD(aREL,{'ICMS60.vBCSTRet',''})
AADD(aREL,{'ICMS60.vICMSSTRet',''})

AADD(aREL,{'ICMS00.vBC',''})
AADD(aREL,{'ICMS20.vBC',''})
AADD(aREL,{'ICMS90.vBC',''})

AADD(aREL,{'ICMS00.pICMS',''})
AADD(aREL,{'ICMS20.pICMS',''})
AADD(aREL,{'ICMS90.pICMS',''})

AADD(aREL,{'ICMS00.vICMS',''})
AADD(aREL,{'ICMS20.vICMS',''})
AADD(aREL,{'ICMS90.vICMS',''})

AADD(aREL,{'ICMS20.pRedBC',''})
AADD(aREL,{'ICMS90.pRedBC',''})

AADD(aREL,{'compl.xObs',''})

AADD(aREL,{'rodo.RNTRC',''})
AADD(aREL,{'rodo.dPrev',''})
AADD(aREL,{'rodo.lota',''})
AADD(aREL,{'rodo.CIOT',''})

AADD(aREL,{'ObsCont.xCampo',''})
AADD(aREL,{'ObsCont.xTexto',''})

AADD(aREL,{'ObsFisco.xCampo',''})
AADD(aREL,{'ObsFisco.xTexto',''})

AADD(aREL,{'infProt.chCTe',''})
AADD(aREL,{'infProt.nProt',''}) 


aXML:=::oFuncoes:XMLnaArray(cArqXml,'cteProc')

IF LEN(aXML)<=0
   hRetorno['MSG']  := 'Não foi possível ler o arquivo XML.'
   Return(hRetorno)
ENDIF

cXML:=MEMOREAD(cArqXml)
IF '1.04' $ SUBSTR(cXML,AT('versao',cXML),13)
   cVERSAO:='1.04'
ELSEIF '2.00' $ SUBSTR(cXML,AT('versao',cXML),13)
   cVERSAO:='2.00'
ELSE
   hRetorno['MSG']  := 'Não foi possível identificar a versão do XML.'
   Return(hRetorno)
ENDIF

FOR mI:=1 TO LEN(aXML)

   IF aXML[mI,2]=NIL
      aXML[mI,2]:=''
   ENDIF

   // seta a variavel
   nSCAN:=ASCAN(aREL,{|x| x[1]=ALLTRIM(aXML[mI,4])+'.'+ALLTRIM(aXML[mI,1])  })
   IF nSCAN>0
      aREL[nSCAN,2]:=aXML[mI,2]
   ENDIF
   
   // Componentes do valor da prestação
   IF 'CTe.infCte.vPrest.Comp' $ aXML[mI,3] .AND. aXML[mI,4]='vPrest'
      nDetComp++
      AADD(aCOMP,{nDetComp,'',''})
   ENDIF
   IF aXML[mI,4]='Comp'
      nSCAN:=ASCAN(aCOMP,{|x| x[1]=nDetComp})
      IF nSCAN>0
         IF aXML[mI,1]='xNome'
            aCOMP[nSCAN,2]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='vComp'
            aCOMP[nSCAN,3]:=aXML[mI,2]
         ENDIF
      ENDIF
   ENDIF

   // Documentos Originários
   
   
   IF (cVERSAO='2.00' .AND. 'CTe.infCte.infCTeNorm' $ aXML[mI,3] .AND. aXML[mI,4]='infDoc') .OR.; 
      (cVERSAO='1.04' .AND. 'CTe.infCte.rem.infNF' $ aXML[mI,3] .AND. aXML[mI,4]='rem')
      nDetInfNF++
      AADD(aInfNF,{nDetInfNF,'','','','','','','','','','','','','','','',''})
      //               1     2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17
   ENDIF
   IF aXML[mI,4]='infNF' .OR. aXML[mI,4]='infNFe'
      nSCAN:=ASCAN(aInfNF,{|x| x[1]=nDetInfNF  })
      IF nSCAN>0
         IF aXML[mI,1]='nRoma'
            aInfNF[nSCAN,2]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='nPed'
            aInfNF[nSCAN,3]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='mod'
            aInfNF[nSCAN,4]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='serie'
            aInfNF[nSCAN,5]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='nDoc'
            aInfNF[nSCAN,6]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='dEmi'
            aInfNF[nSCAN,7]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='vBC'
            aInfNF[nSCAN,8]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='vICMS'
            aInfNF[nSCAN,9]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='vBCST'
            aInfNF[nSCAN,10]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='vST'
            aInfNF[nSCAN,11]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='vProd'
            aInfNF[nSCAN,12]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='vNF'
            aInfNF[nSCAN,13]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='nCFOP'
            aInfNF[nSCAN,14]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='nPeso'
            aInfNF[nSCAN,15]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='PIN'
            aInfNF[nSCAN,16]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='chave'
            aInfNF[nSCAN,17]:=aXML[mI,2]
         ENDIF
      ENDIF
   ENDIF
   
   // Identificação do Conjunto Transportador
   IF 'CTe.infCte.infCTeNorm.infModal.rodo.veic' $ aXML[mI,3] .AND. aXML[mI,4]='rodo'
      nDetVeic++
      AADD(aVeic,{nDetVeic,'','','','','','','','','','','','','','','','','',''})
      //               1   2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19
   ENDIF
   
   nSCAN:=ASCAN(aVeic,{|x| x[1]=nDetVeic  })
   IF nSCAN>0
      IF aXML[mI,4]='veic'
         IF aXML[mI,1]='cInt'
            aVeic[nSCAN,2]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='RENAVAM'
            aVeic[nSCAN,3]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='placa'
            aVeic[nSCAN,4]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='tara'
            aVeic[nSCAN,5]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='capKG'
            aVeic[nSCAN,6]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='capM3'
            aVeic[nSCAN,7]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='tpProp'
            aVeic[nSCAN,8]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='tpVeic'
            aVeic[nSCAN,9]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='tpRod'
            aVeic[nSCAN,10]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='tpCar'
            aVeic[nSCAN,11]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='UF'
            aVeic[nSCAN,12]:=aXML[mI,2]
         ENDIF
      ELSEIF aXML[mI,4]='prop'
         IF aXML[mI,1]='CPF'
            aVeic[nSCAN,13]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='CNPJ'
            aVeic[nSCAN,14]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='RNTRC'
            aVeic[nSCAN,15]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='xNome'
            aVeic[nSCAN,16]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='IE'
            aVeic[nSCAN,17]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='UF'
            aVeic[nSCAN,18]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='tpProp'
            aVeic[nSCAN,19]:=aXML[mI,2]
         ENDIF
      ENDIF
   ENDIF

   // Informações referente ao vale pedagio
   IF 'CTe.infCte.infCTeNorm.infModal.rodo.valePed' $ aXML[mI,3] .AND.aXML[mI,4]='rodo'
      nDetValePed++
      AADD(aValePed,{nDetValePed,'','',''})
      //                  1      2  3  4
   ENDIF
   IF aXML[mI,4]='valePed'
      nSCAN:=ASCAN(aValePed,{|x| x[1]=nDetValePed  })
      IF nSCAN>0
         IF aXML[mI,1]='CNPJForn'
            aValePed[nSCAN,2]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='nCompra'
            aValePed[nSCAN,3]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='CNPJPg'
            aValePed[nSCAN,4]:=aXML[mI,2]
         ENDIF
      ENDIF
   ENDIF
   

   // Identificação do motorista
   IF 'cteProc.CTe.infCte.infCTeNorm.infModal.rodo.mot' $ aXML[mI,3] .AND. aXML[mI,4]='rodo'
      nDetMot++
      AADD(aMot,{nDetMot,'',''})
      //            1    2  3
   ENDIF
   IF aXML[mI,4]='mot'
      nSCAN:=ASCAN(aMot,{|x| x[1]=nDetMot  })
      IF nSCAN>0
         IF aXML[mI,1]='xNome'
            aMot[nSCAN,2]:=aXML[mI,2]
         ELSEIF aXML[mI,1]='CPF'
            aMot[nSCAN,3]:=aXML[mI,2]
         ENDIF
      ENDIF
   ENDIF
   
   // Identificação dos lacres em transito
   IF 'cteProc.CTe.infCte.infCTeNorm.infModal.rodo.lacRodo' $ aXML[mI,3] .AND. aXML[mI,4]='rodo'
      nDetLacRodo++
      AADD(aLacRodo,{nDetLacRodo,''})
      //              1          2
   ENDIF
   IF aXML[mI,4]='lacRodo'
      nSCAN:=ASCAN(aLacRodo,{|x| x[1]=nDetLacRodo  })
      IF nSCAN>0
         IF aXML[mI,1]='nLacre'
            aLacRodo[nSCAN,2]:=aXML[mI,2]
         ENDIF
      ENDIF
   ENDIF

   // Situação tributária
   IF aXML[mI,4]='ICMS00'
      cSitTrib:='00-Prestação sujeito à tributação normal do ICMS'
   ELSEIF aXML[mI,4]='ICMS20'
      cSitTrib:='20-Prestação sujeito à tributação com redução de BC do ICMS'
   ELSEIF aXML[mI,4]='ICMS45'
      cSitTrib:='45-ICMS Isento, não Tributado ou diferido'
   ELSEIF aXML[mI,4]='ICMS60'
      cSitTrib:='60-ICMS cobrado por substituição tributária. Responsabilidade do recolhimento do ICMS atribuído ao tomador ou 3º por ST'
   ELSEIF aXML[mI,4]='ICMS90'
      cSitTrib:='90-ICMS Outros'
   ELSEIF aXML[mI,4]='ICMSOutraUF'
      cSitTrib:='ICMS devido à UF de origem da prestação, quando diferente da UF do emitente'
   ELSEIF aXML[mI,4]='ICMSSN'
      cSitTrib:='Simples Nacional'
   ENDIF
NEXT

oFrPrn:=frReportManager():new()

oFrPrn:LoadFromFile(::cCte_DACTE)
oFrPrn:LoadLangRes(::cCte_FAST_LANG)

oFrPrn:SetUserDataSet('COMP','COL001;COL002;COL003',{||nFr:=1},{||nFr++},{||nFr--},{||nFr>Len(aCOMP)},{|X| aCOMP[nFr,VAL(RIGHT(X,3))]})
oFrPrn:SetUserDataSet('infNF','COL001;COL002;COL003;COL004;COL005;COL006;COL007;COL008;COL009;COL010;COL011;COL012;COL013;COL014;COL015;COL016;COL017',{||nFr:=1},{||nFr++},{||nFr--},{||nFr>Len(aInfNF)},{|X| aInfNF[nFr,VAL(RIGHT(X,3))]})
oFrPrn:SetUserDataSet('veic','COL001;COL002;COL003;COL004;COL005;COL006;COL007;COL008;COL009;COL010;COL011;COL012;COL013;COL014;COL015;COL016;COL017;COL018;COL019',{||nFr:=1},{||nFr++},{||nFr--},{||nFr>Len(aVeic)},{|X| aVeic[nFr,VAL(RIGHT(X,3))]})
oFrPrn:SetUserDataSet('valePed','COL001;COL002;COL003;COL004',{||nFr:=1},{||nFr++},{||nFr--},{||nFr>Len(aValePed)},{|X| aValePed[nFr,VAL(RIGHT(X,3))]})
oFrPrn:SetUserDataSet('MOT','COL001;COL002;COL003',{||nFr:=1},{||nFr++},{||nFr--},{||nFr>Len(aMOT)},{|X| aMOT[nFr,VAL(RIGHT(X,3))]})
oFrPrn:SetUserDataSet('lacRodo','COL001;COL002',{||nFr:=1},{||nFr++},{||nFr--},{||nFr>Len(aLacRodo)},{|X| aLacRodo[nFr,VAL(RIGHT(X,3))]})

oFrPrn:LoadFromFile(::cCte_DACTE)
oFrPrn:LoadLangRes(::cCte_FAST_LANG)

oFrPrn:AddVariable('SitTrib','ICMS',"'"+cSitTrib+"'"  )

FOR mI:=1 TO LEN(aREL)
   oFrPrn:AddVariable(LEFT(aREL[mI,1],AT('.',aREL[mI,1])-1), STRTRAN(aREL[mI,1],'.','_'),"'"+aREL[mI,2]+"'" )
NEXT

oFrPrn:SetProperty("MailExport", "ShowDialog", .f.)
oFrPrn:SetEventHandler("MailExport", "OnSendMail", {|| ::oCTe_GERAIS:uiAviso('Atenção !!!, Por essa opção apenas é enviado o DACTE em formato PDF'),::oCTe_GERAIS:rgMySendMail(oFrPrn)})
oFrPrn:SetIcon(::nCte_Icon_resorce)
oFrPrn:SetTitle( 'DACTE' )

IF cARQpdf<>NIL
   oFrPrn:SetProperty("PDFExport", "ShowDialog", .f.)
   oFrPrn:PrepareReport()
   oFrPrn:SetProperty("PDFExport", "FileName", cARQpdf)

   oFrPrn:SetProperty("PDFExport", "Compressed", .T. )
   oFrPrn:SetProperty("PDFExport", "EmbeddedFonts", .T. )
   oFrPrn:SetProperty("PDFExport", "Background", .T. )
   oFrPrn:SetProperty("PDFExport", "PrintOptimized", .T. )
   oFrPrn:SetProperty("PDFExport", "Author", _Usuario() )
   oFrPrn:SetProperty("PDFExport", "Subject", 'Arquivo gerado automaticamente pelo sistema: ' + _Tipo_Sis()  )

   oFrPrn:DoExport("PDFExport")
   oFrPrn:SetProperty("PDFExport", "ShowDialog", .T.)
ELSE
   IF lDesign
      oFrPrn:DesignReport()
   ELSE
      oFrPrn:PreviewOptions:SetZoomMode(2)
      oFrPrn:ShowReport()
   ENDIF   
ENDIF
oFrPrn:DestroyFR()
oFrPrn:=NIL

hRetorno['STATUS']:=.T.

Return(hRetorno)


Method ctInutilizaCTe() Class oCTe_SEFAZ
/*
   Inutilizacao de CT-e
   Mauricio Cruz - 23/07/2013
*/
LOCAL cXML:='', cID:='', cXMLenv:=''
LOCAL aRET:=HASH()

aRET['STATUS']:=.F.

::cCte_CNPJ:=STRTRAN(STRTRAN(STRTRAN(::cCte_CNPJ,'/'),'-'),'.')
ASORT(::aCte_INUTILIZAR,,,{|x,y| x[1]<y[1] })

// gera o ID
cID:=ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2)))
cID+=::cCte_CNPJ+STRZERO(::aCte_INUTILIZAR[1,3],2)//  '57'
cID+=STRZERO(::aCte_INUTILIZAR[1,2],3)  // SERIE
cID+=STRZERO(::aCte_INUTILIZAR[1,1],9)  // NUM INI
cID+=STRZERO(::aCte_INUTILIZAR[LEN(::aCte_INUTILIZAR),1],9)

// gera o XML
cXML+='<inutCTe versao="'+::cVersao_CTe+'" xmlns="http://www.portalfiscal.inf.br/cte">'
cXML+=   '<infInut Id="ID'+cID+'">'
cXML+=      '<tpAmb>'+::tpAmb+'</tpAmb>'
cXML+=      '<xServ>INUTILIZAR</xServ>'
cXML+=      '<cUF>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2)))+'</cUF>'
cXML+=      '<ano>'+RIGHT(ALLTRIM(STR(YEAR(DATE()))),2)+'</ano>'
cXML+=      '<CNPJ>'+::cCte_CNPJ+'</CNPJ>'
cXML+=      '<mod>'+ALLTRIM(STRZERO(::aCte_INUTILIZAR[1,3],2))+'</mod>'
cXML+=      '<serie>'+ALLTRIM(STR(::aCte_INUTILIZAR[1,2]))+'</serie>'
cXML+=      '<nCTIni>'+ALLTRIM(STR(::aCte_INUTILIZAR[1,1]))+'</nCTIni>'
cXML+=      '<nCTFin>'+ALLTRIM(STR(::aCte_INUTILIZAR[LEN(::aCte_INUTILIZAR),1]))+'</nCTFin>'
cXML+=      '<xJust>'+ALLTRIM(::cCte_MOTIVO)+'</xJust>'
cXML+=   '</infInut>'
cXML+=   '<Signature></Signature>'
cXML+='</inutCTe>'

// assina
aRET:=::ctAssinaXML(cXML,cID,'ID')
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF
cXML:=aRET['XML']

// valida o XML de inutilizacao
aRET:=::ctValidaXML(cXML)
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF
cXMLenv:=cXML

IF !::lCte_Emulador
   // empacota no SOAP ACTION
   cXML:=::ctSoapAction(cXML,'CteInutilizacao')

   // envia o pedido de inutilizacao para o sefaz
   aRET:=::ctComunicaWebService(cXML,'http://www.portalfiscal.inf.br/cte/wsdl/CteInutilizacao','CteInutilizacao')
   IF !aRET['STATUS']
      RETURN(aRET)
   ENDIF
ELSE
   aRET['XML']:='<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Header><cteCabecMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteInutilizacao"><cUF>50</cUF><versaoDados>'+::cVersao_CTe+'</versaoDados></cteCabecMsg></soap:Header><soap:Body><cteInutilizacaoCTResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteInutilizacao"><retInutCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'"><infInut><tpAmb>2</tpAmb><verAplic>MS_PL_CTe_104</verAplic><cStat>102</cStat><xMotivo>Inutilizacao de numero homologado</xMotivo><cUF>50</cUF><ano>13</ano><CNPJ>04967710000146</CNPJ><mod>57</mod><serie>1</serie><nCTIni>0</nCTIni><nCTFin>0</nCTFin><dhRecbto>2013-08-23T10:46:59</dhRecbto><nProt>EMULACAO</nProt></infInut></retInutCTe></cteInutilizacaoCTResult></soap:Body></soap:Envelope>'
ENDIF

// le a resposta
aRET:=::ctPegaRetornoSEFAZ(aRET['XML'])
TRY
   IF VAL(aRET['cStat'])>=200
   ENDIF
CATCH
   aRET['MSG']:='O Sefaz não esta respondendo.'
   aRET['STATUS']:=.F.
   RETURN(aRET)
END

IF VAL(aRET['cStat'])>=200 .AND. VAL(aRET['cStat'])<>682
   aRET['MSG']:=aRET['cStat']+'-'+aRET['xMotivo']
   aRET['STATUS']:=.F.
   RETURN(aRET)
ENDIF

// anexa o protocolo ao arquivo XML de envio
aRET['XML']:='<?xml version="1.0" encoding="UTF-8" ?><infProc xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'">'+cXMLenv+aRET['infInut']+'</infProc>'
aRET['ID']:=cID
aRET['STATUS']:=.T.

RETURN(aRET)



Method ctCancelaCTe() Class oCTe_SEFAZ
/*
   Cancelamento de CT-e
   Mauricio Cruz - 23/07/2013
*/
LOCAL cXML:='', cXMLenv:=''
LOCAL aRET:=HASH()
aRET['STATUS']:=.F.

cXML:='<cancCTe versao="'+::cVersao_CTe+'" xmlns="http://www.portalfiscal.inf.br/cte">'
cXML+=   '<infCanc Id="ID'+::cCte_Chave+'">'
cXML+=      '<tpAmb>'+::tpAmb+'</tpAmb>'
cXML+=      '<xServ>CANCELAR</xServ>'
cXML+=      '<chCTe>'+::cCte_Chave+'</chCTe>'
cXML+=      '<nProt>'+::cCte_PROTOCOLO+'</nProt>'
cXML+=      '<xJust>'+::cCte_MOTIVO+'</xJust>'
cXML+=   '</infCanc>'
cXML+=   '<Signature></Signature>'
cXML+='</cancCTe>'

// assina
aRET:=::ctAssinaXML(cXML,::cCte_Chave,'ID')
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF
cXML:=aRET['XML']
 
// valida o XML de cancelamento
aRET:=::ctValidaXML(cXML)
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF
cXMLenv:=cXML

IF !::lCte_Emulador   
   // empacota no SOAP ACTION
   cXML:=::ctSoapAction(cXML,'CteCancelamento')

   // envia o pedido de cancelamento para o sefaz
   aRET:=::ctComunicaWebService(cXML,'http://www.portalfiscal.inf.br/cte/wsdl/CteCancelamento','CteCancelamento')
   IF !aRET['STATUS']
      RETURN(aRET)
   ENDIF
ELSE
   aRET['XML']:='<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Header><cteCabecMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteCancelamento"><cUF>50</cUF><versaoDados>'+::cVersao_CTe+'</versaoDados></cteCabecMsg></soap:Header><soap:Body><cteCancelamentoCTResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteCancelamento"><retCancCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'"><infCanc><tpAmb>2</tpAmb><cUF>50</cUF><verAplic>MS_PL_CTe_104</verAplic><cStat>101</cStat><xMotivo>Cancelamento de CT-e homologado[chCTe: EMULACAO ]</xMotivo><chCTe>EMULACAO</chCTe><dhRecbto>2013-08-23T10:41:23</dhRecbto><nProt>EMULACAO</nProt></infCanc></retCancCTe></cteCancelamentoCTResult></soap:Body></soap:Envelope>'
ENDIF

// le a resposta
aRET:=::ctPegaRetornoSEFAZ(aRET['XML'])
IF VAL(aRET['cStat'])=218  // trata duplicidade
   aRET:=::ctConsultaProtocolo()   
   aRET:=::ctPegaRetornoSEFAZ(aRET['infCanc'])
ENDIF
IF VAL(aRET['cStat'])>=200
   aRET['STATUS']:=.F.
   aRET['MSG']:=aRET['cStat']+'-'+aRET['xMotivo']
   RETURN(aRET)
ENDIF

aRET['XML']:='<?xml version="1.0" encoding="UTF-8" ?><cancProc xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'">'+cXMLenv+aRET['infCanc']+'</cancProc>'
aRET['STATUS']:=.T.

RETURN(aRET)



Method ctEventos(cXMLevento) Class oCTe_SEFAZ
/*
   Registro de Eventos da CTe
   Mauricio Cruz - 21/10/2013
*/
LOCAL cXML:='', cXMLenv:=''
LOCAL aRET:=HASH()
LOCAL cID:=''

aRET['MSG']:=''
aRET['STATUS']:=.F.

IF ::tpEvento=NIL .OR. EMPTY(::tpEvento)
   aRET['MSG']:='Tipo de evento não informado.'
ENDIF
IF ::nSeqEvento=NIL .OR. ::nSeqEvento<=0
   aRET['MSG']:='Sequencia do evento não informado.'
ENDIF
IF ::cCte_Chave=NIL .OR. EMPTY(::cCte_Chave)
   aRET['MSG']:='Chave da CTe vinculada não informada.'
ENDIF
IF cXMLevento=NIL .OR. EMPTY(cXMLevento)
   aRET['MSG']:='Estrutura XML do evento não informado.'
ENDIF

IF !EMPTY(aRET['MSG'])
   RETURN(aRET)
ENDIF

cID:='ID'+::tpEvento+::cCte_Chave+STRZERO(::nSeqEvento,2)

cXML:='<eventoCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'">'
cXML+=   '<infEvento Id="'+cID+'">'
cXML+=      '<cOrgao>'+ALLTRIM(STR(::oCTe_GERAIS:rgRetorna_uf(::cCte_Estado,2)))+'</cOrgao>'
cXML+=      '<tpAmb>'+::tpAmb+'</tpAmb>'
cXML+=      '<CNPJ>'+::cCte_CNPJ+'</CNPJ>'
cXML+=      '<chCTe>'+::cCte_Chave+'</chCTe>'
cXML+=      '<dhEvento>'+::oFuncoes:FormatDate(DATE(),'YYYY-MM-DD','-')+'T'+TIME()+'</dhEvento>' 
cXML+=      '<tpEvento>'+::tpEvento+'</tpEvento>'
cXML+=      '<nSeqEvento>'+STRZERO(::nSeqEvento,2)+'</nSeqEvento>'
cXML+=      '<detEvento versaoEvento="'+::cVersao_CTe+'">'
cXML+=         cXMLevento
cXML+=      '</detEvento>'
cXML+=   '</infEvento>'
cXML+=   '<Signature></Signature>'
cXML+='</eventoCTe>'

// assina
aRET:=::ctAssinaXML(cXML,cID,'')
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF
cXML:=aRET['XML']

// valida o XML de evento
aRET:=::ctValidaXML(cXML)
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

cXMLenv:=cXML

// empacota no SOAP ACTION
cXML:=::ctSoapAction(cXML,'CteRecepcaoEvento')

// envia o pedido de inutilizacao para o sefaz
aRET:=::ctComunicaWebService(cXML,'http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcaoEvento','cteRecepcaoEvento')
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

aRET['XML_EVENTO']:=cXMLenv

RETURN(aRET)


Method ctEventoCancelamento() Class oCTe_SEFAZ
/*
   Evento de Cancelamento
   Mauricio Cruz - 21/10/2013
*/
LOCAL cXML:='', cXMLenv:='', cRETcanc:=''
LOCAL aRET:=HASH()

aRET['MSG']:=''
aRET['STATUS']:=.F.

IF ::cCte_PROTOCOLO=NIL .OR. EMPTY(::cCte_PROTOCOLO)
   aRET['MSG']:='Protocolo da CTe para cancelamento não informado.'
ENDIF
IF ::cCte_MOTIVO=NIL .OR. EMPTY(::cCte_MOTIVO)
   aRET['MSG']:='Motivo do cancelamento não informado.'
ENDIF

IF !EMPTY(aRET['MSG'])
   RETURN(aRET)
ENDIF

::tpEvento:='110111'
cXML:='<evCancCTe>'
cXML+=   '<descEvento>Cancelamento</descEvento>'
cXML+=   '<nProt>'+::cCte_PROTOCOLO+'</nProt>'
cXML+=   '<xJust>'+::cCte_MOTIVO+'</xJust>'
cXML+='</evCancCTe>'

// valida o XML de evento de cancelamento
aRET:=::ctValidaXML(STRTRAN(cXML,'<evCancCTe>','<evCancCTe xmlns="http://www.portalfiscal.inf.br/cte">'))
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

IF !::lCte_Emulador  
   // executa o registro de evento
   aRET:=::ctEventos(cXML)
   IF !aRET['STATUS']
      RETURN(aRET)
   ENDIF
   cXMLenv:=aRET['XML_EVENTO']
ELSE
   aRET['XML']:='<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Header><cteCabecMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteConsulta"><cUF>50</cUF><versaoDados>'+::cVersao_CTe+'</versaoDados></cteCabecMsg></soap:Header><soap:Body><cteConsultaCTResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteConsulta"><retConsSitCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+::cVersao_CTe+'"><tpAmb>2</tpAmb><verAplic>MS_PL_CTe_200</verAplic><cStat>101</cStat><xMotivo>Cancelamento de CT-e homologado[chCTe: 50131004967710000146570010000030161000030165 ]</xMotivo><cUF>50</cUF><retCancCTe versao="'+::cVersao_CTe+'"><infCanc><tpAmb>2</tpAmb><cUF>50</cUF><verAplic>MS_PL_CTe_200</verAplic><cStat>101</cStat><xMotivo>Cancelamento de CT-e homologado</xMotivo><chCTe>50131004967710000146570010000030161000030165</chCTe><dhRecbto>2013-10-22T15:12:50</dhRecbto><nProt>150131000260573</nProt></infCanc></retCancCTe></retConsSitCTe></cteConsultaCTResult></soap:Body></soap:Envelope>'
   cXMLenv:='EMULACAO DE CACELAMENTO'
   aRET['infEvento']:='EMULACAO DE CACELAMENTO'
ENDIF

IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"         
   SHOWMSG_EDIT(aRET['XML'])
ENDIF   

// le a resposta
aRET:=::ctPegaRetornoSEFAZ(aRET['XML'])
IF VAL(aRET['cStat'])<>135 .AND. VAL(aRET['cStat'])<>631
   aRET['STATUS']:=.F.
   aRET['MSG']:=aRET['cStat']+'-'+aRET['xMotivo']
   RETURN(aRET)
ENDIF
   
IF VAL(aRET['cStat'])=631
   IF !::lCte_Emulador  
      aRET:=::ctConsultaProtocolo()
      IF !aRET['STATUS']
         RETURN(aRET)
      ENDIF
   ELSE
      aRET['infEvento']:='EMULACAO DE CACELAMENTO'
   ENDIF
ENDIF

aRET['XML']:='<?xml version="1.0" encoding="UTF-8" ?><retEventoCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+;
             ::cVersao_CTe+'">'+cXMLenv+aRET['infEvento']+'</retEventoCTe>'

aRET['STATUS']:=.T.

RETURN(aRET)

Method ctEventoCartaCorrecao() Class oCTe_SEFAZ
/*
   Evento da carta de correção
   Mauricio Cruz - 23/10/2013
*/
LOCAL mI:=0
LOCAL cXML:='', cXMLenv:=''
LOCAL aRET:=HASH()

aRET['MSG']:=''
aRET['STATUS']:=.F.

IF ::aCartaCorrecao=NIL .OR. LEN(::aCartaCorrecao)<=0
   aRET['MSG']:='Correções não informadas.'
ENDIF
FOR mI:=1 TO LEN(::aCartaCorrecao)
   IF EMPTY(::aCartaCorrecao[mI,1])
      aRET['MSG']:='Grupo alterado não informado.'
      EXIT
   ENDIF
   IF EMPTY(::aCartaCorrecao[mI,2])
      aRET['MSG']:='Campo alterado não informado.'
      EXIT
   ENDIF
   IF EMPTY(::aCartaCorrecao[mI,3])
      aRET['MSG']:='Valor alterado não informado.'
      EXIT
   ENDIF
NEXT

IF !EMPTY(aRET['MSG'])
   RETURN(aRET)
ENDIF

::tpEvento:='110110'
cXML:='<evCCeCTe>'
cXML+=   '<descEvento>Carta de Correcao</descEvento>'
FOR mI:=1 TO LEN(::aCartaCorrecao)
   cXML+='<infCorrecao>'
   cXML+=   '<grupoAlterado>'+::aCartaCorrecao[mI,1]+'</grupoAlterado>'
   cXML+=   '<campoAlterado>'+::aCartaCorrecao[mI,2]+'</campoAlterado>'
   cXML+=   '<valorAlterado>'+::aCartaCorrecao[mI,3]+'</valorAlterado>'
   IF ::aCartaCorrecao[mI,4]>0
      cXML+='<nroItemAlterado>'+ALLTRIM(STR(::aCartaCorrecao[mI,4]))+'</nroItemAlterado>'
   ENDIF
   cXML+='</infCorrecao>'
NEXT
cXML+=   '<xCondUso>A Carta de Correcao e disciplinada pelo Art. 58-B do CONVENIO/SINIEF 06/89: Fica permitida a utilizacao de carta de correcao, para regularizacao de erro ocorrido na emissao de documentos fiscais relativos a prestacao de servico de transporte, desde que o erro nao esteja relacionado com: I - as variaveis que determinam o valor do imposto tais como: base de calculo, aliquota, diferenca de preco, quantidade, valor da prestacao;II - a correcao de dados cadastrais que implique mudanca do emitente, tomador, remetente ou do destinatario;III - a data de emissao ou de saida.</xCondUso>'
cXML+='</evCCeCTe>'

// valida o XML de evento de carta de correcao
aRET:=::ctValidaXML(STRTRAN(cXML,'<evCCeCTe>','<evCCeCTe xmlns="http://www.portalfiscal.inf.br/cte">'))
IF !aRET['STATUS']
   RETURN(aRET)
ENDIF

IF !::lCte_Emulador  
   // executa o registro de evento
   aRET:=::ctEventos(cXML)
   IF !aRET['STATUS']
      RETURN(aRET)
   ENDIF
   cXMLenv:=aRET['XML_EVENTO']
ELSE
   aRET['XML']:='<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Header><cteCabecMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcaoEvento"><cUF>42</cUF><versaoDados>2.00</versaoDados></cteCabecMsg></soap:Header><soap:Body><cteRecepcaoEventoResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcaoEvento"><retEventoCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="2.00"><infEvento Id="ID342130000098680"><tpAmb>2</tpAmb><verAplic>RS20130820221405</verAplic><cOrgao>42</cOrgao><cStat>135</cStat><xMotivo>Evento registrado e vinculado a CT-e</xMotivo><chCTe>42131110694772000124570010000001041000001049</chCTe><tpEvento>110110</tpEvento><xEvento>Carta Correcao Registrada</xEvento><nSeqEvento>3</nSeqEvento><dhRegEvento>2013-11-20T16:30:58</dhRegEvento><nProt>342130000098680</nProt></infEvento></retEventoCTe></cteRecepcaoEventoResult></soap:Body></soap:Envelope>'
   cXMLenv:='EMULACAO DE CARTA DE CORRECAO'
   aRET['infEvento']:='EMULACAO DE CARTA DE CORRECAO'
ENDIF

IF GET_PARAMETRO('MOTRA_XML')  // SOMENTE PARA SYGECOM, DEMAIS PODEM REMOVER TODO O "IF"         
   SHOWMSG_EDIT(aRET['XML'])
ENDIF   

// le a resposta
aRET:=::ctPegaRetornoSEFAZ(aRET['XML'])
IF VAL(aRET['cStat'])<>135
   aRET['STATUS']:=.F.
   aRET['MSG']:=aRET['cStat']+'-'+aRET['xMotivo']
   RETURN(aRET)
ENDIF

aRET['XML']:='<?xml version="1.0" encoding="UTF-8" ?><retEventoCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="'+;
             ::cVersao_CTe+'">'+cXMLenv+aRET['infEvento']+'</retEventoCTe>'

aRET['STATUS']:=.T.
RETURN(aRET)


