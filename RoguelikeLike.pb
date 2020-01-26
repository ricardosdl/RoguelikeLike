Enumeration TileTypes : #Floor : #Wall : EndEnumeration
Structure TTile
  x.w : y.w : Sprite.u : Passable.a : TileType.a : *Monster.TMonster
EndStructure
Enumeration MonsterTypes : #Player : #Bird : #Snake : #Tank : #Eater : #Jester : EndEnumeration
Prototype DoStuffProc(*Monster) : Prototype UpdateMonsterProc(*Monster)
Structure TMonster
  *Tile.TTile : Sprite.u : Hp.f : MonsterType.a : Dead.a : DoStuff.DoStuffProc : AttackedThisTurn.a
  Stunned.a : Update.UpdateMonsterProc
EndStructure
Enumeration GameResources : #SpriteSheet :  EndEnumeration
Enumeration GameSprites
  #SpritePlayer : #SpritePlayerDeath : #SpriteFloor : #SpriteWall : #SpriteBird : #SpriteSnake : #SpriteTank
  #SpriteEater : #SpriteJester : #SpriteHp
EndEnumeration
Prototype.a CallBackProc();our callback prototype
Global PlayerX.w = 0, PlayerY.w = 0
Global TileSize.a = 64, NumTiles.u = 9, UIWidth.u = 4, GameWidth.u = TileSize * (NumTiles + UIWidth), GameHeight.u = TileSize * NumTiles,ExitGame.a = #False, SoundMuted.a = #False
Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, LastTimeInMs.q
Global Dim Tiles.TTile(NumTiles - 1, NumTiles - 1), *RandomPassableTile.TTile
Global Level.a, Player.TMonster, NewList Monsters.TMonster(), MaxHp.a = 6

