** WILSON ALVES
** Teste de Impressão do DANFE em FastReport - Projeto: hbNFe
**

#include "hbclass.ch"

REQUEST DBFCDX

****************************************************************************************************
FUNCTION MAIN()
****************************************************************************************************
   LOCAL nOption

   SETMODE(25,80)

   SET DATE BRITISH
   SET SCOR OFF

   DO WHILE .T.

      ? "Escolha o Teste da hbNFe:"
      ? "1) Mostrar Relatorio"
      ? "2) Editar Relatorio"
      ? "3) Salvar como PDF"

      ? "0) Quit"
      ? "> "

      DO WHILE .T.

        nOption := Inkey( 0 )

        IF nOption <> ASC("0") .AND. nOption <> ASC("1") .AND. nOption <> ASC("2") .AND. nOption <> ASC("3") .AND. nOption <> asc('q')
           LOOP
        ENDIF

        EXIT

      ENDDO

      ?? Chr( nOption )

      IF nOption == Asc( "0" )  .OR. nOption ==  asc('q')
         EXIT
      ELSEIF nOption == Asc( "1" )
         CreateDANFE( 0 )  // Preview
      ELSEIF nOption == Asc( "2" )
	        CreateDANFE( 2 ) // Design
      ELSEIF nOption == Asc( "3" )
      	  CreateDANFE( 0 ,'DANFE-NFE.PDF' ) // Salvar em PDF
      ENDIF

   ENDDO

RETURN Nil

//-----------------------------------------------------------------
STATIC FUNCTION CreateDanfe( Modo , cPDF )
//-----------------------------------------------------------------
LOCAL oDANFfast

oDANFfast:=hbNfeDANFEFast()
oDANFfast:ArquivoXML    := '35-NFAUTORIZADA.XML'
oDANFfast:ArquivoFR3 := 'danfe.fr3'
oDANFfast:ArquivoPDF    := cPDF
oDANFfast:Modo          := Modo
oDANFfast:cSHOWlogo     := 'N'
aRetorno:=oDANFfast:Executa()

Return(aRetorno) // NIL
