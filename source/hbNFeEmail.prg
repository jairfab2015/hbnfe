****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Envio de Email)                                               *
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

CLASS hbNFeEmail
   DATA ohbNFe

   DATA cSubject
   DATA cMsgTexto
   DATA cMsgHTML
   DATA cServerIP
   DATA cFrom
   DATA cUser
   DATA cPass
   DATA nPortSMTP
   DATA lConf
   DATA lSSL
   DATA lAut

   DATA aFiles
   DATA aTo
   DATA aCC
   DATA aBCC

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeEmail
LOCAL aRetorno := hash(), oCfg, oMsg, oError, nITo, nIFiles, cArgs, cFileName, xa, cArg

   IF VALTYPE( ::aTo ) == "C"
      ::aTo := { ::aTo }
   ENDIF
   IF ::cSubject == Nil
      ::cSubject := ::ohbNFe:cEMail_Subject
   ENDIF
   IF ::cMsgTexto == Nil
      ::cMsgTexto := ::ohbNFe:cEMail_MsgTexto
   ENDIF
   IF ::cMsgHTML == Nil
      ::cMsgHTML := ::ohbNFe:cEMail_MsgHTML
   ENDIF
   IF ::cServerIP == Nil
      ::cServerIP := ::ohbNFe:cEMail_ServerIP
   ENDIF
   IF ::cFrom == Nil
      ::cFrom := ::ohbNFe:cEMail_From
   ENDIF
   IF ::cUser == Nil
      ::cUser := ::ohbNFe:cEMail_User
   ENDIF
   IF ::cPass == Nil
      ::cPass := ::ohbNFe:cEMail_Pass
   ENDIF
   IF ::nPortSMTP == Nil
      ::nPortSMTP := ::ohbNFe:nEMail_PortSMTP
   ENDIF
   IF ::lConf == Nil
      ::lConf := ::ohbNFe:lEMail_Conf
   ENDIF
   IF ::lConf = Nil
      ::lConf = .F.
   ENDIF
   IF ::lSSL == Nil
      ::lSSL := ::ohbNFe:lEMail_SSL
   ENDIF
   IF ::lSSL = Nil
      ::lSSL = .F.
   ENDIF
   IF ::lAut == Nil
      ::lAut := ::ohbNFe:lEMail_Aut
   ENDIF

   // preparar
   TRY

     oCfg := win_oleCreateObject( "CDO.Configuration" )

     WITH OBJECT oCfg:Fields
       :Item( "http://schemas.microsoft.com/cdo/configuration/smtpserver"      ):Value := ::cServerIP
       :Item( "http://schemas.microsoft.com/cdo/configuration/smtpserverport"  ):Value := ::nPortSMTP
       :Item( "http://schemas.microsoft.com/cdo/configuration/sendusing"       ):Value := 2
       :Item( "http://schemas.microsoft.com/cdo/configuration/smtpauthenticate"):Value := ::lAut
       :Item( "http://schemas.microsoft.com/cdo/configuration/smtpusessl"      ):Value := ::lSSL
       :Item( "http://schemas.microsoft.com/cdo/configuration/sendusername"    ):Value := ALLTRIM(::cUser)
       :Item( "http://schemas.microsoft.com/cdo/configuration/sendpassword"    ):Value := ALLTRIM(::cPass)
