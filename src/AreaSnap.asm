format PE64 GUI 6.0 on 'nul'
include 'win64a.inc' 
include 'const.inc'
entry main

section '.text' code readable executable
include 'update.inc' 
include 'graphic.inc'

proc main, hThread

locals 
    msg          MSG
endl

frame  
    invoke     CreateThread, NULL, 0, addr check_update, 0,0, NULL
    mov        qword[hThread], rax
    
    invoke     GetModuleHandle, 0
    mov        qword[wc.hInstance], rax

    invoke     LoadCursor, 0, IDC_CROSS
    mov        qword[wc.hCursor], rax

    invoke     RegisterClassEx, addr wc
    test       rax, rax
    je         .escape

    invoke     CreateWindowEx, WS_EX_LAYERED or WS_EX_TOPMOST or WS_EX_TOOLWINDOW, addr szClass, 0, WS_POPUP or WS_VISIBLE or WS_MAXIMIZE, 0,0,0,0,0,0, addr wc.hInstance, 0
    test       rax, rax
    je         .escape

@@:
    invoke     GetMessage, addr msg, 0,0,0
    test       rax, rax
    je         .escape

    invoke     TranslateMessage, addr msg
    invoke     DispatchMessage, addr msg
    jmp        @b  

.escape:
    invoke     WaitForSingleObject, qword[hThread], INFINITE
    invoke     CloseHandle, qword[hThread]

    invoke     ExitProcess, 0   
endf  

endp

proc AreaSnap uses rbx rsi rdi r12 r13 r14 r15
    cmp        rdx, WM_CREATE
    je         .wmcreate
    cmp        rdx, WM_KEYDOWN
    je         .wmkeydown
    cmp        rdx, WM_PAINT
    je         .wmpaint
    cmp        rdx, WM_LBUTTONDOWN
    je         .lbuttondown
    cmp        rdx, WM_MOUSEMOVE
    je         .mousemove
    cmp        rdx, WM_LBUTTONUP
    je         .lbuttonup
    cmp        rdx, WM_KILLFOCUS
    je         .wmdestroy        
    cmp        rdx, WM_DESTROY
    je         .wmdestroy
    call       qword[DefWindowProc]
    jmp        .finish

.wmkeydown:
    cmp        r8d, VK_ESCAPE 
    je         .wmdestroy
    
    xor        rax,rax
    jmp        .finish

.wmcreate: 
    call       double_buff

    xor        rax,rax
    jmp        .finish

.mousemove:
    cmp        byte[flag], 1
    jne        .finish

    mov        word[rect.right], r9w
    shr        r9, 16 
    mov        word[rect.bottom], r9w

    invoke     InvalidateRect, rcx, 0, 0 ; send WM_PAINT! hwnd, struct 'rect', true\false

    xor        rax,rax   
    jmp        .finish

.wmpaint:    

locals
    ps         PAINTSTRUCT
endl

    ; lea rbx, qword[rect] ???

frame    
    invoke     PatBlt, qword[hBackDC], 0,0, dword[screen_width], dword[screen_height], BLACKNESS

    inc        dword[rect.right]
    inc        dword[rect.bottom]
    invoke     Rectangle, qword[hBackDC], dword[rect.left], dword[rect.top], dword[rect.right], dword[rect.bottom]

    invoke     BeginPaint, rsi, addr ps 
    invoke     BitBlt, [ps.hdc], 0,0, dword[screen_width], dword[screen_height], qword[hBackDC], 0, 0, SRCCOPY 
    invoke     EndPaint, rsi, addr ps
endf

    xor        rax,rax  
    jmp        .finish

.lbuttondown: ; r9W contain x in LOWORD and y in HIWORD
    mov        byte[flag], 1 

    mov        word[rect.left], r9w
    shr        r9, 16 
    mov        word[rect.top], r9w 

    invoke     SetCapture, rcx
    xor        rax,rax      
    jmp        .finish   

.lbuttonup:

frame    
    invoke     SetLayeredWindowAttributes, rcx, 0x00FFFFFF, 0, LWA_COLORKEY or LWA_ALPHA
    invoke     ReleaseCapture

    mov        eax, dword[rect.left]
    mov        ecx, dword[rect.right]
    mov        ebx, dword[rect.top]
    mov        edx, dword[rect.bottom]

    cmp        eax, ecx
    jle        @f 
    xchg       eax, ecx 

@@:
    mov        dword[rect.left], eax
    cmp        ebx, edx
    jle        @f
    xchg       ebx, edx 

@@:
    mov        dword[rect.top], ebx
    sub        ecx, eax
    sub        edx, ebx

    call       screenshot
    call       copy_to_clipboard
    
.wmdestroy:
    invoke     DeleteObject, qword[hWhitePen]
    invoke     DeleteObject, qword[hBackBmp]
    invoke     DeleteDC, qword[hBackDC]

    invoke     PostQuitMessage, 0 
    xor        rax, rax
endf

.finish:
    ret
endp

proc check_update 

locals 
    gethash     rb 65
    getKey      rb MAX_PATH+1
