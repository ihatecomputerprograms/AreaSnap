INFINITE = -1
DELETE = 0x00010000
FileRenameInfo = 3
FileDispositionInfo = 4
INVALID_FILE_SIZE = -1

WINHTTP_ACCESS_TYPE_NO_PROXY = 1
WINHTTP_FLAG_ASYNC = 0x10000000 
WINHTTP_FLAG_SECURE = 0x00800000
WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0
WINHTTP_NO_REFERER = NULL
WINHTTP_DEFAULT_ACCEPT_TYPES = NULL
WINHTTP_NO_ADDITIONAL_HEADERS = NULL
WINHTTP_NO_REQUEST_DATA = NULL
INTERNET_DEFAULT_HTTPS_PORT = 443

EQUAL_ANY         equ 0000b
RANGES            equ 0100b
EQUAL_EACH        equ 1000b
EQUAL_ORDERED     equ 1100b
NEGATIVE_POLARITY equ 010000b
BYTE_MASK         equ 1000000b

CALG_SHA_256 equ 0x0000800c

ICU_DECODE = 0x10000000 
ICU_REJECT_USERPWD = 0x00004000 
WINHTTP_FLAG_REFRESH = 0x00000100
WINHTTP_FLAG_AUTO_REDIRECT = 0x00000200 

INTERNET_OPEN_TYPE_DIRECT = 1
INTERNET_OPEN_TYPE_PROXY = 3 

CRYPT_STRING_HEXRAW = 0x0000000c

struct URL_COMPONENTS ; https://learn.microsoft.com/en-us/windows/win32/api/winhttp/ns-winhttp-url_components

  dwStructSize       dd ?         
  _p004              dd ?
  lpszScheme         dq ?          
  dwSchemeLength     dd ?         
  nScheme            dd ?          
  lpszHostName       dq ?          
  dwHostNameLength   dd ?        
  _p0034             dd ?
  nPort              dd ?          
  lpszUserName       dq ?          
  dwUserNameLength   dd ?          
  lpszPassword       dq ?        
  dwPasswordLength   dd ?        
  _p0044             dd ?
  lpszUrlPath        dq ?          
  dwUrlPathLength    dd ?         
  _p0054             dd ?
  lpszExtraInfo      dq ?         
  dwExtraInfoLength  dd ?         
  _p0064             dd ?

ends


INTERNET_SCHEME_HTTP  = 1
INTERNET_SCHEME_HTTPS = 2


struct GdiplusStartupInput

  GdiplusVersion           dd ?
  _p004                    dd ?
  DebugEventCallback       dq ?
  SuppressBackgroundThread dq ?
  SuppressExternalCodecs   dq ?

ends


struct ImageCodecInfo

  Clsid             db 16 dup ?
  FormatID          db 16 dup ?
  CodecName         dq ?
  DllName           dq ?
  FormatDescription dq ?
  FilenameExtension dq ?
  MimeType          dq ?
  Flags             dd ?
  Version           dd ?
  SigCount          dd ?
  SizeSize          dd ?
  SigPattern        dq ?
  SigMask           dq ?

ends


struct FILE_RENAME_INFO

  ReplaceIfExists   dq ?
  RootDirectory     dq ?
  FileNameLength    dd ?
  FileName          dq ?

ends


struct FILE_DISPOSITION_INFO ; https://learn.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-file_disposition_info

  DeleteFile db ? 

ends