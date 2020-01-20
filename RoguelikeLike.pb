Enumeration TileTypes : #Floor : #Wall : EndEnumeration
Structure Tile
  x.w : y.w : Sprite.u : Passable.a : TileType.a
EndStructure
Enumeration GameResources : #SpriteSheet :  EndEnumeration
Enumeration GameSprites : #Player : #PlayerDeath : EndEnumeration
Global PlayerX.w = 0, PlayerY.w = 0
Global TileSize.a = 64, NumTiles.u = 9, UIWidth.u = 4, GameWidth.u = TileSize * (NumTiles + UIWidth), GameHeight.u = TileSize * NumTiles,ExitGame.a = #False, SoundMuted.a = #False
Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, LastTimeInMs.q
Global Tiles

Procedure LoadSprites()
  LoadSprite(#SpriteSheet, BasePath + "graphics" + #PS$ + "spritesheet.png")
  ;LoadSprite(#Brick, BasePath + "brick.bmp") : LoadSprite(#PaddleH, BasePath + "horizontal-paddle.bmp")
  ;LoadSprite(#PaddleV, BasePath + "vertical-paddle.bmp") : LoadSprite(#Ball, BasePath + "ball.bmp")
  ;Bitmap_Font_Sprite = LoadSprite(#PB_Any, BasePath + "font.png") : Pause_Background_Sprite = LoadSprite(#PB_Any, BasePath + "pause-background.png")
EndProcedure
Procedure DrawSprite(SpriteIndex.u, x.l, y.l)
  ClipSprite(#SpriteSheet, SpriteIndex * 16, 0, 16, 16) : ZoomSprite(#SpriteSheet, TileSize, TileSize) : DisplayTransparentSprite(#SpriteSheet, x * TileSize, y * TileSize)
EndProcedure
Procedure GenerateTiles()
  
EndProcedure
Procedure GenerateLevel()
  GenerateTiles()
EndProcedure
Procedure PlaySoundEffect(Sound.a)
  If SoundInitiated And Not SoundMuted
    PlaySound(Sound)
  EndIf
EndProcedure
Procedure LoadSounds()
  If SoundInitiated
    ;LoadSound(#Lost_Life, BasePath + "lost_life.wav")
    ;LoadSound(#Game_Over, BasePath + "game_over.wav")
    ;LoadSound(#Brick_Break, BasePath + "brick_break.wav")
    ;If LoadSound(#Ball_Touch, BasePath + "ball_touch.wav")
    ;  PlaySoundEffect(#Ball_Touch);on windows the first call to playsound is taking over a second to complete, so we call it here to get over it
    ;EndIf
  EndIf
EndProcedure
Procedure CreateBricks(NumCols.i, NumLines.i, Offset.f = 5)
EndProcedure
Procedure CreatePaddles()
EndProcedure
Procedure CreateBall(StartX.f, StartY.f, VelX.f = 0, VelY.f = 0)
EndProcedure
Declare RenderFrame()
Procedure StartGame(IsNextLevel.b)
  CompilerIf #PB_Compiler_Processor = #PB_Processor_JavaScript
    BindEvent(#PB_Event_RenderFrame, @RenderFrame())
    FlipBuffers()
  CompilerEndIf
EndProcedure
Procedure DrawBitmapText(x.f, y.f, Text.s, CharWidthPx.a = 16, CharHeightPx.a = 24);draw text is too slow on linux, let's try to use bitmap fonts
  ClipSprite(Bitmap_Font_Sprite, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
  ZoomSprite(Bitmap_Font_Sprite, #PB_Default, #PB_Default)
  For i.i = 1 To Len(Text);loop the string Text char by char
    AsciiValue.a = Asc(Mid(Text, i, 1))
    ClipSprite(Bitmap_Font_Sprite, (AsciiValue - 32) % 16 * 8, (AsciiValue - 32) / 16 * 12, 8, 12)
    ZoomSprite(Bitmap_Font_Sprite, CharWidthPx, CharHeightPx)
    DisplayTransparentSprite(Bitmap_Font_Sprite, x + (i - 1) * CharWidthPx, y)
  Next
EndProcedure
Procedure DrawHUD()
EndProcedure

Procedure UpdateKeyBoard(Elapsed.f)
  If KeyboardReleased(#PB_Key_W) : PlayerY - 1 : EndIf
  If KeyboardReleased(#PB_Key_S) : PlayerY + 1 : EndIf
  If KeyboardReleased(#PB_Key_A) : PlayerX - 1 : EndIf
  If KeyboardReleased(#PB_Key_D) : PLayerX + 1 : EndIf
    
EndProcedure
If InitSprite() = 0 Or InitKeyboard() = 0
  CompilerIf #PB_Compiler_Processor = #PB_Processor_JavaScript
    MessageRequester("Sprite system Or keyboard system can't be initialized", 0)
  CompilerElse
    MessageRequester("Error", "Sprite system or keyboard system can't be initialized", 0)
  CompilerEndIf
  End
EndIf
Procedure Loading()
  Static LoadedElements.a
  LoadedElements + 1
  If LoadedElements = 10
    StartGame(#False)
  EndIf
EndProcedure
Procedure LoadingError(Type, Filename$)
  Debug Filename$ + ": loading error"
EndProcedure
CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
  UsePNGImageDecoder()
CompilerEndIf
SoundInitiated = InitSound()
CompilerIf #PB_Compiler_Processor = #PB_Processor_JavaScript
  BindEvent(#PB_Event_Loading, @Loading()) : BindEvent(#PB_Event_LoadingError, @LoadingError())
CompilerEndIf
Procedure Draw()
  ClearScreen(RGB(0,0,0)) : DrawSprite(#Player, PlayerX, PlayerY) : DrawHUD()
  ;DisplayTransparentSprite(#SpriteSheet, 0, 0)
EndProcedure
Procedure RenderFrame()
  ElapsedTimneInS = (ElapsedMilliseconds() - LastTimeInMs) / 1000.0
  If ElapsedTimneInS >= 0.05;never let the elapsed time be higher than 20 fps
    ElapsedTimneInS = 0.05
  EndIf
  CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
    Repeat; Always process all the events to flush the queue at every frame
      Event = WindowEvent()
      Select Event
        Case #PB_Event_CloseWindow
          ExitGame = #True
      EndSelect
    Until Event = 0 ; Quit the event loop only when no more events are available
  CompilerEndIf  
  ExamineKeyboard() : UpdateKeyBoard(ElapsedTimneInS)
  Draw()
  LastTimeInMs = ElapsedMilliseconds()
  FlipBuffers()
EndProcedure
If OpenWindow(0, 0, 0, GameWidth, GameHeight, "RoguelikeLike", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If OpenWindowedScreen(WindowID(0), 0, 0, GameWidth, GameHeight, 0, 0, 0)
    LoadSprites()
    LoadSounds()
    CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
      StartGame(#False)
    CompilerEndIf
    
    LastTimeInMs = ElapsedMilliseconds()
    CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
      Repeat
        RenderFrame()
      Until ExitGame
    CompilerEndIf
  EndIf
EndIf