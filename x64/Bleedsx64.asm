format PE64 GUI 4.0 DLL as 'cpg'
entry DllEntryPoint
include 'encoding\win1251.inc'
include 'win64w.inc'
include 'CorelDraw.inc'
include '..\Resources.inc'

prologue@proc equ static_rsp_prologue
epilogue@proc equ static_rsp_epilogue
close@proc equ static_rsp_close

DllEntryPoint: ;hinstDLL,fdwReason,lpvReserved
  mov eax,TRUE
ret

AttachPlugin: ;ppIPlugin: IVGAppPlugin
  mov qword[rcx],IPlugin
  mov eax,256
ret

proc GetImageData uses rdi rsi rbx rbp r12 r13 r14 r15,Image,data
  mov     [data],rdx
  mov     r14d,[ImageWidth]
  inc     r14
  imul    r14d,[BleedsWidth]
  comcall rcx,IVGImage,Get_Tiles,Tiles
  cominvk Tiles,Get_Count,TileCount
  .MainLoop:
    cominvk Tiles,Get_Item,[TileCount],tmp
    mov     rbx,[tmp]
    comcall rbx,IVGImageTile,Get_Left,TileX
    comcall rbx,IVGImageTile,Get_Bottom,TileY
    comcall rbx,IVGImageTile,Get_Width,TileWidth
    comcall rbx,IVGImageTile,Get_Height,TileHeight
    dec     [TileHeight]
    comcall rbx,IVGImageTile,Get_BytesPerPixel,TileBPP
    comcall rbx,IVGImageTile,Get_BytesPerLine,TileBPL
    comcall rbx,IVGImageTile,Get_PixelData,TileData
    comcall rbx,IVGImageTile,Release
    mov     r15d,[TileWidth]
    mov     edx,[TileHeight]
    mov     rdi,[TileData]
    mov     rsi,[data]
    mov     ebp,[TileBPP]
    mov     r12d,[TileBPL]
    mov     rcx,r15
    mov     ebx,dword[PixelMask+ebp*4-4]
    mov     rax,r12
    imul    ecx,ebp
    imul    eax,edx
    sub     r12,rcx
    add     eax,ecx
    mov     rdi,[rdi+SAFEARRAY.pvData]
    add     rdi,rax

    add     edx,[TileY]
    mov     r13d,[ImageWidth]
    dec     edx
    imul    edx,r13d
    sub     r13,r15
    add     rdx,r14
    shl     r13,2
    add     edx,[TileX]
    add     rdx,r15
    lea     rsi,[rsi+rdx*4]

    mov     edx,[TileHeight]
    .Row:mov rcx,r15
         .Col:sub rdi,rbp
              sub rsi,4
              mov eax,[rdi]
              and eax,ebx
              mov [rsi],eax
              dec ecx
         jne .Col
         sub rdi,r12
         sub rsi,r13
         dec edx
    jns .Row
    invoke  SafeArrayDestroy,[TileData]
    dec     [TileCount]
  jne .MainLoop
  cominvk Tiles,Release
ret
endp

proc SetImageData uses rdi rsi rbx rbp r12 r13 r14,Image,data
  mov     [data],rdx
  comcall rcx,IVGImage,Get_Tiles,Tiles
  cominvk Tiles,Get_Count,TileCount
  .MainLoop:
    cominvk Tiles,Get_Item,[TileCount],tmp
    mov     rbp,[tmp]
    comcall rbp,IVGImageTile,Get_Left,TileX
    comcall rbp,IVGImageTile,Get_Bottom,TileY
    comcall rbp,IVGImageTile,Get_Width,TileWidth
    comcall rbp,IVGImageTile,Get_Height,TileHeight
    comcall rbp,IVGImageTile,Get_BytesPerPixel,TileBPP
    comcall rbp,IVGImageTile,Get_BytesPerLine,TileBPL
    mov     ecx,[TileWidth]
    mov     edx,[TileHeight]
    mov     rsi,[data]
    mov     r12d,[TileBPP]
    mov     r14d,[TileBPL]
    mov     ebx,dword[PixelMask+r12*4-4]
    mov     ebp,ebx
    not     ebx
    imul    ecx,r12d
    mov     rax,r14
    imul    eax,edx
    mov     [rgsabound.cElements],eax
    sub     rax,r14
    sub     r14,rcx
    lea     edi,[eax+ecx]
    add     edx,[TileY]
    mov     r13d,[ImageWidth]
    dec     edx
    imul    edx,r13d
    sub     r13d,[TileWidth]
    add     edx,[TileX]
    shl     r13,2
    add     edx,[TileWidth]
    lea     rsi,[rsi+rdx*4]

    invoke  SafeArrayCreate,VT_UI1,1,rgsabound
    mov     [TileData],rax
    add     rdi,[rax+SAFEARRAY.pvData]

    mov     edx,[TileHeight]
    .Row:mov ecx,[TileWidth]
         .Col:sub rdi,r12
              sub rsi,4
              mov eax,[rsi]
              and [rdi],ebx
              and eax,ebp
              or  [rdi],eax
              dec ecx
         jne .Col
         sub rdi,r14
         sub rsi,r13
         dec edx
    jne .Row

    mov     rbp,[tmp]
    comcall rbp,IVGImageTile,Set_PixelData,TileData
    invoke  SafeArrayDestroy,[TileData]
    comcall rbp,IVGImageTile,Release
    dec     [TileCount]
  jne .MainLoop
  cominvk Tiles,Release
