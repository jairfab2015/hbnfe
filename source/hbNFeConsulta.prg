****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Consulta Protocolo)                                           *
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

CLASS hbNFeConsulta
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA tpAmb
   DATA cNFeFile  //pode ser um xml
   DATA cChaveNFe //pode ser uma chave

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeConsulta
LOCAL cCN, cUrlWS, cXML, oServerWS, oDOMDoc, cXMLResp, cMsgErro, aRetorno := hash(),;
      oFuncoes := hbNFeFuncoes(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2',;
      oError, nI2, xXMLSai, cProtNFe, cXMLSai, cXMLFile, cXMLDadosMsg, oCurl, aHeader, retHTTP

   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := '2.01'
   ENDIF

   IF ::tpAmb = Nil
      ::tpAmb := ::ohbNFe:tpAmb
   ENDIF

   IF !EMPTY( ::cNFeFile )
      IF !FILE( ::cNFeFile )
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Arquivo não encontrado '+::cNFeFile
         RETURN(aRetorno)
      ENDIF
      TRY
         cXMLFile := MEMOREAD( ::cNFeFile )
      CATCH
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Erro ao abrir '+::cNFeFile
         RETURN(aRetorno)
      END
      ::cChaveNFe := SUBS( ::cNFeFile ,AT('-nfe',::cNFeFile)-44 ,44 )
      IF 'retCancNFe' $ cXMLFile
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'NFe '+::cNFeFile+' cancelada'
         RETURN(aRetorno)
      ENDIF
   ENDIF

   cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)

   cUrlWS := ::ohbNFe:getURLWS(_CONSULTAPROTOCOLO)
   IF cUrlWS = nil
      cMsgErro := "Serviço não mapeado"+ HB_OSNEWLINE()+;
                  "Serviço solicitado : CONSULTA PROTOCOLO"
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := cMsgErro
      RETURN(aRetorno)
   ENDIF
   cXMLDadosMsg := '<consSitNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.01">' +;
                      '<tpAmb>'+::tpAmb+'</tpAmb>' +;
                      '<xServ>CONSULTAR</xServ>' +;
                      '<chNFe>'+::cChaveNFe+'</chNFe>' +;
                   '</consSitNFe>'

   cXML := '<?xml version="1.0" encoding="utf-8"?>'
   cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
   cXML := cXML +   '<soap12:Header>'
   cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2">'
   cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
   cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
   cXML := cXML +     '</nfeCabecMsg>'
   cXML := cXML +   '</soap12:Header>'
   cXML := cXML +   '<soap12:Body>'
   cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2">'
   cXML := cXML +        cXMLDadosMsg
   cXML := cXML +     '</nfeDadosMsg>'
   cXML := cXML +   '</soap12:Body>'
   cXML := cXML +'</soap12:Envelope>'
   TRY
      MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-ped-sit.xml",cXMLDadosMsg,.F.)
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido de consulta '+::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-ped-sit.xml"
      RETURN(aRetorno)
   END

  IF ::ohbNFe:nSOAP = HBNFE_CURL
     aHeader = { 'Content-Type: application/soap+xml;charset=utf-8;action="'+cSoapAction+'"',;
                 'SOAPAction: "NfeConsulta2"',;
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
     oServerWS:setRequestHeader("SOAPAction", cSOAPAction)
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
        cMsgErro := "Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_OsNewLine() +;
                    " Linha: " + STR(oDOMDoc:parseError:line)+HB_OsNewLine() +;
                    " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_OsNewLine() +;
                    " Causa do erro: " + oDOMDoc:parseError:reason+HB_OsNewLine() +;
                    "code: "+STR(oDOMDoc:parseError:errorCode)
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := cMsgErro
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
       aRetorno['MsgErro']  := cMsgErro
       RETURN(aRetorno)
     END
     DO WHILE oServerWS:readyState <> 4
        millisec(500)
     ENDDO
     cXMLResp := HB_ANSITOOEM(oServerWS:responseText)
   ENDIF

   cXMLResp := oFuncoes:pegaTag( cXMLResp, 'retConsSitNFe' )

   TRY
      MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-sit.xml",cXMLResp,.F.)
   CATCH
     aRetorno['OK']       := .F.
     aRetorno['MsgErro']  := 'Problema ao gravar retorno da consulta '+::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-sit.xml"
     RETURN(aRetorno)
   END
   aRetorno['OK']           := .T.
   aRetorno['MsgErro']      := ""
   aRetorno['tpAmb']        := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic']     := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['dhRecbto']     := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
   aRetorno['nProt']        := oFuncoes:pegaTag(cXMLResp, "nProt")
   aRetorno['digVal']       := oFuncoes:pegaTag(cXMLResp, "digVal")
   aRetorno['cStat']        := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']      := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']          := oFuncoes:pegaTag(cXMLResp, "uUF")
   aRetorno['chNFe']        := oFuncoes:pegaTag(cXMLResp, "chNFe")
   aRetorno['protNFe']      := oFuncoes:pegaTag(cXMLResp, "protNFe")
   // acresentado as duas tag abaixo: Leonardo Machado - 28/06/2012
   aRetorno['retCancNFe']   := oFuncoes:pegaTag(cXMLResp, "retCancNFe")
   aRetorno['procEventoNFe']:= oFuncoes:pegaTag(cXMLResp, "procEventoNFe")

   // processa protNFe no xml
   IF !EMPTY( ::cNFeFile )
      IF aRetorno['cStat'] == '100' .OR.;  // autorizado o uso
         aRetorno['cStat'] == '110'        // denegado o uso
         cXMLSai := cXMLFile

         //  nao estava trazendo o inicio da tag e o fim da tag, achei mais seguro colocar aqui do que mexer na classe pegaTag.
         // Mauricio Cruz - 03/10/2011
         IF !('<protNFe' $ aRetorno['protNFe'] )
            aRetorno['protNFe']:='<protNFe '+aRetorno['protNFe']+'</protNFe>'
         ENDIF

         // ADD tag "nfeProc" -> Mauricio Cruz - 03/10/2011
         cXMLSai := '<?xml version="1.0" encoding="UTF-8" ?><nfeProc versao="2.01" xmlns="http://www.portalfiscal.inf.br/nfe">'+;
                    SUBS(cXMLSai,1,AT('/NFe>',cXMLSai)+4) + ;
                    aRetorno['protNFe'] + '</nfeProc>'

/*
         cXMLSai := '<?xml version="1.0" encoding="UTF-8" ?>';
                 + '<nfeProc versao="2.00" xmlns="http://www.portalfiscal.inf.br/nfe">';
                 + '<NFe xmlns' + hbNFe_PegaDadosXML('NFe xmlns', cXMLSai, 'NFe' ) + '</NFe>';
                 + aRetorno['protNFe'];
                 + '</nfeProc>'
*/                 
         TRY
            MEMOWRIT( ::cNFeFile, cXMLSai, .F. )
         CATCH
            aRetorno['MsgErro']  := 'Erro ao gravar protNFe no arquivo '+::cNFeFile
            RETURN(aRetorno)
         END
      ENDIF
   ENDIF

   oDOMDoc:=Nil
   oServerWS:=Nil
RETURN(aRetorno)
