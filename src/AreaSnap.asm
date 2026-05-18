format PE64 GUI 6.0 on 'nul'
include 'win64a.inc' 
include 'const.inc'
entry main

section '.text' code readable executable
include 'update.inc' 
include 'graphic.inc'
include 'interface.inc'

proc main, hThread

locals 
    msg_hotkey MSG
    msg MSG
endl
  
frame  
    invoke  CreateThread, NULL, 0, addr check_update, 0,0, NULL
    mov [hThread], rax
    
    call  add_to_startup
    
    invoke  RegisterHotKey, NULL, NULL, MOD_SHIFT or MOD_ALT, 0x51

    invoke  GetModuleHandle, 0
    mov qword[wc.hInstance], rax

    invoke  LoadCursor, 0, IDC_CROSS
    mov qword[wc.hCursor], rax

    invoke  RegisterClassEx, addr wc
    test rax,rax
    je .error

.wait_hotkey:
    invoke  GetMessage, addr msg_hotkey, 0,0,0
    cmp [msg_hotkey.message], WM_HOTKEY
    je .create_window

    invoke  TranslateMessage, addr msg_hotkey
    invoke  DispatchMessage, addr msg_hotkey
    jmp .wait_hotkey

.create_window:
    invoke  CreateWindowEx, WS_EX_LAYERED or WS_EX_TOPMOST or WS_EX_TOOLWINDOW, addr szClass, 0, WS_POPUP or WS_VISIBLE or WS_MAXIMIZE, 0,0,0,0,0,0, addr wc.hInstance, 0
    mov [hwnd],rax
    test rax,rax
    je .error

@@:
    invoke  GetMessage, addr msg, 0,0,0
    test rax,rax
    je .wait_hotkey

    invoke  TranslateMessage, addr msg
    invoke  DispatchMessage, addr msg
    jmp @b  

.error:
    invoke  WaitForSingleObject, [hThread], INFINITE
    invoke  CloseHandle, [hThread]
    invoke  ExitProcess, -1   
endf  

endp

proc AreaSnap uses rbx rsi rdi r12 r13 r14 r15
    cmp rdx, WM_MOUSEMOVE
    je .mousemove
    cmp rdx, WM_PAINT
    je .wmpaint
    cmp rdx, WM_LBUTTONDOWN
    je .lbuttondown
    cmp rdx, WM_LBUTTONUP
    je .lbuttonup
    cmp rdx, WM_KEYDOWN
    je .wmkeydown
    cmp rdx, WM_KILLFOCUS
    je .wmkillfocus        
    cmp rdx, WM_DESTROY
    je .wmdestroy
    cmp rdx, WM_CREATE
    je .wmcreate    
    call  [DefWindowProc]
    jmp .finish

.wmkeydown:
    cmp r8d, VK_ESCAPE 
    je .wmkillfocus
    cmp r8d, 0x31  
    je .changext_to_png
    cmp r8d, 0x32  
    je .changext_to_gif
    cmp r8d, 0x33  
    je .changext_to_jpeg
    cmp r8d, 0x34  
    je .changext_to_bmp
    cmp r8d, 0x35
    je .changext_to_tiff

    xor rax,rax
    jmp .finish

.changext_to_png:
    mov rbx, 0x000067006E007000
    jmp @f
.changext_to_gif:
    mov rbx, 0x0000660069006700
    jmp @f
.changext_to_jpeg:
    mov rbx, 0x00006700650070006A00
    jmp @f
.changext_to_bmp:
    mov rbx, 0x000070006D006200 
    jmp @f
.changext_to_tiff:
    mov rbx, 0x00006600660069007400
@@:
    mov qword[encoder+11],rbx

    xor rax,rax
    jmp .finish

.wmcreate: 
    call  double_buff

    xor rax,rax
    jmp .finish

.mousemove:
    cmp byte[flag], 1
    jne .finish

    mov word[rect.right],r9w
    shr r9, 16 
    mov word[rect.bottom],r9w

    invoke  InvalidateRect, rcx, 0,0 ; send WM_PAINT! 

    xor rax,rax   
    jmp .finish

.wmpaint:    

locals
    ps PAINTSTRUCT
endl

