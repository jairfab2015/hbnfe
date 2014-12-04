//
// definições para uso da CAPICOM
//

#define _CAPICOM_STORE_OPEN_READ_ONLY                 0           // Somente Smart Card em Modo de Leitura

#define _CAPICOM_MEMORY_STORE                         0
#define _CAPICOM_LOCAL_MACHINE_STORE                  1
#define _CAPICOM_CURRENT_USER_STORE                   2
#define _CAPICOM_ACTIVE_DIRECTORY_USER_STORE          3
#define _CAPICOM_SMART_CARD_USER_STORE                4

#define _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED           2
#define _CAPICOM_CERTIFICATE_FIND_SHA1_HASH           0           // Retorna os Dados Criptografados com Hash SH1
#define _CAPICOM_CERTIFICATE_FIND_EXTENDED_PROPERTY   6
#define _CAPICOM_CERTIFICATE_FIND_TIME_VALID          9           // Retorna Certificados Válidos
#define _CAPICOM_CERTIFICATE_FIND_KEY_USAGE           12          // Retorna Certificados que contém dados.
#define _CAPICOM_DIGITAL_SIGNATURE_KEY_USAGE          0x00000080  // Permitir o uso da Chave Privada para assinatura Digital
#define _CAPICOM_AUTHENTICATED_ATTRIBUTE_SIGNING_TIME 0           // Este atributo contém o tempo em que a assinatura foi criada.
#define _CAPICOM_INFO_SUBJECT_SIMPLE_NAME             0           // Retorna o nome de exibição do certificado.
#define _CAPICOM_ENCODE_BASE64                        0           // Os dados são guardados como uma string base64-codificado.
#define _CAPICOM_E_CANCELLED                          -2138568446 // A operação foi cancelada pelo usuário.
#define _CERT_KEY_SPEC_PROP_ID                        6
#define _CAPICOM_CERT_INFO_ISSUER_EMAIL_NAME          0
#define _SIG_KEYINFO                                  2
