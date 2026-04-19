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

    fastcall   open_internet, rbx, url_api
    test       rax, rax
    je         @f

    fastcall   SSE_json_parser, key, rbx, addr getKey, key.sizeof, 0
    test       rax, rax
    je         @f

    fastcall   get_self_filehash, addr gethash

    lea        rsi, qword[gethash]
    lea        rdi, qword[getKey]
    add        rdi, 7
    mov        rcx, 4
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

    fastcall   open_internet, rbx, addr getKey
    test       rax, rax
    je         @f

    invoke     WriteFile, r14, rbx, rax, 0,0 
    invoke     CloseHandle, r14

    call       self_delete_prog 
@@:
    invoke     GlobalFree, rbx 
endf
    ret  
endp

proc open_internet uses rbx rsi rdi r12 r13 r14 r15, lpbuffer, url

locals 
    bytesread  dq ?
endl

    mov        r12, rcx ; lpbuffer
    mov        rdi, rdx

frame
    invoke     InternetOpen, szClass, INTERNET_OPEN_TYPE_DIRECT, 0,0,0 
    test       rax, rax
    je         .error
    mov        rbx, rax
   
    invoke     InternetOpenUrl, rbx, rdi, 0,0,0,0
    test       rax,rax
    je         .error
    mov        rsi, rax

    invoke     InternetReadFile, rsi, r12, 15000, addr bytesread   
    test       rax, rax
    je         .error

@@: 
    invoke     InternetCloseHandle, rbx
    test       rax, rax
    je         .exit

    invoke     InternetCloseHandle, rsi

.exit:  
    mov        rax, qword[bytesread]
endf    
    ret

.error:
    invoke     GetLastError 
    jmp        @b
endp

proc SSE_json_parser uses rbx rsi rdi r12 r13 r14 r15, input_key, input_lpbuffer, getKey, sizekey, duplicate 
    mov         r15, rcx
    mov         r12, qword[duplicate]
    inc         r12
    xor         r14, r14

    lea         r11, qword[r15]
    movdqu      xmm6, dqword[r15]
    lea         r10, [rdx-16]

.search: ; pcmpistrm ?
    add        r10, 16    
    pcmpistri  xmm6, dqword[r10], EQUAL_ORDERED ; rcx contain the return index  
    ja         .search
    jnc        .error
  
    lea        rsi, [r10+rcx]
    mov        rdi, r15
    mov        rcx, r9
    dec        rcx             ;!
    repe       cmpsb    
    jne        .search

    sub        rsi, r9
    cmp        byte[rsi], 0x22
    jne        .search

    add        rsi, r9
    cmp        byte[rsi], 0x22
    jne        .search         
    cmp        byte[rsi+1], 0x3A
    jne        .error
    cmp        byte[rsi+2], 0x22
    jne        .error

    inc        r14

    cmp        r14, r12
    jne        .search
    
    add        rsi, 3
    xor        rcx, rcx

.search_meaning:
    lodsb
    cmp        al,0x22
    je         .exit  

    mov        byte[r8+rcx], al
    inc        rcx
    jmp        .search_meaning

.exit:
    mov        rax, rcx
    mov        byte[r8+rcx], 0
@@:
    ret
 
.error:    
    xor        rax, rax
    jmp        @b
endp

proc get_self_filehash uses rbx rsi rdi r12 r13 r14 r15, gethash

locals 
    phAlgorithm         dq ?
    hHash               dq ?
    bytesRead           dq ?
    get_ascii_for_hex   rb 68
    bytesRead2          dd ?
    lpbuffer            rb MAX_PATH+1
endl

frame 
    mov        r15, rcx ; gethash

    invoke     GetModuleFileName, NULL, addr lpbuffer, MAX_PATH+1
    invoke     CreateFile, addr lpbuffer, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp        rax, INVALID_HANDLE_VALUE
    je         @f
    mov        rbx, rax

    invoke     GetFileSize, rbx, NULL
    cmp        rax, INVALID_FILE_SIZE
    je         @f
    mov        rdi, rax

    invoke     GlobalAlloc, GPTR, rdi
    test       rax, rax 
    je         @f
    mov        r13, rax
    
    invoke     ReadFile, rbx, r13, rdi, addr bytesRead, NULL 
    test       rax, rax
    je         @f

    cmp        rdi, qword[bytesRead]
    jne        @f

    invoke     BCryptOpenAlgorithmProvider, addr phAlgorithm, BCRYPT_SHA256_ALGORITHM, NULL, 0
    invoke     BCryptCreateHash, qword[phAlgorithm], addr hHash, 0,0, NULL, 0,0

    invoke     BCryptHashData, qword[hHash], r13, rdi, 0

    invoke     BCryptFinishHash, qword[hHash], r15, 32, 0   
    invoke     BCryptDestroyHash, qword[hHash]
    invoke     BCryptCloseAlgorithmProvider, qword[phAlgorithm], 0

    invoke     CryptBinaryToString, r15, 32, CRYPT_STRING_HEXRAW, NULL, addr bytesRead2
    invoke     CryptBinaryToString, r15, 32, CRYPT_STRING_HEXRAW, addr get_ascii_for_hex, addr bytesRead2

    lea        rsi, qword[get_ascii_for_hex]
    xor        rcx, rcx

.buf_to_buf:
    lodsb
    mov        byte[r15+rcx], al
    cmp        rcx, 64
    jge        .next

    inc        rcx
    jmp        .buf_to_buf

.next:
    mov        byte[r15+rcx], 0 ;!

@@:
    invoke     GlobalFree, r13 
    invoke     CloseHandle, rbx
endf
    ret
endp

proc self_delete_prog uses rbx rsi rdi r12

locals
    renameinfo       FILE_RENAME_INFO TRUE, NULL, temp_stream_name.sizeof ; remove
    dispositionInfo  FILE_DISPOSITION_INFO TRUE
    
    lpbuffer         rb MAX_PATH+1
endl

    lea        rsi, qword[temp_stream_name]                    ; also remove
    lea        rdi, qword[renameinfo.FileName]
    mov        ecx, dword[renameinfo.FileNameLength]  
    rep        movsw

frame
    invoke     GetModuleFileNameW, NULL, addr lpbuffer, MAX_PATH+1
    invoke     CreateFileW, addr lpbuffer, DELETE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov        rbx, rax

    invoke     SetFileInformationByHandle, rbx, FileRenameInfo, addr renameinfo, sizeof.FILE_RENAME_INFO
    invoke     CloseHandle, rbx

    invoke     CreateFileW, addr lpbuffer, DELETE, FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL 
    mov        rbx, rax

    invoke     SetFileInformationByHandle, rbx, FileDispositionInfo, addr dispositionInfo, sizeof.FILE_DISPOSITION_INFO
    invoke     CloseHandle, rbx
endf
    ret
endp