frame    
    invoke  PatBlt, qword[hBackDC], 0,0, qword[screen_width], qword[screen_height], BLACKNESS

    inc dword[rect.right]
    inc dword[rect.bottom]
    invoke  Rectangle, qword[hBackDC], dword[rect.left], dword[rect.top], dword[rect.right], dword[rect.bottom]

    invoke  BeginPaint, rsi, addr ps 
    invoke  BitBlt, [ps.hdc], 0,0, qword[screen_width], qword[screen_height], qword[hBackDC], 0,0, SRCCOPY 
    invoke  EndPaint, rsi, addr ps
endf

    xor rax,rax  
    jmp .finish

.lbuttondown: ; r9W contain x in LOWORD and y in HIWORD
    mov byte[flag],1 

    mov word[rect.left],r9w
    shr r9,16 
    mov word[rect.top],r9w 

    invoke  SetCapture, rcx
    invoke  SelectObject, qword[hBackDC], qword[hWhitePen]

    xor rax,rax      
    jmp .finish   

.lbuttonup:
    mov r12, rcx 

    invoke  SetLayeredWindowAttributes, r12, 0x00FFFFFF, 0, LWA_COLORKEY or LWA_ALPHA
    invoke  ReleaseCapture

    mov eax,dword[rect.left]
    mov r14d,dword[rect.right]
    mov ebx,dword[rect.top]
    mov r15d,dword[rect.bottom]

    cmp eax,r14d
    jle @f 
    xchg eax,r14d 

@@:
    mov dword[rect.left],eax
    cmp ebx,r15d
    jle @f
    xchg ebx,r15d 

@@:
    mov dword[rect.top],ebx
    sub r14d,eax
    sub r15d,ebx

    call  screenshot

    invoke  DestroyWindow, r12

    xor rax,rax  
    jmp .finish

.wmkillfocus:
    invoke  DestroyWindow, rcx

.wmdestroy:

frame
    mov byte[flag], 0 

    mov dword[rect.left],0
    mov dword[rect.right],0

    invoke  DeleteObject,[hWhitePen]
    invoke  DeleteObject,[hBackBmp]
    invoke  DeleteDC,[hBackDC]

    invoke  PostQuitMessage, 0 
endf
    xor rax,rax

.finish:
    ret
endp

section '.bss' readable writeable
screen_width dq ?
screen_height dq ?

hwnd dq ?
hBackBmp dq ?
hBackDC dq ?  
hWhitePen dq ?
flag db ?

section '.data' readable writeable
wc WNDCLASSEX sizeof.WNDCLASSEX, 0, AreaSnap, 0,0,0,0,0,0,0, szClass, 0 
rect RECT
GDI GdiplusStartupInput 1

github_api db 'https://api.github.com/repos/ihatecomputerprograms/AreaSnap/releases',0

szClass db 'AreaSnap.exe',0
.sizeof = $ - szClass

ads du ':wtfbbq',0 
.sizeof = $ - ads    

BCRYPT_SHA256_ALGORITHM du 'SHA256',0

key db 'digest',0
.sizeof = $ - key

key2 db 'browser_download_url',0
.sizeof = $ - key2

encoder du 'image/png',0
.sizeof = $ - encoder  

data import
  library kernel32, 'KERNEL32.DLL',\
          user32, 'USER32.DLL',\
          gdi32, 'GDI32.DLL',\
          gdiplus, 'GDIPLUS.DLL',\
          bcrypt, 'Bcrypt.dll',\
          crypt32, 'crypt32.dll',\
          wininet, 'Wininet.dll',\
          advapi32, 'Advapi32.dll'

  include 'API\kernel32.inc' ; add SetFileInformationByHandle 
  include 'API\user32.inc' 
  include 'API\gdi32.inc'
  include 'API\advapi32.inc'

  import gdiplus,\
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
            1, LANG_ENGLISH, version

  versioninfo version, VOS__WINDOWS32, VFT_APP, VFT2_UNKNOWN, LANG_ENGLISH, 0,\
            'FileDescription', 'AreaSnap',\
            'ProductName', 'AreaSnap',\
            'LegalCopyright', <'@ihatecomputerprograms. 2026'>,\
            'FileVersion','1.0.3',\
            'ProductVersion', '1.0.3',\
            'OriginalFilename', 'AREASNAP.EXE'

section '.reloc' data readable discardable fixups