****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Recepção Lote) ENVIO                                          *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************
#include "common.ch"
#include "hbclass.ch"
#ifndef __XHARBOUR__
   #include "hbwin.ch"
   #include "harupdf.ch"
   #include "hbzebra.ch"
   #include "hbcompat.ch"
#endif
#include "hbnfe.ch"

CLASS hbNFeRecepcaoLote
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA idLote
   DATA aXMLDados
   DATA lAguardaRetorno
   DATA nTempoAguardaRetorno             //  Anderson Camilo  10/11/2011
   DATA nVezesTentaRetorno               //  Anderson Camilo  10/11/2011

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeRecepcaoLote
LOCAL cCN, cUrlWS, cXML, cXMLDadosMsg, oServerWS, oDOMDoc, cXMLResp, cMsgErro, nI,;
      aRetorno := hash(), oFuncoes := hbNFeFuncoes(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/NfeRecepcao2',;
      cXMLSai, nI2, aRetornoRet, oRetornoNFe, oError, oCurl, aHeader, retHTTP, nVezesRet

   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := ::ohbNFe:versaoDados
   ENDIF

   IF ::nTempoAguardaRetorno = Nil         // Anderson Camilo 10/11/2011
      ::nTempoAguardaRetorno := 15
   ENDIF
   
   IF ::nVezesTentaRetorno = Nil            // Anderson Camilo 10/11/2011
      ::nVezesTentaRetorno := 1
   ENDIF

   IF VALTYPE(aXMLDados)#'A'
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'O Caminho do Arquivo está inválido, favor revisar'
      RETURN(aRetorno)
   ENDIF

   cXMLDadosMsg := '<enviNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00"><idLote>'+::idLote+'</idLote>'
   FOR nI=1 TO LEN(::aXMLDados)
      TRY
         cXMLDadosMsg += MEMOREAD( ::aXMLDados[nI] )
      CATCH
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Arquivo não encontrado '+::aXMLDados[nI]
         RETURN(aRetorno)
      END
   NEXT
   cXMLDadosMsg += '</enviNFe>'

   cXML := '<?xml version="1.0" encoding="utf-8"?>'
   cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
   cXML := cXML +   '<soap12:Header>'
   cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeRecepcao2">'
   cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
   cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
   cXML := cXML +     '</nfeCabecMsg>'
   cXML := cXML +   '</soap12:Header>'
   cXML := cXML +   '<soap12:Body>'
   cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeRecepcao2">'
   cXML := cXML + cXMLDadosMsg
   cXML := cXML +     '</nfeDadosMsg>'
   cXML := cXML +   '</soap12:Body>'
   cXML := cXML +'</soap12:Envelope>'

   TRY
      MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+::idLote+"-env-lot.xml",cXMLDadosMsg,.F.)
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar envio do lote '+::ohbNFe:pastaEnvRes+"\"+::idLote+"-env-lot.xml"
      RETURN(aRetorno)
   END

   cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)

   cUrlWS := ::ohbNFe:getURLWS(_RECEPCAO)
  IF ::ohbNFe:nSOAP = HBNFE_CURL
     aHeader = { 'Content-Type: application/soap+xml;charset=utf-8;action="'+cSoapAction+'"',;
                 'SOAPAction: "NfeRecepcao2"',;
                 'Content-length: '+ALLTRIM(STR(len(cXML))) }

     #ifndef __XHARBOUR__
       curl_global_init()
       oCurl = curl_easy_init()

       curl_easy_setopt(oCurl, HB_CURLOPT_URL, cUrlWS)
       curl_easy_setopt(oCurl, HB_CURLOPT_PORT , 443)
       curl_easy_setopt(oCurl, HB_CURLOPT_VERBOSE, .F.) // 1
       curl_easy_setopt(oCurl, HB_CURLOPT_HEADER, 1) //retorna o cabeÃ§alho de resposta
       curl_easy_setopt(oCurl, HB_CURLOPT_SSLVERSION, 3)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSL_VERIFYHOST, 0)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSL_VERIFYPEER, 0)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSLCERT, ::ohbNFe:cCertFilePub)
       curl_easy_setopt(oCurl, HB_CURLOPT_KEYPASSWD, ::ohbNFe:cCertPass)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSLKEY, ::ohbNFe:cCertFilePriv)
       curl_easy_setopt(oCurl, HB_CURLOPT_POST, 1)
       curl_easy_setopt(oCurl, HB_CURLOPT_POSTFIELDS, cXML)
       curl_easy_setopt(oCurl, HB_CURLOPT_WRITEFUNCTION, 1)
       curl_easy_setopt(oCurl, HB_CURLOPT_DL_BUFF_SETUP )
       curl_easy_setopt(oCurl, HB_CURLOPT_HTTPHEADER, aHeader )
       curl_easy_perform(oCurl)
       retHTTP := curl_easy_getinfo(oCurl,HB_CURLINFO_RESPONSE_CODE) //informaÃ§Ãµes da conexÃ£o

       cXMLResp := ''
       IF retHTTP = 200 // OK
          curl_easy_setopt( ocurl, HB_CURLOPT_DL_BUFF_GET, @cXMLResp )
          cXMLResp := SUBS(cXMLResp,AT('<?xml',cXMLResp))
       ENDIF

       curl_easy_cleanup(oCurl)
       curl_global_cleanup()
     #endif
  ELSE // MSXML
     #ifdef __XHARBOUR__
        oServerWS := xhb_CreateObject( "MSXML2.ServerXMLHTTP.5.0" )
     #else
        oServerWS := win_oleCreateObject( "MSXML2.ServerXMLHTTP.5.0")
     #endif
     oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
     oServerWS:open("POST", cUrlWS, .F.)
     oServerWS:setRequestHeader("SOAPAction", cSOAPAction )
     oServerWS:setRequestHeader("Content-Type", "application/soap+xml; charset=utf-8")
  
     #ifdef __XHARBOUR__
        oDOMDoc := xhb_CreateObject( "MSXML2.DOMDocument.5.0" )
     #else
        oDOMDoc := win_oleCreateObject( "MSXML2.DOMDocument.5.0")
     #endif
     oDOMDoc:async = .F.
     oDOMDoc:validateOnParse  = .T.
     oDOMDoc:resolveExternals := .F.
     oDOMDoc:preserveWhiteSpace = .T.
     oDOMDoc:LoadXML(cXML)
     IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
        cMsgErro := "Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_OsNewLine() + ;
                    " Linha: " + STR(oDOMDoc:parseError:line)+HB_OsNewLine() + ;
                    " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_OsNewLine() + ;
                    " Causa do erro: " + oDOMDoc:parseError:reason+HB_OsNewLine() + ;
                    " Code: "+STR(oDOMDoc:parseError:errorCode)
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := cMSgErro
        RETURN(aRetorno)
     ENDIF
     TRY
        oServerWS:send(oDOMDoc:xml)
     CATCH oError
       cMsgErro := "Falha: "+'Não foi possível conectar-se ao servidor do SEFAZ, Servidor inativou ou inoperante.' +HB_OsNewLine()+ ;
               	 "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_OsNewLine()+ ;
                	 "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_OsNewLine()+ ;
               	 "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_OsNewLine()+ ;
               	 "SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_OsNewLine()+ ;
              	 "Mensangem: " + oError:Description
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := cMSgErro
        RETURN(aRetorno)
     END
     DO WHILE oServerWS:readyState <> 4
        millisec(500)
     ENDDO
     cXMLResp := HB_ANSITOOEM(oServerWS:responseText)
   ENDIF
   //cXMLResp := oFuncoes:pegaTag(cXMLResp, "nfeRecepcaoLote2Result")
   cXMLResp := oFuncoes:pegaTag(cXMLResp, "retEnviNFe")   // ajuste para NFe2 - Mauricio Cruz - 31/10/2012

   TRY
      MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+::idLote+"-rec.xml",cXMLResp,.F.)
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao gravar recibo do lote '+::ohbNFe:pastaEnvRes+"\"+::idLote+"-rec.xml"
      aRetorno['versao']   := oFuncoes:pegaTag(cXMLResp, "versao")
      aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
      aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
      aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
      aRetorno['cUF']      := oFuncoes:pegaTag(cXMLResp, "cUF")
      aRetorno['dhRecbto'] := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
      aRetorno['nRec']     := oFuncoes:pegaTag(cXMLResp, "nRec")
      aRetorno['tMed']     := oFuncoes:pegaTag(cXMLResp, "tMed")
      RETURN(aRetorno)
   END
   aRetorno['OK']       := .T.
   aRetorno['versao']   := oFuncoes:pegaTag(cXMLResp, "versao")
   aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']      := oFuncoes:pegaTag(cXMLResp, "cUF")
   aRetorno['dhRecbto'] := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
   aRetorno['nRec']     := oFuncoes:pegaTag(cXMLResp, "nRec")
   aRetorno['tMed']     := oFuncoes:pegaTag(cXMLResp, "tMed")

   IF ::lAguardaRetorno

      //Aguarda o tempo determinado no parametro nTempoAguardaRetorno, o default é 15

	  FOR nVezesRet = 1 to ::nVezesTentaRetorno              // Anderson Camilo  10/11/2011
         FOR nI = 1 TO ::nTempoAguardaRetorno              // Anderson Camilo  10/11/2011
            millisec(1000)
         NEXT

	      oRetornoNFe := hbNFeRetornoRecepcao()
	      oRetornoNFe:ohbNFe := ::ohbNfe // Objeto hbNFe
	      oRetornoNFe:nRec := aRetorno['nRec']
	      aRetornoRet := oRetornoNFe:execute()
	      oRetornoNFe := Nil
	
	      IF aRetornoRet['OK'] == .F.
	         aRetorno['ret_OK'] := .F.
	         aRetorno['ret_MsgErro'] := aRetornoRet['MsgErro']
	      ELSE
		      IF nVezesRet < ::nVezesTentaRetorno             // Anderson Camilo  10/11/2011
			      IF aRetornoRet['cStat'] = '105'
			         LOOP
               ENDIF
            ENDIF		   
	         aRetorno['ret_tpAmb']    := aRetornoRet['tpAmb']
	         aRetorno['ret_verAplic'] := aRetornoRet['verAplic']
	         aRetorno['ret_nRec']     := aRetornoRet['nRec']
	         aRetorno['ret_cStat']    := aRetornoRet['cStat']
	         aRetorno['ret_xMotivo']  := aRetornoRet['xMotivo']
	         aRetorno['ret_cUF']      := aRetornoRet['cUF']
	         aRetorno['ret_cMsg']     := aRetornoRet['cMsg']
	         aRetorno['ret_xMsg']     := aRetornoRet['xMsg']
	         aRetorno['nNFs']         := aRetornoRet['nNFs']
	         FOR nI = 1 TO aRetornoRet['nNFs']
	            aRetorno['NF'+STRZERO(nI,2)+'_tpAmb']    := aRetornoRet['NF'+STRZERO(nI,2)+'_tpAmb']
	            aRetorno['NF'+STRZERO(nI,2)+'_verAplic'] := aRetornoRet['NF'+STRZERO(nI,2)+'_verAplic']
	            aRetorno['NF'+STRZERO(nI,2)+'_chNFe']    := aRetornoRet['NF'+STRZERO(nI,2)+'_chNFe']
	            aRetorno['NF'+STRZERO(nI,2)+'_dhRecbto'] := aRetornoRet['NF'+STRZERO(nI,2)+'_dhRecbto']
	            aRetorno['NF'+STRZERO(nI,2)+'_nProt']    := aRetornoRet['NF'+STRZERO(nI,2)+'_nProt']
	            aRetorno['NF'+STRZERO(nI,2)+'_digVal']   := aRetornoRet['NF'+STRZERO(nI,2)+'_digVal']
	            aRetorno['NF'+STRZERO(nI,2)+'_cStat']    := aRetornoRet['NF'+STRZERO(nI,2)+'_cStat']
	            aRetorno['NF'+STRZERO(nI,2)+'_xMotivo']  := aRetornoRet['NF'+STRZERO(nI,2)+'_xMotivo']
	            aRetorno['NF'+STRZERO(nI,2)+'_protNFe']  := aRetornoRet['NF'+STRZERO(nI,2)+'_protNFe']
	            // processa protNFe no xml
	            FOR nI2 = 1 TO LEN( ::aXMLDados )
	               TRY
	                 IF aRetorno['NF'+STRZERO(nI,2)+'_chNFe'] $ MEMOREAD( ::aXMLDados[nI2] ) .AND. aRetorno['NF'+STRZERO(nI,2)+'_cStat'] == '100'
	                    cXMLSai := MEMOREAD( ::aXMLDados[nI2] )
	
	                    // ADD tag "nfeProc" -> Mauricio Cruz - 30/09/2011
	                    cXMLSai := '<?xml version="1.0" encoding="UTF-8" ?><nfeProc versao="2.00" xmlns="http://www.portalfiscal.inf.br/nfe">'+;
	                                SUBS(cXMLSai,1,AT('/NFe>',cXMLSai)+4) + ;
	                               aRetorno['NF'+STRZERO(nI,2)+'_protNFe'] + '</nfeProc>'
	/*
	                    cXMLSai := '<?xml version="1.0" encoding="UTF-8" ?>';
	                            + '<nfeProc versao="2.00" xmlns="http://www.portalfiscal.inf.br/nfe">';
	                            + '<NFe xmlns' + hbNFe_PegaDadosXML('NFe xmlns', cXMLSai, 'NFe' ) + '</NFe>';
	                            + aRetorno['NF'+STRZERO(nI,2)+'_protNFe'];
	                            + '</nfeProc>'
	*/
	                    MEMOWRIT(::aXMLDados[nI2], cXMLSai, .F. )
	                 ENDIF
	               CATCH
	                 aRetorno['NF'+STRZERO(nI,2)+'_MsgErro'] := 'Problema ao gravar protocolo no arquivo '+::aXMLDados[nI2]
	               END
	            NEXT
	         NEXT
  			ENDIF
    		EXIT
  		NEXT nVezesRet
   ENDIF

   oDOMDoc:=Nil
   oServerWS:=Nil
RETURN(aRetorno)
