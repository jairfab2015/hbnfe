****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Retorno Recepção) (RETORNO ENVIO)                             *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************


#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeRetornoRecepcao
   DATA ohbNFe
   DATA oSefaz
   DATA nRec

   METHOD execute()
   ENDCLASS

METHOD execute() CLASS hbNFeRetornoRecepcao
   LOCAL cXMLResp, nI, aRetorno := hash(), oFuncoes := hbNFeFuncoes(), cXMLResp2

   IF ::oSefaz == NIL
      ::oSefaz := ::ohbNFe:oSefaz
   ENDIF

   ::oSefaz:NfeConsultaRecibo( ::nRec )

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::nRec + "-ped-rec.xml", ::oSefaz:cXmlSoap )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido de situação do recibo '+::ohbNFe:pastaEnvRes+"\"+::nRec+"-ped-rec.xml"
      RETURN aRetorno
   END

   cXMLResp := HB_ANSITOOEM( ::oSefaz:cXmlRetorno )

   //cXMLResp := oFuncoes:pegaTag( cXMLResp , "nfeRetRecepcao2Result")
   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\debug-pro-rec.xml", cXMLResp )
   CATCH
   END

   cXMLResp := oFuncoes:pegaTag( cXMLResp , "retConsReciNFe") // Ajuste NFe2 - Mauricio Cruz - 31/10/2012


   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::nRec + "-pro-rec.xml", cXMLResp )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar protocolo do recibo '+::ohbNFe:pastaEnvRes+"\"+::nRec+"-pro-rec.xml"
      RETURN(aRetorno)
   END
   aRetorno['OK']       := .T.
   aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['nRec']     := oFuncoes:pegaTag(cXMLResp, "nRec")
   aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']      := oFuncoes:pegaTag(cXMLResp, "cUF")
   aRetorno['cMsg']     := oFuncoes:pegaTag(cXMLResp, "cMsg")
   aRetorno['xMsg']     := oFuncoes:pegaTag(cXMLResp, "xMsg")
   cXMLResp2 := oFuncoes:pegaTag(cXMLResp, "protNFe")

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\debug-aRetorno.xml", cXMLResp2 )
   CATCH
   END

   //aRetornoNF := hash()
   nI := 0
   DO WHILE .T.
      nI ++
      aRetorno['NF'+STRZERO(nI,2)+'_tpAmb']    := oFuncoes:pegaTag(cXMLResp2, "tpAmb")
      aRetorno['NF'+STRZERO(nI,2)+'_verAplic'] := oFuncoes:pegaTag(cXMLResp2, "verAplic")
      aRetorno['NF'+STRZERO(nI,2)+'_chNFe']    := oFuncoes:pegaTag(cXMLResp2, "chNFe")
      aRetorno['NF'+STRZERO(nI,2)+'_dhRecbto'] := oFuncoes:pegaTag(cXMLResp2, "dhRecbto")
      aRetorno['NF'+STRZERO(nI,2)+'_nProt']    := oFuncoes:pegaTag(cXMLResp2, "nProt")
      aRetorno['NF'+STRZERO(nI,2)+'_digVal']   := oFuncoes:pegaTag(cXMLResp2, "digVal")
      aRetorno['NF'+STRZERO(nI,2)+'_cStat']    := oFuncoes:pegaTag(cXMLResp2, "cStat") // <cStat>204</cStat>
      aRetorno['NF'+STRZERO(nI,2)+'_xMotivo']  := oFuncoes:pegaTag(cXMLResp2, "xMotivo")
      aRetorno['NF'+STRZERO(nI,2)+'_protNFe']  := "<protNFe "+cXMLResp2+"</protNFe>"
      EXIT
   ENDDO
   aRetorno['nNFs']     := nI
   RETURN aRetorno
