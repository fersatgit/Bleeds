format PE GUI 4.0 DLL as 'cpg'
entry DllEntryPoint
include 'encoding\win1251.inc'
include 'win32w.inc'
include 'CorelDraw.inc'
include '..\Resources.inc'

align 16
DllEntryPoint: ;hinstDLL,fdwReason,lpvReserved
  mov eax,TRUE
ret 12

AttachPlugin: ;ppIPlugin: IVGAppPlugin
  mov eax,[esp+4]
  mov dword[eax],IPlugin
  mov eax,256
ret 4

GetImageData: ;(const Image: IVGImage; data: pointer);
  pushad
  mov     eax,[ImageWidth]
  inc     eax
  mul     [BleedsWidth]
  mov     [TileStart],eax
  mov     eax,[esp+36]
  comcall eax,IVGImage,Get_Tiles,Tiles
  cominvk Tiles,Get_Count,TileCount
  .MainLoop:
    cominvk Tiles,Get_Item,[TileCount],tmp
    mov     ebx,[tmp]
    comcall ebx,IVGImageTile,Get_Left,TileX
    comcall ebx,IVGImageTile,Get_Bottom,TileY
    comcall ebx,IVGImageTile,Get_Width,TileWidth
    comcall ebx,IVGImageTile,Get_Height,TileHeight
    dec     [TileHeight]
    comcall ebx,IVGImageTile,Get_BytesPerPixel,TileBPP
    comcall ebx,IVGImageTile,Get_BytesPerLine,TileBPL
    comcall ebx,IVGImageTile,Get_PixelData,TileData
    comcall ebx,IVGImageTile,Release
    mov     ebp,[TileBPP]
    mov     ecx,[TileWidth]
    mov     edx,[TileHeight]
    mov     edi,[TileData]
    mov     esi,[esp+40]
    mov     ebx,dword[PixelMask+ebp*4-4]
    imul    ecx,ebp
    mov     eax,[TileBPL]
    imul    eax,edx
    add     eax,ecx
    mov     edi,[edi+SAFEARRAY.pvData]
    add     edi,eax

    add     edx,[TileY]
    mov     eax,[ImageWidth]
    dec     edx
    imul    edx,eax
    sub     eax,[TileWidth]
    add     edx,[TileX]
    shl     eax,2
    add     edx,[TileWidth]
    add     edx,[TileStart]
    mov     [esp-4],eax
    lea     esi,[esi+edx*4]

    mov     eax,[TileBPL]
    sub     eax,ecx
    mov     [esp-8],eax

    mov     edx,[TileHeight]
    .Row:mov ecx,[TileWidth]
         .Col:sub edi,ebp
              sub esi,4
              mov eax,[edi]
              and eax,ebx
              mov [esi],eax
              dec ecx
         jne .Col
         sub edi,[esp-8]
         sub esi,[esp-4]
         dec edx
    jns .Row
    invoke  SafeArrayDestroy,[TileData]
    dec     [TileCount]
  jne .MainLoop
  cominvk Tiles,Release
  popad
ret 8

SetImageData: ;(const Image: IVGImage; data: pointer);
  pushad
  mov     eax,[esp+36]
  comcall eax,IVGImage,Get_Tiles,Tiles
  cominvk Tiles,Get_Count,TileCount
  .MainLoop:
    cominvk Tiles,Get_Item,[TileCount],tmp
    mov     ebp,[tmp]
    comcall ebp,IVGImageTile,Get_Left,TileX
    comcall ebp,IVGImageTile,Get_Bottom,TileY
    comcall ebp,IVGImageTile,Get_Width,TileWidth
    comcall ebp,IVGImageTile,Get_Height,TileHeight
    comcall ebp,IVGImageTile,Get_BytesPerPixel,TileBPP
    comcall ebp,IVGImageTile,Get_BytesPerLine,TileBPL
    mov     ecx,[TileWidth]
    mov     edx,[TileHeight]
    mov     edi,[TileData]
    mov     esi,[esp+40]
    mov     eax,[TileBPP]
    mov     ebx,dword[PixelMask+eax*4-4]
    mov     ebp,ebx
    not     ebx
    imul    ecx,eax
    mov     eax,[TileBPL]
    imul    eax,edx
    mov     [rgsabound.cElements],eax

    sub     eax,[TileBPL]
    lea     edi,[eax+ecx]

    add     edx,[TileY]
    mov     eax,[ImageWidth]
    dec     edx
    imul    edx,eax
    sub     eax,[TileWidth]
    add     edx,[TileX]
    shl     eax,2
    add     edx,[TileWidth]
    push    eax
    lea     esi,[esi+edx*4]

    mov     eax,[TileBPL]
    sub     eax,ecx
    push    eax

    invoke  SafeArrayCreate,VT_UI1,1,rgsabound
    mov     [TileData],eax
    add     edi,[eax+SAFEARRAY.pvData]
    add     esp,8

    mov     edx,[TileHeight]
    .Row:mov ecx,[TileWidth]
         .Col:sub edi,[TileBPP]
              sub esi,4
              mov eax,[esi]
              and [edi],ebx
              and eax,ebp
              or  [edi],eax
              dec ecx
         jne .Col
         sub edi,[esp-8]
         sub esi,[esp-4]
         dec edx
    jne .Row

    mov     ebp,[tmp]
    comcall ebp,IVGImageTile,Set_PixelData,TileData
    invoke  SafeArrayDestroy,[TileData]
    comcall ebp,IVGImageTile,Release
    dec     [TileCount]
  jne .MainLoop
  cominvk Tiles,Release
  popad
