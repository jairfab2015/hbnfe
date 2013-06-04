****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Inutilização)                                                 *
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

CLASS hbNFeInutiliza
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA tpAmb
   DATA cUF
   DATA ano
   DATA CNPJ
   DATA mod
   DATA serie
   DATA nNFIni
   DATA nNFFin
   DATA cJustificativa

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeInutiliza
LOCAL cCN, cUrlWS, cXML, cXMLDadosMsg, oServerWS, oDOMDoc, cXMLResp, cMsgErro,;
      aRetorno := hash(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/NfeInutilizacao2',;
      oFuncoes := hbNFeFuncoes(), FIDInutilizacao, oAssina, oError, aRetornoAss, oCurl, aHeader, retHTTP

   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := ::ohbNFe:versaoDados
   ENDIF
   IF ::tpAmb = Nil
      ::tpAmb := ::ohbNFe:tpAmb
   ENDIF

   FIDInutilizacao := 'ID' + ::cUF + ::ano + ::CNPJ + ::mod + strZero(val(::serie), 3) + strZero(val(::nNFIni), 9) + strZero(val(::nNFFin), 9)
   cXMLDadosMsg := '<inutNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00">';
                     +'<infInut Id="'+FIDInutilizacao+'">';
                       +'<tpAmb>'+::tpAmb+'</tpAmb>';
                       +'<xServ>INUTILIZAR</xServ>';
                       +'<cUF>'+::cUF+'</cUF>';
                       +'<ano>'+::ano+'</ano>';
                       +'<CNPJ>'+::CNPJ+'</CNPJ>';
                       +'<mod>'+::mod+'</mod>';
                       +'<serie>'+::serie+'</serie>';
                       +'<nNFIni>'+::nNFIni+'</nNFIni>';
                       +'<nNFFin>'+::nNFFin+'</nNFFin>';
                       +'<xJust>'+::cJustificativa+'</xJust>';
                     +'</infInut>';
                  +'</inutNFe>'

   oAssina := hbNFeAssina()
   oAssina:ohbNFe := ::ohbNfe // Objeto hbNFe
   oAssina:cXMLFile := cXMLDadosMsg
   oAssina:lMemFile := .T.
   aRetornoAss := oAssina:execute()
   oAssina := Nil
   IF aRetornoAss['OK'] == .F.
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := aRetornoAss['MsgErro']
      RETURN(aRetorno)
   ENDIF
   cXMLDadosMsg := aRetornoAss['XMLAssinado']

   cXML := '<?xml version="1.0" encoding="utf-8"?>'
   cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
   cXML := cXML +   '<soap12:Header>'
   cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeInutilizacao2">'
   cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
   cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
   cXML := cXML +     '</nfeCabecMsg>'
   cXML := cXML +   '</soap12:Header>'
   cXML := cXML +   '<soap12:Body>'
   cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeInutilizacao2">'
   cXML := cXML + cXMLDadosMsg
   cXML := cXML +     '</nfeDadosMsg>'
   cXML := cXML +   '</soap12:Body>'
   cXML := cXML +'</soap12:Envelope>'
   TRY
      MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+FIDInutilizacao+"-ped-inu.xml",cXMLDadosMsg,.F.)
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido de inutilização '+::ohbNFe:pastaEnvRes+"\"+FIDInutilizacao+"-ped-inu.xml"
      RETURN(aRetorno)
   END
   cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)

   cUrlWS := ::ohbNFe:getURLWS(_INUTILIZACAO)
   
   
  IF ::ohbNFe:nSOAP = HBNFE_CURL
     aHeader = { 'Content-Type: application/soap+xml;charset=utf-8;action="'+cSoapAction+'"',;
                 'SOAPAction: "NfeInutilizacao2"',;
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
        oServerWS := xhb_CreateObject( _MSXML2_ServerXMLHTTP )
     #else
        oServerWS := win_oleCreateObject( _MSXML2_ServerXMLHTTP )
     #endif
     oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
     oServerWS:open("POST", cUrlWS, .F.)
     oServerWS:setRequestHeader("SOAPAction", cSOAPAction )
     oServerWS:setRequestHeader("Content-Type", "application/soap+xml; charset=utf-8")
  
     #ifdef __XHARBOUR__
        oDOMDoc := xhb_CreateObject( _MSXML2_DOMDocument )
     #else
        oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )
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
       cMsgErro := "Falha "+HB_OsNewLine()+ ;
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
   MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+FIDInutilizacao+"-inu.xml",cXMLResp,.F.)
   MEMOWRIT(::ohbNFe:pastaInutilizacao+"\"+FIDInutilizacao+"-inu.xml",cXMLResp,.F.)
   cXMLResp := oFuncoes:pegaTag(cXMLResp, "nfeInutilizacaoNF2Result")
   aRetorno['OK']       := .T.
   aRetorno['ID']       := oFuncoes:pegaTag(cXMLResp, "ID")
   aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']      := oFuncoes:pegaTag(cXMLResp, "cUF")
   aRetorno['ano']      := oFuncoes:pegaTag(cXMLResp, "ano")
   aRetorno['CNPJ']     := oFuncoes:pegaTag(cXMLResp, "CNPJ")
   aRetorno['mod']      := oFuncoes:pegaTag(cXMLResp, "mod")
   aRetorno['serie']    := oFuncoes:pegaTag(cXMLResp, "serie")
   aRetorno['nNFIni']   := oFuncoes:pegaTag(cXMLResp, "nNFIni")
   aRetorno['nNFFin']   := oFuncoes:pegaTag(cXMLResp, "nNFFin")
   aRetorno['dhRecbto'] := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
   aRetorno['nProt']    := oFuncoes:pegaTag(cXMLResp, "nProt")

   oDOMDoc:=Nil
   oServerWS:=Nil
RETURN(aRetorno)