ret
endp

proc DialogFunc uses rbx rbp rsi rdi,wnd,msg,wParam,lParam
  mov rsi,rcx
  cmp rdx,WM_HSCROLL
  je .WM_HSCROLL
  cmp rdx,WM_COMMAND
  je .WM_COMMAND
  cmp rdx,WM_INITDIALOG
  je .WM_INITDIALOG
  cmp rdx,WM_CLOSE
  je .WM_CLOSE
    xor eax,eax
  ret
     .WM_HSCROLL:mov    rbx,r9
                 invoke SendMessageW,r9,TBM_GETPOS,0,0
                 cmp    rbx,[SmoothTrack]
                 jne @f
                    cinvoke wsprintfW,buf,fmt1,eax
                    invoke  SendDlgItemMessageW,rsi,11,WM_SETTEXT,0,buf
                    ret
                 @@:
                 mov    ecx,10
                 cdq
                 div    ecx
                 add    al,'0'
                 add    dl,'0'
                 mov    byte[fmt2],al
                 mov    byte[fmt2+4],dl
                 invoke SendDlgItemMessageW,rsi,13,WM_SETTEXT,0,fmt2
                 ret
     .WM_COMMAND:cmp r8w,2
                 ja  @f
                   movzx  rdi,r8w
                   invoke SendMessageW,r9,BM_GETCHECK,0,0
                   mov    ebx,eax
                   lea    eax,[edi+edi+8]
                   invoke GetDlgItem,rsi,eax
                   invoke EnableWindow,rax,ebx
                   lea    eax,[edi+edi+9]
                   invoke GetDlgItem,rsi,eax
                   invoke EnableWindow,rax,ebx
                   ret
                 @@:
                 cmp r8w,9
                 jne .quit
                   movdqa dqword[buf],xmm6
                   mov    [wnd],rsi
                   xor    ebx,ebx
                   mov    ebp,4
                   @@:add    ebx,ebx
                      invoke SendDlgItemMessageW,rsi,ebp,BM_GETCHECK,0,0
                      add    ebx,eax
                      dec    ebp
                   jne @b
                   invoke  SendDlgItemMessageW,rsi,6,BM_GETCHECK,0,0
                   mov     edx,5
                   cmp     eax,1
                   mov     [Params.flags],bl
                   sbb     edx,0
                   mov     [Params.DefImageType],dl
                   invoke  SendMessageW,[SmoothTrack],TBM_GETPOS,0,0
                   mov     [Params.Smooth],al
                   invoke  SendMessageW,[BleedsTrack],TBM_GETPOS,0,0
                   mov     [Params.BleedsSize],al

                   cominvk CorelApp,Get_ActiveDocument,CorelDoc
                   mov     rsi,[CorelDoc]
                   comcall rsi,IVGDocument,BeginCommandGroup,strBleeds
                   comcall rsi,IVGDocument,Set_Unit,cdrMillimeter
                   comcall rsi,IVGDocument,Get_ActiveLayer,ActiveLayer
                   comcall rsi,IVGDocument,Get_ActivePage,tmp
                   mov     rbx,[tmp]
                   comcall rbx,IVGPage,Get_Layers,tmp
                   mov     rbp,[tmp]
                   mov     [ContourLayer],0
                   comcall rbp,IVGLayers,Find,strCut,ContourLayer
                   comcall rbp,IVGLayers,Release
                   cmp     [ContourLayer],0
                   jne @f
                     comcall rbx,IVGPage,CreateLayer,strCut,ContourLayer
                   @@:
                   comcall rbx,IVGPage,Release
                   cominvk ActiveLayer,Activate
                   comcall rsi,IVGDocument,Get_SelectionRange,Selection

                   test    [Params.flags],FLAGS_GROUP
                   je @f
                     cominvk Selection,Group,Shape
                     cominvk Selection,RemoveAll
                     cominvk Selection,Add,[Shape]
                     cominvk Shape,Release
                   @@:

                   cominvk Selection,Get_Count,ShapesCount
                   .MainLoop:
                     mov     eax,[ShapesCount]
                     mov     [tmpVariant.data],rax
                     cominvk Selection,Get_Item,tmpVariant,Shape
                     cominvk Shape,GetSize,ShapeWidth,ShapeHeight
                     cominvk Shape,GetPosition,ShapeX,ShapeY
                     movsd   xmm0,[ShapeY]
                     subsd   xmm0,[ShapeHeight]
                     movsd   [ShapeY],xmm0

               ;Rasterize item
                     cominvk Shape,Duplicate,0.0,0.0,tmp
                     mov     rbx,[tmp]
                     comcall rbx,IVGShape,Get_type,tmp
                     cmp     dword[tmp],cdrBitmapShape
                     je .Bimmap
                       movzx   rdx,[Params.DefImageType]
                       comcall rbx,IVGShape,ConvertToBitmapEx,rdx,0,1,MAXDPI,cdrNoAntiAliasing,1,0,0,tmp
                       comcall rbx,IVGShape,Release
                       mov     rbx,[tmp]
                     jmp .Shape
                     .Bimmap:
                       comcall rbx,IVGShape,Get_Bitmap,tmp
                       mov     rbp,[tmp]
                       comcall rbp,IVGBitmap,Get_ResolutionX,tmp
                       mov     esi,MAXDPI
                       mov     edi,MAXDPI
                       sub     esi,dword[tmp]
                       cmovg   edi,dword[tmp]
                       cominvk Shape,Get_RotationAngle,tmp
                       movsd   xmm6,[tmp]
                       comcall rbp,IVGBitmap,Get_Mode,tmp
                       mov     edx,dword[tmp]
                       mov     ecx,not 110100b             ;inverse bitset of cdrGrayscaleImage,cdrRGBColorImage,cdrCMYKColorImage
                       movzx   eax,[Params.DefImageType]
                       bt      ecx,edx
                       cmovc   edx,eax
                       sbb     eax,eax
                       or      esi,eax
                       ptest   xmm6,xmm6
                       setz    al                          ;eax should be zero (S_OK) after Get_Mode calling
                       dec     eax
                       or      esi,eax   ;if (ShapeRotationAngle<>0)or(not (Shape.Bitmap.mode in [cdrGrayscaleImage,cdrRGBColorImage,cdrCMYKColorImage]))or(Shape.Bitmap.ResolutionX>MAXDPI) then
                       jns @f
                         comcall rbx,IVGShape,ConvertToBitmapEx,rdx,0,1,edi,cdrNoAntiAliasing,1,0,0,tmp
                         comcall rbx,IVGShape,Release
                         mov     rbx,[tmp]
                       @@:
                       comcall rbp,IVGBitmap,Release
                     .Shape:

                     comcall  rbx,IVGShape,Get_Bitmap,tmp
                     mov      rbp,[tmp]
                     comcall  rbp,IVGBitmap,Get_Image,tmp
                     mov      rsi,[tmp]
                     comcall  rbp,IVGBitmap,Get_ImageAlpha,tmp
                     mov      rdi,[tmp]
                     comcall  rbp,IVGBitmap,Release

               ;calculate bleeds width in pixels and new image size with bleeds
                     comcall  rsi,IVGImage,Get_type,ImageType
                     comcall  rsi,IVGImage,Get_Width,ImageWidth
                     comcall  rsi,IVGImage,Get_Height,ImageHeight
                     movzx    eax,[Params.BleedsSize]
                     cvtsi2sd xmm0,[ImageWidth]
                     cvtsi2sd xmm1,eax
                     movsd    xmm2,[dbl_1]
                     divsd    xmm0,[ShapeWidth]
                     mulsd    xmm1,[dbl_01]
                     movsd    [dpi],xmm0
                     mulsd    xmm0,xmm1
                     divsd    xmm2,xmm1
                     movsd    [dpircp],xmm2
                     addsd    xmm0,[dbl_15] ;+1.5
                     addsd    xmm1,xmm2
                     cvtsd2si eax,xmm0
                     movsd    [BleedsSize],xmm1
                     shufpd   xmm1,xmm1,0
                     movapd   xmm0,dqword[ShapeX]
                     movapd   xmm3,dqword[ShapeWidth]
                     mov      [BleedsWidth],eax
                     add      eax,eax
                     subpd    xmm0,xmm1
                     add      [ImageWidth],eax
                     add      [ImageHeight],eax
                     mov      eax,[ImageWidth]
                     movapd   dqword[ShapeX],xmm0
                     mul      [ImageHeight]
                     addpd    xmm1,xmm1
                     shl      eax,2
                     addpd    xmm3,xmm1
                     mov      [ImageSize],eax
                     movapd   dqword[ShapeWidth],xmm3

               ;Get pixel data from image
                     invoke   VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
                     mov      [Alpha2],rax
                     stdcall  GetImageData,rdi,rax
                     comcall  rdi,IVGImage,Release
                     invoke   VirtualAlloc,0,[ImageSize],MEM_COMMIT,PAGE_READWRITE
                     mov      [Color2],rax
                     stdcall  GetImageData,rsi,rax
                     comcall  rsi,IVGImage,Release
                     comcall  rbx,IVGShape,Delete
                     comcall  rbx,IVGShape,Release

               ;Alpha channel thresolding
                     mov    ecx,[ImageSize]
                     add    ecx,15
                     and    ecx,-16
                     mov    rax,[Alpha2]
                     movdqu xmm1,dqword[AlphaThresold]
                     @@:sub     ecx,16
                        movdqa  xmm0,[rax+rcx]
                        pcmpgtd xmm0,xmm1
                        movdqa  [rax+rcx],xmm0
                     jne @b

               ;Contour and backplate
                     cominvk  CorelDoc,CreateImage,[ImageType],[ImageWidth],[ImageHeight],0,Image
                     test     [Params.flags],FLAGS_CONTOUR+FLAGS_ONLYOUTER
                     je .Bleeds
                       stdcall SetImageData,[Image],[Alpha2]
                       cominvk ActiveLayer,CreateBitmap2,float[ShapeX],float[ShapeY],float[ShapeWidth],float[ShapeHeight],[Image],0,tmp
                       mov     rbx,[tmp]
                       comcall rbx,IVGShape,Get_Bitmap,tmp
                       comcall rbx,IVGShape,Release
                       mov     rbx,[tmp]
                       movzx   r8d,[Params.Smooth]
                       comcall rbx,IVGBitmap,Trace,cdrTraceDetailedLogo,r8,100,cdrColorBlackAndWhite,cdrCustom,2,1,1,1,tmp
                       comcall rbx,IVGBitmap,Release
                       mov     rbx,[tmp]
                       comcall rbx,IVGTraceSettings,Finish,tmp
                       comcall rbx,IVGTraceSettings,Release
                       mov     rbx,[tmp]
                       mov     [tmp],0
                       comcall rbx,IVGShapeRange,Combine,tmp
                       comcall rbx,IVGShapeRange,Release
                       mov     rbx,[tmp]
                       test    rbx,rbx ;if user cancelate tracing
                       je      .cancel
                       test    [Params.flags],FLAGS_ONLYOUTER
                       je .NoBackPlate
                         comcall rbx,IVGShape,BreakApartEx,tmp
                         comcall rbx,IVGShape,Release
                         mov     rbp,[tmp]
                         comcall rbp,IVGShapeRange,Get_LastShape,tmp
                         mov     rbx,[tmp]
                         comcall rbp,IVGShapeRange,Get_Count,tmp
                         mov     rsi,[tmp]
                         jmp     .start
                         @@:mov     [tmpVariant.data],rsi
                            comcall rbp,IVGShapeRange,Get_Item,tmpVariant,tmp
                            mov     rdi,[tmp]
                            comcall rbx,IVGShape,Weld,rdi,0,0,tmp
                            comcall rbx,IVGShape,Release
                            comcall rdi,IVGShape,Release
                            mov     rbx,[tmp]
                            .start:
                            dec     esi
                         jne @b
                         comcall rbp,IVGShapeRange,Release
                         cominvk CorelApp,CreateCMYKColor,0,0,0,0,tmp
                         mov     rsi,[tmp]
                         comcall rbx,IVGShape,CreateContour,cdrContourInside,float[dpircp],1,cdrDirectFountainFillBlend,0,rsi,0,0,0,cdrContourSquareCap,cdrContourCornerMiteredOffsetBevel,15.0,tmp ;MiterLimit=15.0
                         comcall rbx,IVGShape,Release
                         comcall rsi,IVGColor,Release
                         mov     rbp,[tmp]
                         comcall rbp,IVGEffect,Separate,tmp
                         comcall rbp,IVGEffect,Release
                         mov     rbp,[tmp]
                         comcall rbp,IVGShapeRange,Get_LastShape,tmp
                         mov     rbx,[tmp]
                         comcall rbp,IVGShapeRange,Get_FirstShape,tmp
                         mov     rsi,[tmp]
                         comcall rsi,IVGShape,OrderBackOf,[Shape]
                         cominvk Shape,Release
                         mov     [Shape],rsi
                         comcall rbp,IVGShapeRange,Release
                       .NoBackPlate:
                       comcall rbx,IVGShape,Get_Fill,tmp
                       mov     rbp,[tmp]
                       comcall rbp,IVGFill,ApplyNoFill
                       comcall rbp,IVGFill,Release
                       comcall rbx,IVGShape,Get_Outline,tmp
                       mov     rbp,[tmp]
                       comcall rbp,IVGOutline,Set_Width,float[UltraThin]
                       comcall rbp,IVGOutline,Release
                       comcall rbx,IVGShape,MoveToLayer,[ContourLayer]
                       test    [Params.flags],FLAGS_CONTOUR
                       jne @f
                         comcall rbx,IVGShape,Delete
                       @@:
                       comcall rbx,IVGShape,Release
                     .Bleeds:

               ;Bleeds creation
                     test     [Params.flags],FLAGS_BLEEDS
                     je .NoBleeds
                          invoke VirtualAlloc,0,[ImageSize],MEM_COMMIT,PAGE_READWRITE
                          mov    [Alpha],rax
                          invoke VirtualAlloc,0,[ImageSize],MEM_COMMIT,PAGE_READWRITE
                          mov    [Color],rax
                          mov    r8d,[BleedsWidth]
                          dec    r8
                          mov    edx,[ImageWidth]
                          jmp .Start
                          .Pass:
                            mov   r9d,[ImageHeight]
                            sub   r9,2
                            .Row:
                              lea   ecx,[edx-2]
                              .Col:
                                add rsi,4
                                add rdi,4
                                add rbx,4
                                add rbp,4
                                cmp dword[rdi+rdx*4],0
                                jne @f
                                  mov   eax,[rdi-4]
                                  add   eax,[rdi]
                                  add   eax,[rdi+4]
                                  add   eax,[rdi+rdx*4-4]
                                  add   eax,[rdi+rdx*4]
                                  add   eax,[rdi+rdx*4+4]
                                  add   eax,[rdi+rdx*8-4]
                                  add   eax,[rdi+rdx*8]
                                  add   eax,[rdi+rdx*8+4]
                                  je @f
                                    movd      xmm0,[rsi-4]
                                    movd      xmm2,[rsi]
                                    movd      xmm3,[rsi+4]
                                    movd      xmm4,[rdi-4]
                                    movd      xmm5,[rdi]
                                    movd      xmm6,[rdi+4]
                                    punpcklbw xmm0,xmm0
                                    punpcklbw xmm2,xmm2
                                    punpcklbw xmm3,xmm3
                                    shufps    xmm4,xmm4,0
                                    shufps    xmm5,xmm5,0
                                    shufps    xmm6,xmm6,0
                                    punpcklwd xmm0,xmm0
                                    punpcklwd xmm2,xmm2
                                    punpcklwd xmm3,xmm3
                                    psrld     xmm0,24
                                    psrld     xmm2,24
                                    psrld     xmm3,24
                                    pmulld    xmm0,xmm4
                                    pmulld    xmm2,xmm5
                                    pmulld    xmm3,xmm6
                                    paddd     xmm0,xmm2
                                    paddd     xmm0,xmm3

                                    movd      xmm1,[rsi+rdx*4-4]
                                    movd      xmm2,[rsi+rdx*4]
                                    movd      xmm3,[rsi+rdx*4+4]
                                    movd      xmm4,[rdi+rdx*4-4]
                                    movd      xmm5,[rdi+rdx*4]
                                    movd      xmm6,[rdi+rdx*4+4]
                                    punpcklbw xmm1,xmm1
                                    punpcklbw xmm2,xmm2
                                    punpcklbw xmm3,xmm3
                                    shufps    xmm4,xmm4,0
                                    shufps    xmm5,xmm5,0
                                    shufps    xmm6,xmm6,0
                                    punpcklwd xmm1,xmm1
                                    punpcklwd xmm2,xmm2
                                    punpcklwd xmm3,xmm3
                                    psrld     xmm1,24
                                    psrld     xmm2,24
                                    psrld     xmm3,24
                                    pmulld    xmm1,xmm4
                                    pmulld    xmm2,xmm5
                                    pmulld    xmm3,xmm6
                                    paddd     xmm0,xmm1
                                    paddd     xmm0,xmm2
                                    paddd     xmm0,xmm3

                                    movd      xmm1,[rsi+rdx*8-4]
                                    movd      xmm2,[rsi+rdx*8]
                                    movd      xmm3,[rsi+rdx*8+4]
                                    movd      xmm4,[rdi+rdx*8-4]
                                    movd      xmm5,[rdi+rdx*8]
                                    movd      xmm6,[rdi+rdx*8+4]
                                    punpcklbw xmm1,xmm1
                                    punpcklbw xmm2,xmm2
                                    punpcklbw xmm3,xmm3
                                    shufps    xmm4,xmm4,0
                                    shufps    xmm5,xmm5,0
                                    shufps    xmm6,xmm6,0
                                    punpcklwd xmm1,xmm1
                                    punpcklwd xmm2,xmm2
                                    punpcklwd xmm3,xmm3
                                    psrld     xmm1,24
                                    psrld     xmm2,24
                                    psrld     xmm3,24
                                    pmulld    xmm1,xmm4
                                    pmulld    xmm2,xmm5
                                    pmulld    xmm3,xmm6
                                    paddd     xmm0,xmm1
                                    paddd     xmm0,xmm2
                                    paddd     xmm0,xmm3

                                    cvtdq2ps  xmm0,xmm0
                                    cvtsi2ss  xmm1,eax
                                    shufps    xmm1,xmm1,0
                                    divps     xmm0,xmm1
                                    cvtps2dq  xmm0,xmm0
                                    packssdw  xmm0,xmm0
                                    packuswb  xmm0,xmm0
                                    mov       dword[rbx+rdx*4],255
                                    movd      [rbp+rdx*4],xmm0
                                  @@:
                                  dec ecx
                                jne .Col
                                add rsi,8
                                add rdi,8
                                add rbx,8
                                add rbp,8
                                dec r9
                              jne .Row
                              .Start:
                              mov   rdi,[Alpha]
                              mov   rsi,[Color]
                              mov   rbx,[Alpha2]
                              mov   rbp,[Color2]
                              mov   ecx,[ImageSize]
                              add   ecx,15
                              and   ecx,-16
                              @@:sub    ecx,16
                                 movdqa xmm0,[rbx+rcx]
                                 movdqa xmm1,[rbp+rcx]
                                 movdqa [rdi+rcx],xmm0
                                 movdqa [rsi+rcx],xmm1
                              jne @b
                              dec r8
                          jns .Pass

                          stdcall SetImageData,[Image],[Color]
                          cominvk CorelDoc,CreateImage,cdrGrayscaleImage,[ImageWidth],[ImageHeight],0,tmp
                          mov     rsi,[tmp]
                          stdcall SetImageData,rsi,[Alpha]
                          cominvk ActiveLayer,CreateBitmap2,float[ShapeX],float[ShapeY],float[ShapeWidth],float[ShapeHeight],[Image],rsi,tmp
                          mov     rbx,[tmp]
                          comcall rbx,IVGShape,OrderBackOf,[Shape]
                          comcall rbx,IVGShape,Release
                          comcall rsi,IVGImage,Release
                          .cancel:
                          invoke  VirtualFree,[Alpha],0,MEM_RELEASE
                          invoke  VirtualFree,[Color],0,MEM_RELEASE
                     .NoBleeds:

                     cominvk  Image,Release
                     cominvk  Shape,Release
                     invoke   VirtualFree,[Alpha2],0,MEM_RELEASE
                     invoke   VirtualFree,[Color2],0,MEM_RELEASE
                     dec      [ShapesCount]
                   jne .MainLoop
                   cominvk CorelDoc,EndCommandGroup
                   cominvk Selection,Release
                   cominvk ActiveLayer,Release
                   cominvk ContourLayer,Release
                   cominvk CorelDoc,Release
                   mov     rsi,[wnd]
                   movdqa  xmm6,dqword[buf]
       .WM_CLOSE:mov     eax,[Params]
                 mov     [tmpVariant.data],rax
                 cominvk UserData,Set_Item,strBleeds,0,tmpVariant
                 cominvk UserData,Release
                 invoke  EndDialog,rsi,0
           .quit:ret
  .WM_INITDIALOG:cominvk CorelApp,Get_GlobalUserData,UserData
                 mov     dword[tmpVariant.type],0
                 cominvk UserData,Get_Item,strBleeds,0,tmpVariant
                 cmp     dword[tmpVariant.type],VT_I4
                 jne @f
                   mov eax,dword[tmpVariant.data]
                   mov [Params],eax
                 @@:
                 mov     [tmpVariant.type],VT_I4

                 movzx ebx,[Params.flags]
                 mov   ebp,4
                 shl   ebx,28
                 @@:add    ebx,ebx
                    sbb    eax,eax
                    invoke SendDlgItemMessageW,rsi,ebp,BM_SETCHECK,eax,0
                    dec    ebp
                 jne @b
                 invoke  GetDlgItem,rsi,10
                 mov     [SmoothTrack],rax
                 mov     rbx,rax
                 invoke  SendMessageW,rbx,TBM_SETRANGE,0,100 shl 16
                 movzx   eax,[Params.Smooth]
                 invoke  SendMessageW,rbx,TBM_SETPOS,1,eax
                 movzx   eax,[Params.Smooth]
                 shl     eax,16
                 stdcall DialogFunc,rsi,WM_HSCROLL,eax,rbx
                 invoke  GetDlgItem,rsi,1
                 stdcall DialogFunc,rsi,WM_COMMAND,1,rax

                 invoke  GetDlgItem,rsi,12
                 mov     [BleedsTrack],rax
                 mov     rbx,rax
                 invoke  SendMessageW,rbx,TBM_SETRANGE,0,50 shl 16+1
                 movzx   eax,[Params.BleedsSize]
                 invoke  SendMessageW,rbx,TBM_SETPOS,1,eax
                 movzx   eax,[Params.BleedsSize]
                 shl     eax,16
                 stdcall DialogFunc,rsi,WM_HSCROLL,eax,rbx
                 invoke  GetDlgItem,rsi,2
                 stdcall DialogFunc,rsi,WM_COMMAND,2,rax

                 movzx   eax,[Params.DefImageType]
                 inc     eax
                 invoke  SendDlgItemMessageW,rsi,eax,BM_SETCHECK,1,0
                 mov     eax,1
                 ret
