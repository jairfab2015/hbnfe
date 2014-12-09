****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Consulta Cadastro)                                            *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeConsultaCadastro
   DATA   ohbNFe
   DATA   oSefaz
   DATA   cCNPJ
   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeConsultaCadastro
LOCAL cXMLResp, aRetorno := hash(), oFuncoes := hbNFeFuncoes(), cFileEnvRes

   IF ::oSefaz = Nil
      ::oSefaz := ::ohbNFe:oSefaz
   ENDIF

   ::oSefaz:NfeCadastro( ::oSefaz:cUF, ::cCnpj )

   cFileEnvRes := ::cCNPJ+oFuncoes:formatDate( DATE(), "YYMMDD")+SUBS(TIME(),1,2)+SUBS(TIME(),4,2)+SUBS(TIME(),7,2)
   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + cFileEnvRes + "-ped-cad.xml", ::oSefaz:cXmlSoap )
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido do cadastro '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-ped-cad.xml"
      RETURN(aRetorno)
   END

   cXMLResp := HB_ANSITOOEM( ::oSefaz:cXmlResposta )
   cXMLResp := oFuncoes:pegaTag( cXMLResp , 'retConsCad' )
   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + cFileEnvRes + "-cad.xml", cXMLResp )
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao gravar retorno do cadastro '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-cad.xml"
      aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
      aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
      aRetorno['IE']         := oFuncoes:pegaTag(cXMLResp, "IE")
      aRetorno['CNPJ']       := oFuncoes:pegaTag(cXMLResp, "CNPJ")
      aRetorno['cSit']       := oFuncoes:pegaTag(cXMLResp, "cSit")
      aRetorno['indCredNFe'] := oFuncoes:pegaTag(cXMLResp, "indCredNFe")
      aRetorno['indCredCTe'] := oFuncoes:pegaTag(cXMLResp, "indCredCTe")
      aRetorno['xNome']      := oFuncoes:pegaTag(cXMLResp, "xNome")
      aRetorno['xRegApur']   := oFuncoes:pegaTag(cXMLResp, "xRegApur")
      aRetorno['CNAE']       := oFuncoes:pegaTag(cXMLResp, "CNAE")
      aRetorno['dIniAtiv']   := oFuncoes:pegaTag(cXMLResp, "dIniAtiv")
      aRetorno['dUltSit']    := oFuncoes:pegaTag(cXMLResp, "dUltSit")
      aRetorno['xLgr']       := oFuncoes:pegaTag(cXMLResp, "xLgr")
      aRetorno['nro']        := oFuncoes:pegaTag(cXMLResp, "nro")
      aRetorno['xBairro']    := oFuncoes:pegaTag(cXMLResp, "xBairro")
      aRetorno['cMun']       := oFuncoes:pegaTag(cXMLResp, "cMun")
      aRetorno['xMun']       := oFuncoes:pegaTag(cXMLResp, "xMun")
      aRetorno['CEP']        := oFuncoes:pegaTag(cXMLResp, "CEP")
      RETURN(aRetorno)
   END
   aRetorno['OK']         := .T.
   aRetorno['MsgErro']    := ""
   aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['IE']         := oFuncoes:pegaTag(cXMLResp, "IE")
   aRetorno['CNPJ']       := oFuncoes:pegaTag(cXMLResp, "CNPJ")
   aRetorno['cSit']       := oFuncoes:pegaTag(cXMLResp, "cSit")
   aRetorno['indCredNFe'] := oFuncoes:pegaTag(cXMLResp, "indCredNFe")
   aRetorno['indCredCTe'] := oFuncoes:pegaTag(cXMLResp, "indCredCTe")
   aRetorno['xNome']      := oFuncoes:pegaTag(cXMLResp, "xNome")
   aRetorno['xRegApur']   := oFuncoes:pegaTag(cXMLResp, "xRegApur")
   aRetorno['CNAE']       := oFuncoes:pegaTag(cXMLResp, "CNAE")
   aRetorno['dIniAtiv']   := oFuncoes:pegaTag(cXMLResp, "dIniAtiv")
   aRetorno['dUltSit']    := oFuncoes:pegaTag(cXMLResp, "dUltSit")
   aRetorno['xLgr']       := oFuncoes:pegaTag(cXMLResp, "xLgr")
   aRetorno['nro']        := oFuncoes:pegaTag(cXMLResp, "nro")
   aRetorno['xBairro']    := oFuncoes:pegaTag(cXMLResp, "xBairro")
   aRetorno['cMun']       := oFuncoes:pegaTag(cXMLResp, "cMun")
   aRetorno['xMun']       := oFuncoes:pegaTag(cXMLResp, "xMun")
   aRetorno['CEP']        := oFuncoes:pegaTag(cXMLResp, "CEP")

   RETURN aRetorno
