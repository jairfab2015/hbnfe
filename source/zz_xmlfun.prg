/*
   O objetivo desta função é montar o "node" do XML com menos fonte.
   Ao invés de "<cliente>" + cliente->Codigo + "</cliente>"
   Só usar  XmlTag( "cliente", cliente->Codigo )
   Fica um fonte menor e mais legível
   E quando o conteúdo for vazio, o node vira "<cliente />"
*/
FUNCTION XmlTag( cTag, xValue )
   LOCAL cXml

   IF Empty( xValue )
      cXml := "<" + cTag + " />"
   ELSE
      cXml := "<" + cTag + ">" + xValue + "</" + cTag + ">"
   ENDIF
   RETURN cXml
