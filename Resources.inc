MAXDPI              = 150
FLAGS_CONTOUR       = 1
FLAGS_BLEEDS        = 2
FLAGS_GROUP         = 4
FLAGS_ONLYOUTER     = 8

macro DLGTEMPLATEEX helpID,exStyle,style,cDlgItems,x,y,cx,cy,_menu,title,pointsize,weight,italic,charset,typeface{
  dd 0xFFFF0001,helpID,exStyle,style
  dw cDlgItems,x,y,cx,cy,_menu,0
  du title,0
  dw pointsize,weight
  db italic,charset
  du typeface,0
}

macro DLGITEMTEMPLATEEX helpID,exStyle,style,x,y,cx,cy,id,class,title{
  align 4
  dd helpID,exStyle,style
  dw x,y,cx,cy
  dd id
  if class eq 'BUTTON'
    dw 0FFFFh,80h
  else if class eq 'EDIT'
    dw 0FFFFh,81h
  else if class eq 'STATIC'
    dw 0FFFFh,82h
  else if class eq 'LISTBOX'
    dw 0FFFFh,83h
  else if class eq 'SCROLLBAR'
    dw 0FFFFh,84h
  else if class eq 'COMBOBOX'
    dw 0FFFFh,85h
  else
    du class,0
  end if
  du title,0
  dw 0
}

align 16
AlphaThresold           dd 240,240,240,240
PixelMask               dd $FF,$FFFF,$FFFFFF,$FFFFFFFF
UltraThin               dq 0.0762
dbl_01                  dq 0.1
dbl_1                   dq 1.0
dbl_15                  dq 1.5

Params:
  .DefImageType         db cdrCMYKColorImage
  .BleedsSize           db 10
  .Smooth               db 25
  .flags                db FLAGS_CONTOUR+FLAGS_BLEEDS+FLAGS_ONLYOUTER

MainDlg:                DLGTEMPLATEEX 0,0,DS_SETFONT+DS_MODALFRAME+DS_CENTER+WS_POPUP+WS_CAPTION+WS_SYSMENU,12,0,0,168,83,0,'',12,FW_NORMAL,0,0,'SEGOE UI'
                        ;encoding macro don`t work here. I don`t know why. So I define unicode-string by hand.
                        Labels equ 0020h,0020h,0020h,0020h,0020h,0421h,0433h,043Bh,0430h,0436h,0438h,0432h,0430h,043Dh,0438h,0435h,000Dh,000Ah,000Dh,000Ah,000Dh,000Ah,0020h,0020h,0020h,0020h,0020h,0428h,0438h,0440h,0438h,043Dh,0430h,000Dh,000Ah,000Dh,000Ah,000Dh,000Ah,0426h,0432h,0435h,0442h,043Eh,0432h,0430h,044Fh,0020h,043Ch,043Eh,0434h,0435h,043Bh,044Ch,0020h,043Fh,043Eh,002Dh,0443h,043Ch,043Eh,043Bh,0447h,0430h,043Dh,0438h,044Eh ;'     Сглаживание',13,10,13,10,13,10,'     Ширина',13,10,13,10,13,10,'Цветовая модель по-умолчанию'
                        DLGITEMTEMPLATEEX 0,0,SS_LEFT+WS_CHILD+WS_VISIBLE+WS_GROUP                      ,4  ,14,108,63,0 ,'STATIC',Labels
                        DLGITEMTEMPLATEEX 0,0,TBS_HORZ+WS_CHILD+WS_VISIBLE+WS_TABSTOP                   ,60 ,14,80 ,12,10,'msctls_trackbar32',''
                        DLGITEMTEMPLATEEX 0,0,SS_LEFT+WS_CHILD+WS_VISIBLE+WS_GROUP                      ,144,13,24 ,10,11,'STATIC',''
                        DLGITEMTEMPLATEEX 0,0,TBS_HORZ+WS_CHILD+WS_VISIBLE+WS_TABSTOP                   ,60 ,38,80 ,12,12,'msctls_trackbar32',''
                        DLGITEMTEMPLATEEX 0,0,SS_LEFT+WS_CHILD+WS_VISIBLE+WS_GROUP                      ,144,37,24 ,10,13,'STATIC',''
                        DLGITEMTEMPLATEEX 0,0,BS_AUTOCHECKBOX+WS_CHILD+WS_VISIBLE+WS_TABSTOP            ,4  , 4,40 ,10,1 ,'BUTTON','Контур'
                        DLGITEMTEMPLATEEX 0,0,BS_AUTOCHECKBOX+WS_CHILD+WS_VISIBLE+WS_TABSTOP            ,4  ,28,40 ,10,2 ,'BUTTON','Припуск'
                        DLGITEMTEMPLATEEX 0,0,BS_AUTOCHECKBOX+WS_CHILD+WS_VISIBLE+WS_TABSTOP            ,3  ,50,101,10,3 ,'BUTTON','Выделение как один объект'
                        DLGITEMTEMPLATEEX 0,0,BS_AUTOCHECKBOX+WS_CHILD+WS_VISIBLE+WS_TABSTOP            ,104,50,101,10,4 ,'BUTTON','Только снаружи'
                        DLGITEMTEMPLATEEX 0,0,BS_AUTORADIOBUTTON+WS_CHILD+WS_VISIBLE+WS_TABSTOP         ,25 ,70,26 ,10,5 ,'BUTTON','RGB'
                        DLGITEMTEMPLATEEX 0,0,BS_AUTORADIOBUTTON+WS_CHILD+WS_VISIBLE+WS_TABSTOP         ,60 ,70,28 ,10,6 ,'BUTTON','CMYK'
                        DLGITEMTEMPLATEEX 0,0,BS_PUSHBUTTON+WS_CHILD+WS_VISIBLE+WS_TABSTOP              ,123,68,30 ,12,9 ,'BUTTON','OK'

strBleeds               OLEstr 'Bleeds'
strStandard             OLEstr 'Standard'
strButtonCaption        OLEstr 'Припуски'
strCut                  OLEstr 'рез'
fmt1                    du '%u',0
fmt2                    du '0.0 мм',0
errCPUNotSupported      du 'Процессор не поддерживается. Требуется SSE 4.1.',0
ICOData                 file 'icon.ico'
sizeof.ICOData=$-ICOData

data import
  library kernel,'KERNEL32.DLL',\
          oleaut,'OLEAUT32.DLL',\
          user,'USER32.DLL',\
          comctl,'COMCTL32.DLL'

  import kernel,\
         CloseHandle,'CloseHandle',\
         CreateFileW,'CreateFileW',\
         GetTempPathW,'GetTempPathW',\
         lstrcmpW,'lstrcmpW',\
         VirtualAlloc,'VirtualAlloc',\
         VirtualFree,'VirtualFree',\
         WriteFile,'WriteFile'

  import user,\
         DialogBoxIndirectParamW,'DialogBoxIndirectParamW',\
         EnableWindow,'EnableWindow',\
         EndDialog,'EndDialog',\
         GetDlgItem,'GetDlgItem',\
         MessageBoxW,'MessageBoxW',\
         SendMessageW,'SendMessageW',\
         SendDlgItemMessageW,'SendDlgItemMessageW',\
         wsprintfW,'wsprintfW'

  import comctl,\
         InitCommonControls,'InitCommonControls'

  import oleaut,\
         SafeArrayCreate,'SafeArrayCreate',\
         SafeArrayDestroy,'SafeArrayDestroy'

end data

data export
 export 0,AttachPlugin,'AttachPlugin'
end data

data fixups
end data