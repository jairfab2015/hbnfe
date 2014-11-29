#include "hbclass.ch"

#define WSCTERECEPCAO              1
#define WSCTECONSULTAPROTOCOLO     2
#define WSCTESTATUSSERVICO         3
#define WSNFECANCELAMENTO          4
#define WSNFECONSULTACADASTRO      5
#define WSNFECONSULTAPROTOCOLO     6
#define WSNFEINUTILIZACAO          7
#define WSNFERECEPCAO              8
#define WSNFERECEPCAOEVENTO        9
#define WSNFERETRECEPCAO           10
#define WSNFESTATUSSERVICO         11
#define WSNFEDOWNLOADNF            12
#define WSNFECONSULTADEST          13
#define WSMDFERECEPCAO             14
#define WSMDFERETRECEPCAO          15
#define WSMDFERECEPCAOEVENTO       16
#define WSMDFECONSULTAPROTOCOLO    17
#define WSMDFESTATUSSERVICO        18

#define WSHOMOLOGACAO   "2"
#define WSPRODUCAO      "1"

CREATE CLASS hbnfeSefazClass
   VAR   cAmbiente     INIT WSPRODUCAO
   VAR   cScan         INIT "N"
   VAR   cUF           INIT "SP"
   VAR   cVersao       INIT ""
   VAR   cServico      INIT ""
   VAR   cSoapAction   INIT ""
   VAR   cWebService   INIT ""
   VAR   cXmlDados     INIT ""
   VAR   cXmlSoap      INIT ""
   VAR   cXmlRetorno   INIT ""
   VAR   cProjeto      INIT "nfe"
   VAR   cCertificado  INIT ""
   VAR   cCertSerial   INIT ""  // pra libcurl
   VAR   cCertPassword INIT ""  // pra libcurl
   VAR   lLibCurl      INIT .F. // pra libcurl
   //METHOD CTEConsulta( cChave, cCertificado )
   //METHOD CTELoteEnvia( cXml, cLote, cUf, cCertificado )
   //METHOD CTEStatus( cUf, cCertificado )
   //METHOD MDFEConsulta( cChave, cCertificado )
   //METHOD MDFELoteEnvia( cXml, cLote, cUf, cCertificado )
   //METHOD MDFEConsultaRecibo( cRecibo, cUf, cCertificado )
   //METHOD MDFEStatus( cUf, cCertificado )
   //METHOD NFECancela( cUf, cXml, cCertificado )
   //METHOD NFECadastro( cUf, cCnpj, cCertificado )
   //METHOD NFEConsulta( cChave, cCertificado )
   //METHOD NFEEventoEnvia( cChave, cXml, cCertificado )
   //METHOD NFEInutiliza( cUf, cAno, cCnpj, cMod, cSerie, cNumIni, cNumFim, cJustificativa, cCertificado )
   //METHOD NFELoteEnvia( cXml, cLote, cUf, cCertificado )
   //METHOD NFEConsultaRecibo( cRecibo, cUf, cCertificado )
   //METHOD NFEStatus( cUf, cCertificado )
   //METHOD GetWebService( cUf, cServico )
   //METHOD XmlSoapEnvelope()
   //METHOD XmlSoapPost()
   //METHOD MicrosoftXmlSoapPost()
   //METHOD CUrlXmlSoapPost()
   END CLASS
