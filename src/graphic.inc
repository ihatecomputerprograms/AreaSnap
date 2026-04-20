proc screenshot uses rbx rsi rdi r12 r13 r14 r15, token, size, numEncoders, gdip_bitmap

locals
    st            SYSTEMTIME

    encoder_clsid db 16 dup ?
    lpDataStr     db 255 dup ?
endl

    mov        r14d, ecx ; width
    mov        r15d, edx ; height

frame
    invoke     GdiplusStartup, addr token, addr GDI, 0
    test       rax, rax
    jnz        .exit

    invoke     GdipGetImageEncodersSize, addr numEncoders, addr size
    test       rax, rax
    jnz        .shutdown_gdiplus
        
    invoke     GlobalAlloc, GPTR, qword[size]
    test       rax, rax
    je         .exit
    mov        rbx, rax

    invoke     GdipGetImageEncoders, qword[numEncoders], qword[size], rbx
    test       rax, rax
    jnz        .exit

    mov        r12, rbx
    mov        r13, qword[numEncoders]
    
@@:
    mov        rsi, qword[r12 + ImageCodecInfo.MimeType]
    mov        rdi, encoder
    mov        rcx, encoder.sizeof
    repe       cmpsb
    je         @f

    add        r12, sizeof.ImageCodecInfo
    dec        r13
    jnz        @b
    jmp        .exit

@@:
    lea        rsi, qword[r12 + ImageCodecInfo.Clsid] 
    lea        rdi, qword[encoder_clsid]
    mov        rcx, 4
    rep        movsd

    invoke     GlobalFree, rbx 

    invoke     GetDC, 0
    test       rax, rax
    jz         .exit          
    mov        rbx, rax  ; overwrite rbx here!!!
    
    invoke     CreateCompatibleDC, rbx
    mov        r12, rax  

    invoke     CreateCompatibleBitmap, rbx, r14d, r15d ;hdc width height
    test       rax, rax
    jz         .release_dc
    mov        r13, rax  
    movq       xmm11, rax 

    invoke     SelectObject, r12, r13 
    test       rax, rax
    jz         .delete_dc

    invoke     BitBlt, r12, 0,0, r14d, r15d, rbx, dword[rect.left], dword[rect.top], SRCCOPY ;hdc x y width height hdc2 x2 y2
    test       rax, rax
    jz         .delete_dc

    invoke     GdipCreateBitmapFromHBITMAP, r13, 0, addr gdip_bitmap 
    test       rax, rax
    jnz        .delete_dc

    invoke     GetLocalTime, addr st

    lea        r15, qword[lpDataStr]
    invoke     GetEnvironmentVariableW, EnvVariable, r15, 255
    imul       rax, 2
    add        r15, rax

    invoke     GetDateFormatW, LOCAL_SYSTEM_DEFAULT, 0, addr st, lpformat_data, r15, 255 ; 255 - rax!!!
    imul       rax, 2
    add        r15, rax
    sub        r15, 2

    invoke     GetTimeFormatW, LOCAL_SYSTEM_DEFAULT, 0, addr st, lpformat_time, r15, 255   
    ; imul       rax, 2
    ; add        r15, rax ; for feature!

    invoke     GdipSaveImageToFile, qword[gdip_bitmap], addr lpDataStr, addr encoder_clsid, 0
    invoke     GdipDisposeImage, qword[gdip_bitmap]

.delete_dc:
    invoke     DeleteDC, r12

.release_dc:
    invoke     ReleaseDC, 0, rbx

.shutdown_gdiplus:
    invoke     GdiplusShutdown, qword[token]

.exit:
endf
    ret
endp

proc copy_to_clipboard uses rbx rsi 

    movq       rbx, xmm11 ; bitmap

frame
    mov        rcx, 0
    call       [OpenClipboard]
    test       rax, rax
    je         @f
    
    call       [EmptyClipboard]    
    invoke     SetClipboardData, CF_BITMAP, rbx
    call       [CloseClipboard]

@@:
    invoke     DeleteObject, rbx
endf
    ret
endp    

proc double_buff uses rbx rsi

frame 
    invoke     GetDC, rsi ; rcx == rsi
    mov        rbx, rax

    invoke     GetSystemMetrics, SM_CXSCREEN 
    mov        dword[screen_width], eax
    invoke     GetSystemMetrics, SM_CYSCREEN
    mov        dword[screen_height], eax

    invoke     CreateCompatibleDC, rbx
    mov        qword[hBackDC], rax

    invoke     CreateCompatibleBitmap, rbx, dword[screen_width], dword[screen_height]
    mov        qword[hBackBmp], rax
    invoke     SelectObject, qword[hBackDC], rax

    invoke     SetLayeredWindowAttributes, rsi, 0x00FFFFFF, 192, LWA_COLORKEY or LWA_ALPHA
    invoke     ReleaseDC, rsi, rbx 

    invoke     CreatePen, PS_SOLID, 2, 0x00FFFFF0
    mov        qword[hWhitePen], rax
    invoke     SelectObject, qword[hBackDC], rax
endf   
    ret
endp