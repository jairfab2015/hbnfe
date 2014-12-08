****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Consulta Protocolo)                                           *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeConsulta
   DATA   ohbNFe
   DATA   cUFWS
   DATA   versaoDados
   DATA   tpAmb
   DATA   cNFeFile  //pode ser um xml
   DATA   cChaveNFe //pode ser uma chave
   METHOD Execute()
ENDCLASS

METHOD Execute() CLASS hbNFeConsulta
   LOCAL cXMLResp, aRetorno := hash(), oFuncoes := hbNFeFuncoes(), cXMLSai, cXMLFile, oSefaz

   IF ::cUFWS = NIL
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := '2.01'
   ENDIF

   IF ::tpAmb = NIL
      ::tpAmb := ::ohbNFe:tpAmb
   ENDIF

   IF .NOT. Empty( ::cNFeFile )
      IF .NOT. File( ::cNFeFile )
         aRetorno[ 'OK' ]       := .F.
         aRetorno[ 'MsgErro' ]  := 'Arquivo não encontrado ' + ::cNFeFile
         RETURN(aRetorno)
      ENDIF
      TRY
         cXMLFile := MEMOREAD( ::cNFeFile )
      CATCH
         aRetorno[ 'OK' ]       := .F.
         aRetorno[ 'MsgErro' ]  := 'Erro ao abrir ' + ::cNFeFile
         RETURN( aRetorno )
      END
      ::cChaveNFe := Substr( ::cNFeFile ,AT('-nfe',::cNFeFile)-44 ,44 )
      IF 'retCancNFe' $ cXMLFile
         aRetorno[ 'OK' ]       := .F.
         aRetorno[ 'MsgErro' ]  := 'NFe ' + ::cNFeFile+' cancelada'
         RETURN aRetorno
      ENDIF
   ENDIF

   oSefaz := SefazClass():New()
   ::SetSefaz( oSefaz )
   oSefaz:NfeConsulta( ::cChaveNfe )
   cXmlResp := oSefaz:cXmlResposta

   cXMLResp := oFuncoes:pegaTag( cXMLResp, 'retConsSitNFe' )

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-sit.xml", cXMLResp )
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
            hb_MemoWrit( ::cNFeFile, cXMLSai )
         CATCH
            aRetorno['MsgErro']  := 'Erro ao gravar protNFe no arquivo '+::cNFeFile
            RETURN(aRetorno)
         END
      ENDIF
   ENDIF

   RETURN aRetorno
