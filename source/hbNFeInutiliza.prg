****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Inutilização)                                                 *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeInutiliza
   DATA   ohbNFe
   DATA   oSefaz
   DATA   versaoDados
   DATA   ano
   DATA   CNPJ
   DATA   mod
   DATA   serie
   DATA   nNFIni
   DATA   nNFFin
   DATA   cJustificativa
   METHOD execute()
ENDCLASS

METHOD Execute() CLASS hbNFeInutiliza
   LOCAL cXMLResp, aRetorno := hash(), oFuncoes := hbNFeFuncoes(), FIDInutilizacao

   IF ::oSefaz == NIL
      ::oSefaz := ::ohbNFe:oSefaz
   ENDIF

   FIDInutilizacao := 'ID' + ::cUF + ::ano + ::CNPJ + ::mod + strZero(val(::serie), 3) + strZero(val(::nNFIni), 9) + strZero(val(::nNFFin), 9)

   ::oSefaz:NfeInutiliza( ::oSefaz:cUf, ::Ano, ::Cnpj, ::Mod, ::Serie, ::nNFIni, ::nNFFin )

   cXMLResp := HB_ANSITOOEM( ::oSefaz:cXmlResposta )

   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + FIDInutilizacao + "-inu.xml", cXMLResp )
   hb_MemoWrit( ::ohbNFe:pastaInutilizacao + "\" + FIDInutilizacao + "-inu.xml", cXMLResp )
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
   RETURN aRetorno
