****************************************************************************************************
* Include hbNFE                                                                                    *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

// #include "common.ch"      // mas isto nao é default?
#include "harupdf.ch"        // Saiu da condição xHarbour, porque xHarbour também tem harupdf
#ifndef __XHARBOUR__         // no Harbour 3.2 também não precisa ao se usar hbc
   #include "hbwin.ch"
   #include "hbzebra.ch"
   #include "hbcompat.ch"    // esta é a única que não faz parte de um hbc
#endif
#ifdef __LIBCURL__
   #include "hbcurl.ch"      // devido aos includes, precisa existir
#endif

// No Windows 64 bits o registro é diferente e pode precisar desfazer o registro errado anterior
//
// \windows\system32\regsvr32 /u msxml5.dll
// \windows\system32\regsvr32 /u capicom.dll
//
// \windows\syswow64\regsvr32 msxml5.dll
// \windows\syswow64\regsvr32 capicom.dll
//
// msxml5r.dll não precisa ser registrada

#include "capicom.ch"

#define _RECEPCAO             1
#define _RETRECEPCAO          2
#define _CANCELAMENTO         3
#define _INUTILIZACAO         4
#define _CONSULTAPROTOCOLO    5
#define _STATUSSERVICO        6
#define _CONSULTACADASTRO     7
#define _RECEPCAODEEVENTO     8
#define _EVENTO               9
#define _CONSULTANFEDEST      10
#define _DOWNLOADNFE          11
#define _RECPEVENTO           12

#define _MSXML2_DOMDocument          'MSXML2.DOMDocument.5.0'
#define _MSXML2_MXDigitalSignature   'MSXML2.MXDigitalSignature.5.0'
#define _MSXML2_XMLSchemaCache       'MSXML2.XMLSchemaCache.5.0'
#define _MSXML2_ServerXMLHTTP        'MSXML2.ServerXMLHTTP.5.0'

#define _LOGO_ESQUERDA        1
#define _LOGO_DIREITA         2
#define _LOGO_EXPANDIDO       3

#define HBNFE_MXML            1
#define HBNFE_CURL            2

#define HBNFE_EXIGIDA         .T.
#define HBNFE_NAOEXIGIDA      .F.