endp

QueryInterface:   ;(const self:IVGAppPlugin; const IID: TGUID; out Obj): HResult; stdcall;
  mov qword[r8],IPlugin
AddRef:           ;(const self:IVGAppPlugin):Integer; stdcall;
Release:          ;(const self:IVGAppPlugin):Integer; stdcall;
  xor eax,eax
ret
GetTypeInfoCount: ;(const self:IVGAppPlugin; out Count: Integer): HResult; stdcall;
GetTypeInfo:      ;(const self:IVGAppPlugin; Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
GetIDsOfNames:    ; this,IID,Names,NameCount,LocaleID,DispIDs
  mov eax,E_NOTIMPL
ret

proc Invoke this,DispID,IID,LocaleID,Flags,Params,VarResult,ExcepInfo,ArgErr
  cmp edx,OnSelectionChange
  je .OnSelectionChange
  cmp edx,OnPluginCommand
  je .OnPluginCommand
  cmp edx,OnUpdatePluginCommand
  je .OnUpdatePluginCommand
  xor eax,eax
  ret
      .OnSelectionChange:cominvk CorelApp,Get_ActiveSelectionRange,Selection
                         test    eax,eax
                         jne @f
                           cominvk Selection,Get_Count,Enabled
                           cominvk Selection,Release
                         @@:
                         xor     eax,eax
                         ret
        .OnPluginCommand:mov    rax,[Params]
                         mov    rax,[rax+DISPPARAMS.rgvarg]
                         invoke lstrcmpW,[rax+VARIANT.data],strBleeds
                         test   eax,eax
                         jne    @f
                           cominvk CorelApp,Get_ActiveWindow,CorelWnd
                           cominvk CorelWnd,Get_Handle,CorelWndHandle
                           cominvk CorelWnd,Release
                           invoke  DialogBoxIndirectParamW,0,MainDlg,[CorelWndHandle],DialogFunc,0
                           cominvk CorelApp,Refresh
                         @@:
                         xor     eax,eax
                         ret
  .OnUpdatePluginCommand:xchg   rbx,[Params]
                         mov    rbx,[rbx+DISPPARAMS.rgvarg]
                         invoke lstrcmpW,[rbx+sizeof.VARIANT*2+VARIANT.data],strBleeds
                         test   eax,eax
                         jne    @f
                           mov rax,[rbx+sizeof.VARIANT*1+VARIANT.data]
                           mov edx,[Enabled]
                           mov [rax],dx
                         @@:
                         mov    rbx,[Params]
                         xor    eax,eax
                         ret
endp

proc OnLoad ;(const self:IVGAppPlugin; const _Application: IVGApplication):LongInt;stdcall;
  mov     [CorelApp],rdx
  comcall rdx,IVGApplication,AddRef
ret
endp

proc StartSession uses rbx rsi     ;(const self:IVGAppPlugin):LongInt;stdcall;
  mov     eax,1
  cpuid
  test    ecx,1 shl 19 ;SSE 4.1
  je .CPUNotSupported
    mov     rbx,[CorelApp]
    comcall rbx,IVGApplication,AddPluginCommand,strBleeds,strButtonCaption,strButtonCaption,buf
    comcall rbx,IVGApplication,AdviseEvents,IPlugin,EventsCookie
    comcall rbx,IVGApplication,Get_CommandBars,tmp
    mov     rbx,[tmp]
    mov     [tmp],0
    mov     [tmpVariant.type],VT_BSTR
    mov     [tmpVariant.data],strBleeds
    comcall rbx,ICUICommandBars,Get_Item,tmpVariant,tmp
    cmp     [tmp],0
    jne @f
      comcall rbx,ICUICommandBars,Add,strBleeds,cuiBarTop,0,tmp
    @@:
    comcall rbx,ICUICommandBars,Release
    mov     rbx,[tmp]
    comcall rbx,ICUICommandBar,Set_Visible,1
    comcall rbx,ICUICommandBar,Get_Controls,tmp
    comcall rbx,ICUICommandBar,Release
    mov     rbx,[tmp]
    comcall rbx,ICUIControls,AddCustomButton,cdrCmdCategoryPlugins,strBleeds,1,0,tmp
    comcall rbx,ICUIControls,Release
    mov     rbx,[tmp]
    invoke  GetTempPathW,bufsize/2,buf+4
    lea     eax,[eax*2+strBleeds.size]
    mov     dword[buf],eax
    movdqu  xmm0,dqword[strBleeds]
    movdqu  dqword[buf+4+rax-strBleeds.size],xmm0
    invoke  CreateFileW,buf+4,GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
    mov     rsi,rax
    invoke  WriteFile,rax,ICOData,sizeof.ICOData,tmp,0
    invoke  CloseHandle,rsi
    comcall rbx,ICUIControl,SetIcon2,buf+4
    comcall rbx,ICUIControl,Release
    xor     eax,eax
    ret
  .CPUNotSupported:
  invoke MessageBoxW,[CorelWndHandle],errCPUNotSupported,strBleeds,MB_TASKMODAL
  mov    eax,E_FAIL
ret
endp

proc StopSession      ;(const self:IVGAppPlugin):LongInt;stdcall;
  cominvk CorelApp,UnadviseEvents,[EventsCookie]
  xor     eax,eax
ret
endp

proc OnUnload         ;(const self:IVGAppPlugin)LongInt;stdcall;
  cominvk CorelApp,Release
  xor     eax,eax
ret
endp

align 8
IPlugin           dq IPluginVMT
IPluginVMT        dq QueryInterface,\
                     AddRef,\
                     Release,\
                     GetTypeInfoCount,\
                     GetTypeInfo,\
                     GetIDsOfNames,\
                     Invoke,\
                     OnLoad,\
                     StartSession,\
                     StopSession,\
                     OnUnload

align 16
buf               rb 1024
bufsize=$-buf
ShapeWidth        rq 1
ShapeHeight       rq 1
ShapeX            rq 1
ShapeY            rq 1
dpi               rq 1
dpircp            rq 1
BleedsSize        rq 1
tmpVariant        VARIANT
CorelApp          IVGApplication
CorelDoc          IVGDocument
ActiveLayer       IVGLayer
ContourLayer      IVGLayer
Shape             IVGShape
Tiles             IVGImageTiles
Image             IVGImage
Selection         IVGShapeRange
UserData          IVGProperties
CorelWnd          IVGWindow
TileData          rq 1
CorelWndHandle    rq 1
Color             rq 1
Alpha             rq 1
Color2            rq 1
Alpha2            rq 1
tmp               rq 1
SmoothTrack       rq 1
BleedsTrack       rq 1
EventsCookie      rd 1
ShapesCount       rd 1
ImageType         rd 1
ImageWidth        rd 1
ImageHeight       rd 1
ImageSize         rd 1
BleedsWidth       rd 1
TileCount         rd 1
TileX             rd 1
TileY             rd 1
TileWidth         rd 1
TileHeight        rd 1
TileBPP           rd 1
TileBPL           rd 1
Enabled           rd 1
rgsabound         SAFEARRAYBOUND