Procedure LoadSprites()
  LoadSprite(#SpriteSheet, BasePath + "graphics" + #PS$ + "spritesheet.png")
EndProcedure
Procedure DrawSprite(SpriteIndex.u, x.f, y.f)
  ClipSprite(#SpriteSheet, SpriteIndex * 16, 0, 16, 16) : ZoomSprite(#SpriteSheet, TileSize, TileSize) : DisplayTransparentSprite(#SpriteSheet, x * TileSize, y * TileSize)
EndProcedure
Procedure MoveMonster(*Monster.TMonster, *NewTile.TTile)
  If *Monster\Tile <> #Null : *Monster\Tile\Monster = #Null : EndIf
  *Monster\Tile = *NewTile : *NewTile\Monster = *Monster
EndProcedure
Procedure InitMonster(*Monster.TMonster, *Tile.TTile, Sprite.u, Hp.b, MonsterType.a, DoStuff.DoStuffProc, UpdateMonster.UpdateMonsterProc)
  MoveMonster(*Monster, *Tile) : *Monster\Sprite = Sprite : *Monster\Hp = Hp : *Monster\MonsterType = MonsterType
  *Monster\Dead = #False : *Monster\DoStuff = DoStuff : *Monster\AttackedThisTurn = #False : *Monster\Stunned = #False
  *Monster\Update = UpdateMonster
EndProcedure
Procedure.i GetTile(x.w, y.w)
  If (x < 0 Or x > NumTiles - 1) Or (y < 0 Or y > NumTiles -1)
    ProcedureReturn #Null
  EndIf
  ProcedureReturn @Tiles(x, y)
EndProcedure
Procedure.a GetTileDistance(*TileA.TTile, *TileB.TTile)
  ProcedureReturn Abs(*TileA\x - *TileB\x) + Abs(*TileA\y - *TileB\y)
EndProcedure
Procedure.i GetTileNeighbor(*Tile.TTile, Dx.w, Dy.w)
  ProcedureReturn GetTile(*Tile\x + Dx, *Tile\y + Dy)
EndProcedure
Procedure DieMonster(*Monster.TMonster)
  *Monster\Dead = #True : *Monster\Tile\Monster = #Null : *Monster\Sprite = #SpritePlayerDeath
EndProcedure
Procedure HitMonster(*Monster.TMonster, Damage.a)
  *Monster\hp - Damage
  If *Monster\hp <= 0 : DieMonster(*Monster) : EndIf
EndProcedure
Procedure.a TryMonsterMove(*Monster.TMonster, Dx.w, Dy.w)
  *NewTile.TTile = GetTileNeighbor(*Monster\Tile, Dx, Dy)
  If *NewTile <> #Null And *NewTile\Passable
    If *NewTile\Monster = #Null
      MoveMonster(*Monster, *NewTile)
    Else
      If *Monster\MonsterType = #Player Or *NewTile\Monster\MonsterType = #Player
         *Monster\AttackedThisTurn = #True : *NewTile\Monster\Stunned = #True : HitMonster(*NewTile\Monster, 1)
      EndIf
    EndIf
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure
Procedure GetTileAdjacentNeighbors(*Tile.TTile, List AdjacentNeighbors.i())
  ClearList(AdjacentNeighbors())
  AddElement(AdjacentNeighbors()) : AdjacentNeighbors() = GetTileNeighbor(*Tile, 0, -1)
  AddElement(AdjacentNeighbors()) : AdjacentNeighbors() = GetTileNeighbor(*Tile, 0, 1)
  AddElement(AdjacentNeighbors()) : AdjacentNeighbors() = GetTileNeighbor(*Tile, -1, 0)
  AddElement(AdjacentNeighbors()) : AdjacentNeighbors() = GetTileNeighbor(*Tile, 1, 0)
EndProcedure
Procedure GetTileAdjacentPassableNeighbors(*Tile.TTile, List AdjacentPassableNeighbors.i())
  Define NewList AdjacentNeighbors.i() : ClearList(AdjacentPassableNeighbors())
  GetTileAdjacentNeighbors(*Tile, AdjacentNeighbors())
  ForEach AdjacentNeighbors() : *AdjacentNeighbor.TTile = AdjacentNeighbors()
    If *AdjacentNeighbor = #Null : Continue : EndIf
    If *AdjacentNeighbor\Passable
      AddElement(AdjacentPassableNeighbors()) : AdjacentPassableNeighbors() = *AdjacentNeighbor
    EndIf
  Next
EndProcedure
Procedure DoMonsterStuff(*Monster.TMonster)
  NewList AdjacentPassableNeighbors.i()
  GetTileAdjacentPassableNeighbors(*Monster\Tile, AdjacentPassableNeighbors())
  ForEach AdjacentPassableNeighbors() : *CurrentTile.TTile = AdjacentPassableNeighbors()
    If *CurrentTile\Monster = #Null Or *CurrentTile\Monster\MonsterType = #Player
      Continue
    Else
      DeleteElement(AdjacentPassableNeighbors())
    EndIf
  Next
  ResetList(AdjacentPassableNeighbors())
  If ListSize(AdjacentPassableNeighbors()) > 0
    SmallestDistance.w = NumTiles * NumTiles : *ClosestPassableTile.TTile = #Null
    ForEach AdjacentPassableNeighbors() : *CurrentTile.TTile = AdjacentPassableNeighbors()
      Distance.a = GetTileDistance(*CurrentTile, Player\Tile)
      If Distance < SmallestDistance
        *ClosestPassableTile = *CurrentTile : SmallestDistance = Distance
      EndIf
    Next
    TryMonsterMove(*Monster, *ClosestPassableTile\x - *Monster\Tile\x, *ClosestPassableTile\y - *Monster\Tile\y)
  EndIf
EndProcedure
Procedure DoSnakeStuff(*Snake.TMonster)
  *Snake\AttackedThisTurn = #False : DoMonsterStuff(*Snake)
  If Not *Snake\AttackedThisTurn : DoMonsterStuff(*Snake) : EndIf
EndProcedure
Procedure ReplaceTile(NewTileType.a, x.w, y.w)
  If NewTileType = #Floor
    Tiles(x, y)\Sprite = #SpriteFloor : Tiles(x, y)\Passable = #True : Tiles(x, y)\TileType = #Floor
  ElseIf NewTileType = #Wall
    Tiles(x, y)\Sprite = #SpriteWall : Tiles(x, y)\Passable = #False : Tiles(x, y)\TileType = #Wall
  EndIf
EndProcedure
Procedure HealMonsterEater(*Eater.TMonster, Damage.f)
  *Eater\Hp + Damage : If *Eater\Hp > MaxHp : *Eater\Hp = MaxHp : EndIf
EndProcedure
Procedure.a InBounds(x.w, y.w)
  ProcedureReturn Bool(x > 0 And y > 0 And x < NumTiles - 1 And y < NumTiles - 1)
EndProcedure
Procedure DoEaterSuff(*Eater.TMonster)
  NewList AdjacentNeighbors.i()
  GetTileAdjacentNeighbors(*Eater\Tile, AdjacentNeighbors())
  ForEach AdjacentNeighbors() : *CurrentTile.TTile = AdjacentNeighbors()
    If Not *CurrentTile\Passable And InBounds(*CurrentTile\x, *CurrentTile\y)
      Continue
    Else
      DeleteElement(AdjacentNeighbors())
    EndIf
  Next
  If ListSize(AdjacentNeighbors()) > 0 : FirstElement(AdjacentNeighbors()) : *Tile.TTile = AdjacentNeighbors()
    ReplaceTile(#Floor, *Tile\x, *Tile\y) : HealMonsterEater(*Eater.TMonster, 0.5)
  Else
    DoMonsterStuff(*Eater)
  EndIf
EndProcedure
Procedure UpdateMonster(*Monster.TMonster)
  If *Monster\Stunned
    *Monster\Stunned = #False : ProcedureReturn
  EndIf
  If *Monster\DoStuff <> #Null : *Monster\DoStuff(*Monster) : EndIf
EndProcedure
Procedure UpdateTankMonster(*Monster.TMonster)
  StartStunned.a = *Monster\Stunned : UpdateMonster(*Monster)
  If Not StartStunned : *Monster\Stunned = #True : EndIf
EndProcedure
Procedure.i InitAMonster(*Tile.TTile, MonsterType.a)
  AddElement(Monsters())
  Select MonsterType
    Case #Player
    Case #Bird : InitMonster(@Monsters(), *Tile, #SpriteBird, 3, #Bird, @DoMonsterStuff(), @UpdateMonster())
    Case #Snake : InitMonster(@Monsters(), *Tile, #SpriteSnake, 1, #Snake, @DoSnakeStuff(), @UpdateMonster())
    Case #Tank : InitMonster(@Monsters(), *Tile, #SpriteTank, 2, #Tank, @DoMonsterStuff(), @UpdateTankMonster())
    Case #Eater : InitMonster(@Monsters(), *Tile, #SpriteEater, 1, #Eater, @DoEaterSuff(), @UpdateMonster())
    Case #Jester : InitMonster(@Monsters(), *Tile, #SpriteJester, 2, #Jester, @DoMonsterStuff(), @UpdateMonster())
  EndSelect
  ProcedureReturn @Monsters()
EndProcedure
Procedure Tick()
  ForEach Monsters()
    If Monsters()\hp > 0
      Monsters()\Update(@Monsters())
    Else
      DeleteElement(Monsters())
    EndIf
  Next
EndProcedure
Procedure.a TryPlayerMonsterMove(*Player.TMonster, Dx.w, Dy.w)
  If TryMonsterMove(Player, Dx, Dy) : Tick() : EndIf
EndProcedure
Procedure TryTo(Description.s, Callback.CallbackProc)
  For i.u = 1000 To 1 Step -1
    If Callback()
      ProcedureReturn
    EndIf
  Next i
  RaiseError(#PB_OnError_IllegalInstruction)
EndProcedure
Procedure GetRandomPassableTile()
  x.w = Random(NumTiles - 1, 0) : y = Random(NumTiles - 1, 0)
  *RandomPassableTile = GetTile(x, y)
  ProcedureReturn Bool(*RandomPassableTile\Passable And Not *RandomPassableTile\Monster)
EndProcedure
Procedure.i RandomPassableTile()
  TryTo("get random passable tile", @GetRandomPassableTile())
  ProcedureReturn *RandomPassableTile
EndProcedure
Procedure.i SpawnMonster()
  ProcedureReturn InitAMonster(RandomPassableTile(), Random(#Jester, #Bird))
EndProcedure
Procedure GenerateMonsters()
  NumMonsters.u = Level + 1
  For i.u = 1 To NumMonsters : SpawnMonster() : Next i
EndProcedure
Procedure InitPlayer(*Player.TMonster, *Tile.TTile, Sprite.u, Hp.b)
  InitMonster(*Player, *Tile, Sprite, Hp, #Player, #Null, #Null)
EndProcedure
Procedure DrawTile(*Tile.TTile)
  DrawSprite(*Tile\Sprite, *Tile\x, *Tile\y)
EndProcedure
Procedure GetTileConnectedTiles(*Tile.TTile, List ConnectedTiles.i())
  ClearList(ConnectedTiles()) : AddElement(ConnectedTiles()) : ConnectedTiles() = *Tile
  NewList TilesToCheck.i() : 
  AddElement(TilesToCheck()) : 
  TilesToCheck() = *Tile : 
  ResetList(TilesToCheck())
  While(NextElement(TilesToCheck()))
    *CurrentTile.TTile = TilesToCheck() : FirstElement(TilesToCheck()) : DeleteElement(TilesToCheck())
    NewList PassableNeighbors.i() : GetTileAdjacentPassableNeighbors(*CurrentTile, PassableNeighbors())
    ForEach ConnectedTiles()
      ForEach PassableNeighbors()
        If PassableNeighbors() = ConnectedTiles()
          DeleteElement(PassableNeighbors())
        EndIf
      Next
    Next
    NewList CopyPassableNeighBors() : CopyList(PassableNeighbors(), CopyPassableNeighBors())
    MergeLists(PassableNeighbors(), ConnectedTiles()) : MergeLists(CopyPassableNeighBors(), TilesToCheck())
    ResetList(TilesToCheck())
  Wend
EndProcedure
Procedure.u GenerateTiles()
  NumPassableTiles.u = 0
  For i.w = 0 To NumTiles - 1
    For j.w = 0 To NumTiles - 1
      If (Random(100, 0) / 100.0 < 0.3) Or (Not InBounds(i, j))
        Tiles(i, j)\x = i : Tiles(i, j)\y = j : Tiles(i, j)\Sprite = #SpriteWall : Tiles(i, j)\Passable = #False
        Tiles(i, j)\TileType = #Wall
      Else
        Tiles(i, j)\x = i : Tiles(i, j)\y = j : Tiles(i, j)\Sprite = #SpriteFloor : Tiles(i, j)\Passable = #True
        Tiles(i, j)\TileType = #Floor : NumPassableTiles + 1
      EndIf
      Tiles(i, j)\Monster = #Null
    Next j
  Next i
  ProcedureReturn NumPassableTiles
EndProcedure
Procedure GenerateMap()
  PassableTiles.u = GenerateTiles()
  *RandomPassableTile = RandomPassableTile() : NewList ConnectedTiles.i()
  GetTileConnectedTiles(*RandomPassableTile, ConnectedTiles())
  ProcedureReturn Bool(PassableTiles = ListSize(ConnectedTiles()))
EndProcedure
Procedure GenerateLevel()
  TryTo("generate map", @GenerateMap())
  GenerateMonsters()
EndProcedure
Procedure PlaySoundEffect(Sound.a)
  If SoundInitiated And Not SoundMuted
    PlaySound(Sound)
  EndIf
EndProcedure
Procedure LoadSounds()
  If SoundInitiated
  EndIf
EndProcedure
Declare RenderFrame()
Procedure StartGame(IsNextLevel.b)
  CompilerIf #PB_Compiler_Processor = #PB_Processor_JavaScript
    BindEvent(#PB_Event_RenderFrame, @RenderFrame())
    FlipBuffers()
  CompilerEndIf
  Level = 1 : GenerateLevel()
  *RandomPassableTile.TTile = RandomPassableTile()
  InitPlayer(@Player, *RandomPassableTile, #SpritePlayer, 3)
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
  If KeyboardReleased(#PB_Key_W) : TryPlayerMonsterMove(@Player, 0, -1) : EndIf
  If KeyboardReleased(#PB_Key_S) : TryPlayerMonsterMove(@Player, 0, 1) : EndIf
  If KeyboardReleased(#PB_Key_A) : TryPlayerMonsterMove(@Player, -1, 0) : EndIf
  If KeyboardReleased(#PB_Key_D) : TryPlayerMonsterMove(@Player, 1, 0) : EndIf
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
Procedure DrawMonster(*Monster.TMonster)
  DrawSprite(*Monster\Sprite, *Monster\Tile\x, *Monster\Tile\y)
  For i.b = 0 To *Monster\Hp - 1;draw hp
    ii.b = (i % 3) : Hpx.f = *Monster\Tile\x + (ii) * (5 / 16)
    DrawSprite(#SpriteHp, Hpx, *Monster\Tile\y - Round( i / 3, #PB_Round_Down) * (5 /16))
  Next
EndProcedure
Procedure Draw()
  ClearScreen(RGB(0,0,0))
  For i.w = 0 To NumTiles - 1
    For j.w = 0 To NumTiles - 1
      *Tile.TTile = GetTile(i, j)
      If *Tile = #Null : Continue;the tile is out of the visible screen
      Else
        DrawTile(*Tile)
      EndIf
    Next j
  Next i
  ForEach Monsters() : DrawMonster(@Monsters()) : Next
  DrawMonster(@Player) : DrawHUD()
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