****************************************************************************************************
* Funcoes pra compatibilidade xHarbour                                                             *
****************************************************************************************************

#ifdef __XHARBOUR__

// Existia o método na classe de funções, mas não usado
FUNCTION hb_CurDrive( xValue )
   RETURN CurDrive( xValue )


// Funcões de OLE
FUNCTION win_OleCreateObject( cObjeto )
   RETURN xhb_CreateObject( cObjeto )

// Gravar sem o Fim de arquivo do DOS Chr(26)
FUNCTION hb_MemoWrit( cFileName, cText )
   RETURN MemoWrit( cFileName, cText, .F. )

// CRLF
FUNCTION HB_EOL()
   RETURN HB_OsNewLine()

// A função abaixo dá erro no Harbour 3.4 msvc
   #pragma BEGINDUMP

   #define _WIN32_IE      0x0500
   #define HB_OS_WIN_32_USED
   #define _WIN32_WINNT   0x0400
   #include <windows.h>
   #include "hbapi.h"
   #include "hbapiitm.h"

   #if !defined( HB_ISNIL )
      #define HB_ISNIL( n )         ISNIL( n )
      #define HB_ISCHAR( n )        ISCHAR( n )
   #endif

   HB_FUNC( SYG_GETPRIVATEPROFILESTRING )
   {
      //TCHAR bBuffer[ 1024 ] = { 0 };
      TCHAR bBuffer[ 5024 ] = { 0 };
      DWORD dwLen ;
      char * lpSection = hb_parc( 1 );
      char * lpEntry = HB_ISCHAR(2) ? hb_parc( 2 ) : NULL ;
      char * lpDefault = hb_parc( 3 );
      char * lpFileName = hb_parc( 4 );
      dwLen = GetPrivateProfileString( lpSection , lpEntry ,lpDefault , bBuffer, sizeof( bBuffer ) , lpFileName);
      if( dwLen )
        hb_retclen( ( char * ) bBuffer, dwLen );
      else
         hb_retc( lpDefault );
   }

   #pragma ENDDUMP

#else
   FUNCTION SYG_GetPrivateProFileString( ... )
      RETURN ""
#endif