ret 8

DialogFunc: ;(wnd,msg,wParam,lParam: dword):dword;stdcall;
  cmp dword[esp+8],WM_HSCROLL
  je .WM_HSCROLL
  cmp dword[esp+8],WM_COMMAND
  je .WM_COMMAND
  cmp dword[esp+8],WM_INITDIALOG
  je .WM_INITDIALOG
  cmp dword[esp+8],WM_CLOSE
  je .WM_CLOSE
    xor eax,eax
  ret 16
     .WM_HSCROLL:invoke SendMessageW,dword[esp+28],TBM_GETPOS,0,0
                 mov    edx,[esp+16]
                 cmp    edx,[SmoothTrack]
                 jne @f
                    cinvoke wsprintfW,buf,fmt1,eax
                    invoke  SendDlgItemMessageW,dword[esp+20],11,WM_SETTEXT,0,buf
                    ret     16
                 @@:
                 aam
                 add    ax,'00'
                 mov    byte[fmt2],ah
                 mov    byte[fmt2+4],al
                 invoke SendDlgItemMessageW,dword[esp+20],13,WM_SETTEXT,0,fmt2
                 ret     16
     .WM_COMMAND:cmp word[esp+12],2
                 ja  @f
                   push   ebx
                   invoke SendMessageW,dword[esp+32],BM_GETCHECK,0,0
                   mov    ebx,eax
                   movzx  eax,word[esp+16]
                   lea    eax,[eax+eax+8]
                   invoke GetDlgItem,dword[esp+12],eax
                   invoke EnableWindow,eax,ebx
                   movzx  eax,word[esp+16]
                   lea    eax,[eax+eax+9]
                   invoke GetDlgItem,dword[esp+12],eax
                   invoke EnableWindow,eax,ebx
                   pop    ebx
                   ret    16
                 @@:
                 cmp word[esp+12],9
                 jne .quit
                   pushad
                   xor ebx,ebx
                   mov ebp,4
                   @@:add    ebx,ebx
                      invoke SendDlgItemMessageW,dword[esp+52],ebp,BM_GETCHECK,0,0
                      add    ebx,eax
                      dec    ebp
                   jne @b
                   invoke  SendDlgItemMessageW,dword[esp+52],6,BM_GETCHECK,0,0
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
                   mov     esi,[CorelDoc]
                   comcall esi,IVGDocument,BeginCommandGroup,strBleeds
                   comcall esi,IVGDocument,Set_Unit,cdrMillimeter
                   comcall esi,IVGDocument,Get_ActiveLayer,ActiveLayer
                   comcall esi,IVGDocument,Get_ActivePage,tmp
                   mov     ebx,[tmp]
                   comcall ebx,IVGPage,Get_Layers,tmp
                   mov     ebp,[tmp]
                   mov     [ContourLayer],0
                   comcall ebp,IVGLayers,Find,strCut,ContourLayer
                   comcall ebp,IVGLayers,Release
                   cmp     [ContourLayer],0
                   jne @f
                     comcall ebx,IVGPage,CreateLayer,strCut,ContourLayer
                   @@:
                   comcall ebx,IVGPage,Release
                   cominvk ActiveLayer,Activate
                   comcall esi,IVGDocument,Get_SelectionRange,Selection

                   test    [Params.flags],FLAGS_GROUP
                   je @f
                     cominvk Selection,Group,Shape
                     cominvk Selection,RemoveAll
                     cominvk Selection,Add,[Shape]
                     cominvk Shape,Release
                   @@:

                   cominvk Selection,Get_Count,ShapesCount
                   .MainLoop:
                     cominvk Selection,Get_Item,VT_I4,0,[ShapesCount],0,Shape
                     cominvk Shape,GetSize,ShapeWidth,ShapeHeight
                     cominvk Shape,GetPosition,ShapeX,ShapeY
                     movsd   xmm0,[ShapeY]
                     subsd   xmm0,[ShapeHeight]
                     movsd   [ShapeY],xmm0

               ;Rasterize item
                     cominvk Shape,Duplicate,0,0,0,0,tmp
                     mov     ebx,[tmp]
                     comcall ebx,IVGShape,Get_type,tmp
                     cmp     [tmp],cdrBitmapShape
                     je .Bimmap
                       movzx   eax,[Params.DefImageType]
                       comcall ebx,IVGShape,ConvertToBitmapEx,eax,0,1,MAXDPI,cdrNoAntiAliasing,1,0,0,tmp
                       comcall ebx,IVGShape,Release
                       mov     ebx,[tmp]
                     jmp .Shape
                     .Bimmap:
                       comcall ebx,IVGShape,Get_Bitmap,tmp
                       mov     ebp,[tmp]
                       comcall ebp,IVGBitmap,Get_ResolutionX,tmp
                       mov     esi,MAXDPI
                       mov     edi,MAXDPI
                       sub     esi,[tmp]
                       cmovg   edi,[tmp]
                       cominvk Shape,Get_RotationAngle,tmp
                       movsd   xmm7,qword[tmp]
                       comcall ebp,IVGBitmap,Get_Mode,tmp   ;In theory xmm7 may be corrupted there, but shouldn`t
                       mov     edx,dword[tmp]
                       mov     ecx,not 110100b              ;inverse bitset of cdrGrayscaleImage,cdrRGBColorImage,cdrCMYKColorImage
                       movzx   eax,[Params.DefImageType]
                       bt      ecx,edx
                       cmovc   edx,eax
                       sbb     eax,eax
                       or      esi,eax
                       ptest   xmm7,xmm7
                       setz    al                           ;eax should be zero (S_OK) after Get_Mode calling
                       dec     eax
                       or      esi,eax ;if (ShapeRotationAngle<>0)or(not (Shape.Bitmap.mode in [cdrGrayscaleImage,cdrRGBColorImage,cdrCMYKColorImage]))or(Shape.Bitmap.ResolutionX>MAXDPI) then
                       jns @f
                         comcall ebx,IVGShape,ConvertToBitmapEx,edx,0,1,edi,cdrNoAntiAliasing,1,0,0,tmp
                         comcall ebx,IVGShape,Release
                         mov     ebx,[tmp]
                       @@:
                       comcall ebp,IVGBitmap,Release
                     .Shape:

                     comcall  ebx,IVGShape,Get_Bitmap,tmp
                     mov      ebp,[tmp]
                     comcall  ebp,IVGBitmap,Get_Image,tmp
                     mov      esi,[tmp]
                     comcall  ebp,IVGBitmap,Get_ImageAlpha,tmp
                     mov      edi,[tmp]
                     comcall  ebp,IVGBitmap,Release

               ;calculate bleeds width in pixels and new image size with bleeds
                     comcall  esi,IVGImage,Get_type,ImageType
                     comcall  esi,IVGImage,Get_Width,ImageWidth
                     comcall  esi,IVGImage,Get_Height,ImageHeight
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
                     mov      [Alpha2],eax
                     stdcall  GetImageData,edi,eax
                     comcall  edi,IVGImage,Release
                     invoke   VirtualAlloc,0,[ImageSize],MEM_COMMIT,PAGE_READWRITE
                     mov      [Color2],eax
                     stdcall  GetImageData,esi,eax
                     comcall  esi,IVGImage,Release
                     comcall  ebx,IVGShape,Delete
                     comcall  ebx,IVGShape,Release

               ;Alpha channel thresolding
                     mov    ecx,[ImageSize]
                     add    ecx,15
                     and    ecx,-16
                     mov    eax,[Alpha2]
                     movdqu xmm1,dqword[AlphaThresold]
                     @@:sub     ecx,16
                        movdqa  xmm0,[eax+ecx]
                        pcmpgtd xmm0,xmm1
                        movdqa  [eax+ecx],xmm0
                     jne @b

               ;Contour and backplate
                     cominvk  CorelDoc,CreateImage,[ImageType],[ImageWidth],[ImageHeight],0,Image
                     test     [Params.flags],FLAGS_CONTOUR+FLAGS_ONLYOUTER
                     je .Bleeds
                       stdcall SetImageData,[Image],[Alpha2]
                       push    tmp
                       push    0
                       push    [Image]
                       sub     esp,32
                       movapd  xmm0,dqword[ShapeX]
                       movapd  xmm1,dqword[ShapeWidth]
                       movupd  [esp],xmm0
                       movupd  [esp+16],xmm1
                       cominvk ActiveLayer,CreateBitmap2
                       mov     ebx,[tmp]
                       comcall ebx,IVGShape,Get_Bitmap,tmp
                       comcall ebx,IVGShape,Release
                       mov     ebx,[tmp]
                       movzx   eax,[Params.Smooth]
                       comcall ebx,IVGBitmap,Trace,cdrTraceDetailedLogo,eax,100,cdrColorBlackAndWhite,cdrCustom,2,1,1,1,tmp
                       comcall ebx,IVGBitmap,Release
                       mov     ebx,[tmp]
                       comcall ebx,IVGTraceSettings,Finish,tmp
                       comcall ebx,IVGTraceSettings,Release
                       mov     ebx,[tmp]
                       mov     [tmp],0
                       comcall ebx,IVGShapeRange,Combine,tmp
                       comcall ebx,IVGShapeRange,Release
                       mov     ebx,[tmp]
                       test    ebx,ebx ;if user cancelate tracing
                       je      .cancel
                       test    [Params.flags],FLAGS_ONLYOUTER
                       je .NoBackPlate
                         comcall ebx,IVGShape,BreakApartEx,tmp
                         comcall ebx,IVGShape,Release
                         mov     ebp,[tmp]
                         comcall ebp,IVGShapeRange,Get_LastShape,tmp
                         mov     ebx,[tmp]
                         comcall ebp,IVGShapeRange,Get_Count,tmp
                         mov     esi,[tmp]
                         jmp     .start
                         @@:comcall ebp,IVGShapeRange,Get_Item,VT_I4,0,esi,0,tmp
                            mov     edi,[tmp]
                            comcall ebx,IVGShape,Weld,edi,0,0,tmp
                            comcall ebx,IVGShape,Release
                            comcall edi,IVGShape,Release
                            mov     ebx,[tmp]
                            .start:
                            dec     esi
                         jne @b
                         comcall ebp,IVGShapeRange,Release
                         cominvk CorelApp,CreateCMYKColor,0,0,0,0,tmp
                         mov     esi,[tmp]
                         comcall ebx,IVGShape,CreateContour,cdrContourInside,dword[dpircp],dword[dpircp+4],1,cdrDirectFountainFillBlend,0,esi,0,0,0,cdrContourSquareCap,cdrContourCornerMiteredOffsetBevel,0,$402E0000,tmp ;MiterLimit=15.0
                         comcall ebx,IVGShape,Release
                         comcall esi,IVGColor,Release
                         mov     ebp,[tmp]
                         comcall ebp,IVGEffect,Separate,tmp
                         comcall ebp,IVGEffect,Release
                         mov     ebp,[tmp]
                         comcall ebp,IVGShapeRange,Get_LastShape,tmp
                         mov     ebx,[tmp]
                         comcall ebp,IVGShapeRange,Get_FirstShape,tmp
                         mov     esi,[tmp]
                         comcall esi,IVGShape,OrderBackOf,[Shape]
                         cominvk Shape,Release
                         mov     [Shape],esi
                         comcall ebp,IVGShapeRange,Release
                       .NoBackPlate:
                       comcall ebx,IVGShape,Get_Fill,tmp
                       mov     ebp,[tmp]
                       comcall ebp,IVGFill,ApplyNoFill
                       comcall ebp,IVGFill,Release
                       comcall ebx,IVGShape,Get_Outline,tmp
                       mov     ebp,[tmp]
                       comcall ebp,IVGOutline,Set_Width,dword[UltraThin],dword[UltraThin+4]
                       comcall ebp,IVGOutline,Release
                       comcall ebx,IVGShape,MoveToLayer,[ContourLayer]
                       test    [Params.flags],FLAGS_CONTOUR
                       jne @f
                         comcall ebx,IVGShape,Delete
                       @@:
                       comcall ebx,IVGShape,Release
                     .Bleeds:

               ;Bleeds creation
                     test     [Params.flags],FLAGS_BLEEDS
                     je .NoBleeds
                          invoke VirtualAlloc,0,[ImageSize],MEM_COMMIT,PAGE_READWRITE
                          mov    [Alpha],eax
                          invoke VirtualAlloc,0,[ImageSize],MEM_COMMIT,PAGE_READWRITE
                          mov    [Color],eax
                          mov    [espPreserve],esp
                          mov    eax,[BleedsWidth]
                          dec    eax
                          mov    [TileCount],eax
                          mov    edx,[ImageWidth]
                          jmp .Start
                          .Pass:
                            mov   esp,[ImageHeight]
                            sub   esp,2
                            .Row:
                              lea   ecx,[edx-2]
                              .Col:
                                add esi,4
                                add edi,4
                                add ebx,4
                                add ebp,4
                                cmp dword[edi+edx*4],0
                                jne @f
                                  mov   eax,[edi-4]
                                  add   eax,[edi]
                                  add   eax,[edi+4]
                                  add   eax,[edi+edx*4-4]
                                  add   eax,[edi+edx*4]
                                  add   eax,[edi+edx*4+4]
                                  add   eax,[edi+edx*8-4]
                                  add   eax,[edi+edx*8]
                                  add   eax,[edi+edx*8+4]
                                  je @f
                                    movd      xmm0,[esi-4]
                                    movd      xmm2,[esi]
                                    movd      xmm3,[esi+4]
                                    movd      xmm4,[edi-4]
                                    movd      xmm5,[edi]
                                    movd      xmm6,[edi+4]
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

                                    movd      xmm1,[esi+edx*4-4]
                                    movd      xmm2,[esi+edx*4]
                                    movd      xmm3,[esi+edx*4+4]
                                    movd      xmm4,[edi+edx*4-4]
                                    movd      xmm5,[edi+edx*4]
                                    movd      xmm6,[edi+edx*4+4]
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

                                    movd      xmm1,[esi+edx*8-4]
                                    movd      xmm2,[esi+edx*8]
                                    movd      xmm3,[esi+edx*8+4]
                                    movd      xmm4,[edi+edx*8-4]
                                    movd      xmm5,[edi+edx*8]
                                    movd      xmm6,[edi+edx*8+4]
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
                                    mov       dword[ebx+edx*4],255
                                    movd      [ebp+edx*4],xmm0
                                  @@:
                                  dec ecx
                                jne .Col
                                add esi,8
                                add edi,8
                                add ebx,8
                                add ebp,8
                                dec esp
                              jne .Row
                              .Start:
                              mov   edi,[Alpha]
                              mov   esi,[Color]
                              mov   ebx,[Alpha2]
                              mov   ebp,[Color2]
                              mov   ecx,[ImageSize]
                              add   ecx,15
                              and   ecx,-16
                              @@:sub    ecx,16
                                 movdqa xmm0,[ebx+ecx]
                                 movdqa xmm1,[ebp+ecx]
                                 movdqa [edi+ecx],xmm0
                                 movdqa [esi+ecx],xmm1
                              jne @b
                              dec [TileCount]
                          jns .Pass
                          mov   esp,[espPreserve]

                          stdcall SetImageData,[Image],[Color]
                          cominvk CorelDoc,CreateImage,cdrGrayscaleImage,[ImageWidth],[ImageHeight],0,tmp
                          mov     esi,[tmp]
                          stdcall SetImageData,esi,[Alpha]
                          push    tmp
                          push    esi
                          push    [Image]
                          sub     esp,32
                          movapd  xmm0,dqword[ShapeX]
                          movapd  xmm1,dqword[ShapeWidth]
                          movupd  [esp],xmm0
                          movupd  [esp+16],xmm1
                          cominvk ActiveLayer,CreateBitmap2
                          mov     ebx,[tmp]
                          comcall ebx,IVGShape,OrderBackOf,[Shape]
                          comcall ebx,IVGShape,Release
                          comcall esi,IVGImage,Release
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
                   popad
       .WM_CLOSE:cominvk UserData,Set_Item,strBleeds,0,VT_I4,0,[Params],0
                 cominvk UserData,Release
                 invoke  EndDialog,dword[esp+8],0
           .quit:ret 16
  .WM_INITDIALOG:push  ebx
                 push  ebp
                 cominvk CorelApp,Get_GlobalUserData,UserData
                 mov     dword[tmpVariant.type],0
                 cominvk UserData,Get_Item,strBleeds,0,tmpVariant
                 cmp     dword[tmpVariant.type],VT_I4
                 jne @f
                   mov eax,dword[tmpVariant.data]
                   mov [Params],eax
                 @@:

                 movzx ebx,[Params.flags]
                 mov   ebp,4
                 shl   ebx,28
                 @@:add    ebx,ebx
                    sbb    eax,eax
                    invoke SendDlgItemMessageW,dword[esp+28],ebp,BM_SETCHECK,eax,0
                    dec    ebp
                 jne @b
                 invoke  GetDlgItem,dword[esp+16],10
                 mov     [SmoothTrack],eax
                 mov     ebx,eax
                 invoke  SendMessageW,ebx,TBM_SETRANGE,0,100 shl 16
                 movzx   eax,[Params.Smooth]
                 invoke  SendMessageW,ebx,TBM_SETPOS,1,eax
                 movzx   eax,[Params.Smooth]
                 shl     eax,16
                 stdcall DialogFunc,dword[esp+24],WM_HSCROLL,eax,ebx
                 invoke  GetDlgItem,dword[esp+16],1
                 stdcall DialogFunc,dword[esp+24],WM_COMMAND,1,eax

                 invoke  GetDlgItem,dword[esp+16],12
                 mov     [BleedsTrack],eax
                 mov     ebx,eax
                 invoke  SendMessageW,ebx,TBM_SETRANGE,0,50 shl 16+1
                 movzx   eax,[Params.BleedsSize]
                 invoke  SendMessageW,ebx,TBM_SETPOS,1,eax
                 movzx   eax,[Params.BleedsSize]
                 shl     eax,16
                 stdcall DialogFunc,dword[esp+24],WM_HSCROLL,eax,ebx
                 invoke  GetDlgItem,dword[esp+16],2
                 stdcall DialogFunc,dword[esp+24],WM_COMMAND,2,eax

                 movzx   eax,[Params.DefImageType]
                 inc     eax
                 invoke  SendDlgItemMessageW,dword[esp+28],eax,BM_SETCHECK,1,0
                 pop     ebp
                 pop     ebx
                 mov     eax,1
                 ret 16

QueryInterface:   ;(const self:IVGAppPlugin; const IID: TGUID; out Obj): HResult; stdcall;
  mov eax,[esp+12]
  mov dword[eax],IPlugin
  xor eax,eax
ret 12
AddRef:           ;(const self:IVGAppPlugin):Integer; stdcall;
Release:          ;(const self:IVGAppPlugin):Integer; stdcall;
  xor eax,eax
ret 4
GetTypeInfoCount: ;(const self:IVGAppPlugin; out Count: Integer): HResult; stdcall;
  mov eax,E_NOTIMPL
ret 8
GetTypeInfo:      ;(const self:IVGAppPlugin; Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
  mov eax,E_NOTIMPL
ret 12
GetIDsOfNames:    ;(const self:IVGAppPlugin; const IID: TGUID; Names: Pointer;NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
  mov eax,E_NOTIMPL
ret 24

Invoke:           ;(const self:IVGAppPlugin; DispID: Integer; const IID: TGUID; LocaleID: Integer;Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
  mov eax,[esp+8]
  cmp eax,OnSelectionChange
  je .OnSelectionChange
  cmp eax,OnPluginCommand
  je .OnPluginCommand
  cmp eax,OnUpdatePluginCommand
  je .OnUpdatePluginCommand
  xor eax,eax
  ret 36
      .OnSelectionChange:cominvk CorelApp,Get_ActiveSelectionRange,Selection
                         test    eax,eax
                         jne @f
                           cominvk Selection,Get_Count,Enabled
                           cominvk Selection,Release
                         @@:
                         xor     eax,eax
                         ret 36
        .OnPluginCommand:mov    eax,[esp+24]
                         mov    eax,[eax+DISPPARAMS.rgvarg]
                         invoke lstrcmpW,dword[eax+VARIANT.data],strBleeds
                         test   eax,eax
                         jne    @f
                           cominvk CorelApp,Get_ActiveWindow,CorelWnd
                           cominvk CorelWnd,Get_Handle,CorelWndHandle
                           cominvk CorelWnd,Release
                           invoke  DialogBoxIndirectParamW,0,MainDlg,[CorelWndHandle],DialogFunc,0
                           cominvk CorelApp,Refresh
                         @@:
                         xor     eax,eax
                         ret 36
  .OnUpdatePluginCommand:xchg   ebx,[esp+24]
                         mov    ebx,[ebx+DISPPARAMS.rgvarg]
                         invoke lstrcmpW,dword[ebx+sizeof.VARIANT*2+VARIANT.data],strBleeds
                         test   eax,eax
                         jne    @f
                           mov eax,dword[ebx+sizeof.VARIANT*1+VARIANT.data]
                           mov edx,[Enabled]
                           mov [eax],dx
                         @@:
                         mov    ebx,[esp+24]
                         xor    eax,eax
                         ret 36

OnLoad:           ;(const self:IVGAppPlugin; const _Application: IVGApplication):LongInt;stdcall;
  xchg    ebx,[esp+8]
  mov     [CorelApp],ebx
  comcall ebx,IVGApplication,AddRef
  mov     ebx,[esp+8]
ret 8

StartSession:     ;(const self:IVGAppPlugin):LongInt;stdcall;
  push    ebx
  mov     eax,1
  cpuid
  test    ecx,1 shl 19 ;SSE 4.1
  je .CPUNotSupported
    mov     ebx,[CorelApp]
    comcall ebx,IVGApplication,AddPluginCommand,strBleeds,strButtonCaption,strButtonCaption,buf
    comcall ebx,IVGApplication,AdviseEvents,IPlugin,EventsCookie
    comcall ebx,IVGApplication,Get_CommandBars,tmp
    mov     ebx,[tmp]
    mov     [tmp],0
    comcall ebx,ICUICommandBars,Get_Item,VT_BSTR,0,strBleeds,0,tmp
    cmp     [tmp],0
    jne @f
      comcall ebx,ICUICommandBars,Add,strBleeds,cuiBarTop,0,tmp
    @@:
    comcall ebx,ICUICommandBars,Release
    mov     ebx,[tmp]
    comcall ebx,ICUICommandBar,Set_Visible,1
    comcall ebx,ICUICommandBar,Get_Controls,tmp
    comcall ebx,ICUICommandBar,Release
    mov     ebx,[tmp]
    comcall ebx,ICUIControls,AddCustomButton,cdrCmdCategoryPlugins,strBleeds,1,0,tmp
    comcall ebx,ICUIControls,Release
    mov     ebx,[tmp]
    invoke  GetTempPathW,bufsize/2,buf+4
    lea     eax,[eax*2+strBleeds.size]
    mov     dword[buf],eax
    movdqu  xmm0,dqword[strBleeds]
    movdqu  dqword[buf+4+eax-strBleeds.size],xmm0
    invoke  CreateFileW,buf+4,GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
    push    eax
    invoke  WriteFile,eax,ICOData,sizeof.ICOData,tmp,0
    invoke  CloseHandle
    comcall ebx,ICUIControl,SetIcon2,buf+4
    comcall ebx,ICUIControl,Release
    pop     ebx
    xor     eax,eax
    ret 4
  .CPUNotSupported:
  invoke MessageBoxW,[CorelWndHandle],errCPUNotSupported,strBleeds,MB_TASKMODAL
  pop    ebx
  mov    eax,E_FAIL
ret 4

StopSession:      ;(const self:IVGAppPlugin):LongInt;stdcall;
  cominvk CorelApp,UnadviseEvents,[EventsCookie]
  xor     eax,eax
ret 4

OnUnload:         ;(const self:IVGAppPlugin)LongInt;stdcall;
  cominvk CorelApp,Release
  xor     eax,eax
ret 4

align 4
IPlugin           dd IPluginVMT
IPluginVMT        dd QueryInterface,\
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
CorelWndHandle    rd 1
espPreserve       rd 1
Color             rd 1
Alpha             rd 1
Color2            rd 1
Alpha2            rd 1
tmp               rd 1
                  rd 1
SmoothTrack       rd 1
BleedsTrack       rd 1
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
TileData          rd 1
TileStart         rd 1
Enabled           rd 1
rgsabound         SAFEARRAYBOUND