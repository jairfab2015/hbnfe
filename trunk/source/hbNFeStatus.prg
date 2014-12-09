****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Status de Serviço)                                            *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeStatus
   DATA   ohbNFe
   DATA   oSefaz
   METHOD execute()
   ENDCLASS

METHOD execute() CLASS hbNFeStatus
   LOCAL aRetorno := hash(), oFuncoes := hbNFeFuncoes(), cFileEnvRes, cXMLResp
   IF ::oSefaz == NIL
      ::oSefaz := ::ohbNFe:oSefaz
   ENDIF

   ::oSefaz:NfeStatus()

   cFileEnvRes := oFuncoes:formatDate( DATE(), "YYMMDD")+SUBS(TIME(),1,2)+SUBS(TIME(),4,2)+SUBS(TIME(),7,2)
   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + cFileEnvRes + "-ped-sta.xml", ::oSefaz:cXmlSoap )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido de status '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-ped-sta.xml"
      RETURN aRetorno
   END

   cXmlResp := oFuncoes:pegaTag( ::oSefaz:cXmlRetorno, 'retConsStatServ' )

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + cFileEnvRes + "-sta.xml", ::oSefaz:cXmlRetorno )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar retorno de status '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-sta.xml"
      RETURN(aRetorno)
   END
   aRetorno['OK']       := .T.
   aRetorno['MsgErro']  := ""
   aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']      := oFuncoes:pegaTag(cXMLResp, "cUF")
   aRetorno['dhRecbto'] := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
   aRetorno['tMed']     := oFuncoes:pegaTag(cXMLResp, "tMed")

   RETURN aRetorno
