proc add_to_startup phkResult, lpdwDisposition

locals
	lpbuffer rb MAX_PATH+1
endl

frame
	invoke  RegCreateKeyEx,HKEY_CURRENT_USER,lpSubKey,0,0,REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,0,addr phkResult,addr lpdwDisposition
	cmp [lpdwDisposition], REG_OPENED_EXISTING_KEY
	je @f

	invoke  MessageBox, 0, lpText, lpValueName, MB_YESNO or MB_ICONQUESTION
	cmp rax, IDNO
	je .answer_was_no

	mov [lpbuffer], 0x22
    invoke  GetModuleFileName, NULL, addr lpbuffer + 1, MAX_PATH+1	
    mov [lpbuffer+rax+1], 0x0022
    mov rsi, rax
    add rsi, 3
    
    invoke  RegSetValueEx, [phkResult], lpValueName, 0, REG_SZ, addr lpbuffer, rsi
@@:    
    invoke  RegCloseKey, [phkResult] 
endf
	ret

.answer_was_no:
	invoke  RegDeleteKey, [phkResult], lpSubKey
	jmp @b

	lpText db 'Do you want to add the program to startup?',0

	lpSubKey db 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run',0
	lpValueName db 'AreaSnap',0
endp