endl

frame
    invoke     GlobalAlloc, GPTR, 15000
    test       rax, rax
    je         @f
    mov        rbx, rax ; save heap

    lea        rsi,[url_api] ; fastcall   open_internet, rbx, url_api
    call       open_internet
    test       rax,rax
    je         @f

    fastcall   SSE_json_parser, key, rbx, addr getKey, key.sizeof, 0
    test       rax, rax
    je         @f

    fastcall   get_self_filehash, addr gethash

    lea        rsi,[gethash]
    lea        rdi,[getKey]
    add        rdi,7
    mov        rcx,4
    repe       cmpsq  
    je         @f

    fastcall   SSE_json_parser, key3, rbx, addr getKey, key3.sizeof, 1    
    test       rax, rax
    je         @f

    invoke     CreateFile, addr getKey, GENERIC_READ or GENERIC_WRITE, 0,0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    cmp        rax, INVALID_HANDLE_VALUE
    je         @f
    mov        r14, rax 

    fastcall   SSE_json_parser, key2, rbx, addr getKey, key2.sizeof, 0     
    test       rax, rax
    je         @f

    lea        rsi,[getKey] ; fastcall   open_internet, rbx, addr getKey
    call       open_internet
    test       rax,rax
    je         @f

    invoke     WriteFile, r14, rbx, rax, 0,0 
    invoke     CloseHandle, r14

    call       self_delete_prog 
@@:
    invoke     GlobalFree, rbx 
endf
    ret  
endp

section '.bss' readable writeable
screen_width    dd ?
screen_height   dd ?

hBackBmp        dq ?
hBackDC         dq ?  
hWhitePen       dq ?
flag            db ?

section '.data' readable writeable
wc WNDCLASSEX sizeof.WNDCLASSEX, 0, AreaSnap, 0,0,0,0,0,0,0, szClass, 0 
rect RECT
GDI GdiplusStartupInput 1

szClass db 'AreaSnap',0
.sizeof = $ - szClass

url_api db 'https://api.github.com/repos/ihatecomputerprograms/AreaSnap/releases',0

ads du ':wtfbbq',0 
.sizeof = $ - ads    

BCRYPT_SHA256_ALGORITHM du 'SHA256',0

key db 'digest',0
.sizeof = $ - key

key2 db 'browser_download_url',0
.sizeof = $ - key2

key3 db 'name',0
.sizeof = $ - key3

encoder du 'image/png',0
.sizeof = $ - encoder  

EnvVariable du 'USERPROFILE',0
lpformat_data du '\Pictures\yyyy-MM-dd',0
lpformat_time du 'HH-mm-ss.png',0

data import
  library kernel32, 'KERNEL32.DLL',\
          user32, 'USER32.DLL',\
          gdi32, 'GDI32.DLL',\
          gdiplus, 'GDIPLUS.DLL',\
          bcrypt, 'Bcrypt.dll',\
          crypt32, 'crypt32.dll',\
          wininet, 'Wininet.dll'

  include 'API\kernel32.inc' ; add SetFileInformationByHandle 
  include 'API\user32.inc' 
  include 'API\gdi32.inc'

  import  gdiplus,\
          GdiplusStartup,'GdiplusStartup',\
          GdiplusShutdown,'GdiplusShutdown',\
          GdipGetImageEncodersSize,'GdipGetImageEncodersSize',\
          GdipGetImageEncoders,'GdipGetImageEncoders',\
          GdipSaveImageToFile,'GdipSaveImageToFile',\
          GdipDisposeImage,'GdipDisposeImage',\
          GdipCreateBitmapFromHBITMAP,'GdipCreateBitmapFromHBITMAP'   

  import bcrypt,\
          BCryptOpenAlgorithmProvider, 'BCryptOpenAlgorithmProvider',\
          BCryptCreateHash, 'BCryptCreateHash',\
          BCryptHashData, 'BCryptHashData',\
          BCryptFinishHash, 'BCryptFinishHash',\  
          BCryptDestroyHash, 'BCryptDestroyHash',\
          BCryptCloseAlgorithmProvider, 'BCryptCloseAlgorithmProvider' 

  import crypt32,\
          CryptBinaryToString, 'CryptBinaryToStringA'

  import wininet,\
          InternetOpen, 'InternetOpenA',\
          InternetOpenUrl, 'InternetOpenUrlA',\
          InternetReadFile, 'InternetReadFile',\
          InternetCloseHandle, 'InternetCloseHandle'      
end data

section '.rsrc' resource readable
  directory RT_VERSION, versions

  resource versions,\
       1, LANG_NEUTRAL, version

  versioninfo version, VOS__WINDOWS32, VFT_APP, VFT2_UNKNOWN, LANG_ENGLISH+SUBLANG_DEFAULT, 0,\
      'FileDescription', 'Screenshot capture',\
      'LegalCopyright', <'2026 @ihatecomputerprograms.'>,\
      'ProductVersion', '0.0.2',\
      'OriginalFilename', 'AreaSnap.exe'
      
section '.reloc' data readable discardable fixups