*       :Item( "http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout" ):Value := 30
       :Update()
     END WITH
   CATCH oError
   	aRetorno[ "OK" ] = .F.
      aRetorno[ "MsgErro" ] := "Falha conexão com o smtp"+HB_EOL()+ ;
                               "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_EOL()+ ;
                      		    "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_EOL()+ ;
                      		    "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_EOL()+ ;
                      		    "SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_EOL()+ ;
                      		    "Mensangem: " + oError:Description
      RETURN( aRetorno )
   END

   // enviar
   FOR nITo:=1 TO LEN( ::aTo )

      oMsg := win_oleCreateObject ( "CDO.Message" )

      WITH OBJECT oMsg
        :Configuration := oCfg
        :From := ::cFrom
        :To   := ::aTo[ nITo ]
        IF ::aCC <> Nil
           :Cc := ::aCC
        ELSE
		     :Cc := ""
        ENDIF
        IF ::aBCC <> Nil
           :BCC := ::aBCC
        ELSE
		     :BCC := ""
        ENDIF
        :Subject := ::cSubject
        IF !EMPTY( ::cMsgTexto )
           :TextBody = ::cMsgTexto
        ELSE
           :HTMLBody = ::cMsgHTML
        ENDIF
        FOR nIFiles := 1 TO LEN( ::aFiles )
           IF FILE( ALLTRIM(::aFiles[ nIFiles ]) )
              :AddAttachment(ALLTRIM(::aFiles[ nIFiles ]))
           ELSE
              aRetorno[ "OK" ] := .F.
              aRetorno[ "MsgErro" ] := 'Arquivo não encontrado: '+::aFiles[ nIFiles ]
              RETURN(aRetorno)
           ENDIF
        NEXT
        IF ::lConf=.T.
         :Fields( "urn:schemas:mailheader:disposition-notification-to" ):Value := ::cFrom
         :Fields:update()
        ENDIF
      END WITH
      TRY
        oMsg:Send() // retorno :=
      CATCH oError
	      cFilename := ""
	      IF oError:Filename<>NIL
	         IF VALTYPE(oError:Filename) = "C"
	            cFilename := oError:Filename
	         ELSEIF VALTYPE(oError:Filename) = "N"
	            cFilename := TRANSFORM(oError:Filename,Nil)
	         ELSE
	           cFilename := VALTYPE(oError:Filename)
	         ENDIF
			ENDIF
	      cArgs := ""
	      IF oError:Args<>NIL
	         IF VALTYPE(oError:Args) = "C"
	            cArgs := oError:Args
	         ELSEIF VALTYPE(oError:Args) = "N"
	            cArgs := TRANSFORM(oError:Args,Nil)
	         ELSEIF VALTYPE(oError:Args) = "A"
	            FOR xA = 1 TO LEN(oError:Args)
	               // cArg := ""
	               IF VALTYPE(oError:Args[xA])="C"
      	            cArg := oError:Args[xA]
	               ELSEIF VALTYPE(oError:Args[xA])="N"
      	            cArg := TRANSFORM(oError:Args[xA],Nil)
	               ELSE
      	            cArg := "desc."+VALTYPE(oError:Args[xA])
	               ENDIF
	               cArgs += cArg+","
	            NEXT
	         ELSE
	           cArgs := VALTYPE(oError:Args)
	         ENDIF
			ENDIF
			aRetorno[ "MsgErro" ] := "Falha envio de email"+HB_EOL()+ ;
                	                "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_EOL()+ ;
                	      		    "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_EOL()+ ;
                	      		    "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_EOL()+ ;
                	      		    "SubSystem: " + IF(oError:SubSystem=NIL,"",oError:SubSystem) + ";" +HB_EOL()+ ;
                	      		    "Operation: " + IF(oError:Operation=NIL,"",IF(ISCHARACTER(oError:Operation),oError:Operation,STR(oError:Operation))) + ";" +HB_EOL()+ ;
                	      		    "Filename: " + cFilename + ";" +HB_EOL()+ ;
                	      		    "Args: " + cArgs + ";" +HB_EOL()+ ;
                	      		    "Mensangem: " + IF(oError:Description=NIL,"",oError:Description) + ";"
         #ifndef __XHARBOUR__
             aRetorno[ "MsgErro" ] += "WinOle: "+ win_oleErrorText()
         #endif
         aRetorno[ "OK" ] = .F.
         RETURN( aRetorno )
      END
    NEXT
    aRetorno[ "OK" ] = .T.
RETURN( aRetorno )
