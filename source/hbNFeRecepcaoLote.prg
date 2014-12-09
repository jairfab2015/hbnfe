****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Recepção Lote) ENVIO                                          *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeRecepcaoLote
   DATA ohbNFe
   DATA oSefaz
   DATA idLote
   DATA aXMLDados
   //DATA lAguardaRetorno
   //DATA nTempoAguardaRetorno             //  Anderson Camilo  10/11/2011
   //DATA nVezesTentaRetorno               //  Anderson Camilo  10/11/2011

   METHOD Execute()
ENDCLASS

METHOD Execute() CLASS hbNFeRecepcaoLote
   LOCAL cXMLDadosMsg, cXMLResp, nI, aRetorno := hash(), oFuncoes := hbNFeFuncoes(), ;
      cXMLSai, nI2, aRetornoRet, oRetornoNFe

   IF ::oSefaz == NIL
      ::oSefaz := ::ohbNFe:oSefaz
   ENDIF
   //IF ::nTempoAguardaRetorno = Nil         // Anderson Camilo 10/11/2011
   //   ::nTempoAguardaRetorno := 15
   //ENDIF

   //IF ::nVezesTentaRetorno = Nil            // Anderson Camilo 10/11/2011
   //   ::nVezesTentaRetorno := 1
   //ENDIF

   cXMLDadosMsg := ""
   FOR nI = 1 TO LEN( ::aXMLDados )
      TRY
         cXMLDadosMsg += MEMOREAD( ::aXMLDados[nI] )
      CATCH
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Arquivo não encontrado '+::aXMLDados[nI]
         RETURN(aRetorno)
      END
   NEXT

   ::oSefaz:cXml         := cXmlDadosMsg
   ::oSefaz:NfeLoteEnvia()

   cXMLResp := HB_ANSITOOEM( ::oSefaz:cXmlResposta )

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\debug-rec.xml", ::cXMLResp )
   CATCH
   END
   //cXMLResp := oFuncoes:pegaTag(cXMLResp, "nfeRecepcaoLote2Result")
   cXMLResp := oFuncoes:pegaTag(cXMLResp, "retEnviNFe")   // ajuste para NFe2 - Mauricio Cruz - 31/10/2012

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::idLote + "-rec.xml", cXMLResp )
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
      // Como tem EXIT antes do NEXT, este FOR/NEXT não serve pra nada
   	  //FOR nVezesRet = 1 to ::nVezesTentaRetorno              // Anderson Camilo  10/11/2011
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
                       hb_MemoWrit( ::aXMLDados[nI2], cXMLSai )
                    ENDIF
                  CATCH
                    aRetorno['NF'+STRZERO(nI,2)+'_MsgErro'] := 'Problema ao gravar protocolo no arquivo '+::aXMLDados[nI2]
                  END
               NEXT
            NEXT
         ENDIF

         //EXIT
  	   //NEXT nVezesRet

   ENDIF

RETURN aRetorno
