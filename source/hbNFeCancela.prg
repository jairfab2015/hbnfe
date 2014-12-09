****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Cancela)                                                      *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

// Nota: Este cancelamento foi desativado, agora por evento

CLASS hbNFeCancela
   DATA   ohbNFe
   DATA   oSefaz
   DATA   cNFeFile
   DATA   cJustificativa
   DATA   cChaveNFe,nProt
   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeCancela
LOCAL cXMLDadosMsg, cXMLResp, ;
      aRetorno := hash(), oFuncoes := hbNFeFuncoes(), ;
      oAssina, aRetornoAss, cXMLFile, cXMLSai, nPos

   IF ::oSefaz == NIL
      ::oSefaz := ::ohbNFe:oSefaz
   ENDIF

   TRY
      cXMLFile := MEMOREAD( ::cNFeFile )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Erro ao abrir '+::cNFeFile
      RETURN(aRetorno)
   END

   IF !HB_ISNIL( ::cNFeFile )

      ::cChaveNFe := oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLFile, 'protNFe' ), 'chNFe' )  // Mauricio Cruz - 28/09/2011 alterado pq o nome do arquivo pode estar com o path ex.: c:\user\cruz\appdata\local\temp\.....xml    //::cChaveNFe := SUBS( ::cNFeFile ,1 ,44 )
      ::nProt     := oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLFile, 'protNFe' ), 'nProt' )
      IF EMPTY(::nProt)
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Arquivo '+::cNFeFile+' sem protocolo de envio'
         RETURN(aRetorno)
      ENDIF

   ENDIF

   cXMLDadosMsg := '<cancNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00">';
                     +'<infCanc Id="ID'+::cChaveNFe+'">';
                       +'<tpAmb>'+::tpAmb+'</tpAmb>';
                       +'<xServ>CANCELAR</xServ>';
                       +'<chNFe>'+::cChaveNFe+'</chNFe>';
                       +'<nProt>'+::nProt+'</nProt>';
                       +'<xJust>'+::cJustificativa+'</xJust>';
                     +'</infCanc>';
                  +'</cancNFe>'

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

   ::oSefaz:cXml := cXmlDadosMsg
   ::oSefaz:NFECancela()

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\NFe" + ::cChaveNFe + "-ped-can.xml", cXMLDadosMsg )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar protocolo de pedido '+::ohbNFe:pastaEnvRes+"\"+"NFe"+::cChaveNFe+"-ped-can.xml"
      RETURN(aRetorno)
   END

   cXMLResp := HB_ANSITOOEM( ::oSefaz:cXmlResposta )

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\NFe" + ::cChaveNFe + "-can.xml", cXMLResp )
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao retorno do protocolo '+::ohbNFe:pastaEnvRes+"\NFe"+::cChaveNFe+"-can.xml"
      aRetorno['tpAmb']      := oFuncoes:pegaTag(cXMLResp, "tpAmb")
      aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
      aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
      aRetorno['cUF']        := oFuncoes:pegaTag(cXMLResp, "cUF")
      aRetorno['chNFe']      := oFuncoes:pegaTag(cXMLResp, "chNFe")
      aRetorno['dhRecbto']   := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
      aRetorno['nProt']      := oFuncoes:pegaTag(cXMLResp, "nProt")
      aRetorno['digVal']     := oFuncoes:pegaTag(cXMLResp, "digVal")
      aRetorno['retCancNFe'] := cXMLResp
      RETURN(aRetorno)
   END
   TRY
      hb_MemoWrit( ::ohbNFe:pastaCancelamento + "\NFe" + ::cChaveNFe + "-can.xml", cXMLResp )
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao retorno do protocolo '+::ohbNFe:pastaCancelamento+"\NFe"+::cChaveNFe+"-can.xml"
      aRetorno['tpAmb']      := oFuncoes:pegaTag(cXMLResp, "tpAmb")
      aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
      aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
      aRetorno['cUF']        := oFuncoes:pegaTag(cXMLResp, "cUF")
      aRetorno['chNFe']      := oFuncoes:pegaTag(cXMLResp, "chNFe")
      aRetorno['dhRecbto']   := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
      aRetorno['nProt']      := oFuncoes:pegaTag(cXMLResp, "nProt")
      aRetorno['digVal']     := oFuncoes:pegaTag(cXMLResp, "digVal")
      aRetorno['retCancNFe'] := cXMLResp
      RETURN(aRetorno)
   END
   cXMLResp := oFuncoes:pegaTag(cXMLResp, "nfeCancelamentoNF2Result")
   aRetorno['OK']         := .T.
   aRetorno['tpAmb']      := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']        := oFuncoes:pegaTag(cXMLResp, "cUF")
   aRetorno['chNFe']      := oFuncoes:pegaTag(cXMLResp, "chNFe")
   aRetorno['dhRecbto']   := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
   aRetorno['nProt']      := oFuncoes:pegaTag(cXMLResp, "nProt")
   aRetorno['digVal']     := oFuncoes:pegaTag(cXMLResp, "digVal")
   aRetorno['retCancNFe'] := cXMLResp
   // processa protNFe no xml
   IF aRetorno['chNFe'] $ cXMLFile .AND. aRetorno['cStat'] == '101'
      cXMLSai := cXMLFile
      nPos := AT('/protNFe>',cXMLSai)+8
      IF nPos = 0
         nPos := AT('/NFe>',cXMLSai)+4
      ENDIF
      IF nPos = 0
         // problema xml
      ENDIF
      cXMLSai := SUBS(cXMLSai,1,nPos) + ;
                 aRetorno['retCancNFe']
      TRY
         hb_MemoWrit( ::ohbNFe:pastaNFe + "\" + ::cChaveNFe + '-nfe.xml', cXMLSai )
      CATCH
         aRetorno['MsgErro']  := 'Problema ao retorno do protocolo '+::ohbNFe:pastaNFe+"\"+::cChaveNFe+'-nfe.xml'
      END
   ENDIF

RETURN aRetorno
