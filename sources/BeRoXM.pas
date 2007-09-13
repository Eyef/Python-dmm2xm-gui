unit BeRoXM;
// BeRoXM modified by Grom PE (XM loader/saver only, no player)
// Copyright (C) 2005-2007, Benjamin 'BeRo' Rosseaux
// http://www.bero.0ok.de/ - http://www.0ok.de/ - http://www.berotracker.de/
// - BeRoXM Sourcecode is copyright (C) 2005-2007, Benjamin 'BeRo' Rosseaux
// - This source must not be redistributed without this text.
// - This source is provided as-is. BeRo (Benjamin Rosseaux) will not support
//   or answer questions about the source provided. unless there are some
//   REALLY nasty bugs. Remember i'm NOT going to spend time on this, except
//   if you are using it in a commerical product! Otherwhise fix it yourself!
// - The source can be modified, and redistributed as long as no copyright or
//   comment blocks (see at the top of each source file) are removed.
// - BeRoXM sourcecode is in no way representative of BeRoTracker source.
// - BeRoXM may not load and save XM files exactly as BeRoTracker does.
// - If your product is not intended to make any money, and is not charged
//   for in any way, then you may use this in it for FREE!
// - You may use it for free until your commercial product is about to be
//   published.
// - If you want to use it in a commercial product, then please contact me
//   (benjamin@0ok.de) for pricing and conditions.
// - You must give credits!

interface

uses Windows,Messages,Streams;

const
  BEROXM_MODIFIED_BY_GROM_PE=true;
  // This constant is for using different code for original BeRoXM version:
  // {$IF Declared(BEROXM_MODIFIED_BY_GROM_PE)}
  // Something();
  // {$ELSE}
  // SomethingElseThatRequiresOriginalVersionOfBeRoXM();
  // {$IFEND}

const
  LastSample=255;
  LastInstrument=255;
  LastPattern=255;
  LastPatternOrder=255;
  LastChannel=255;

  MaxSampleSize=$40000000;

  NoteC1=1;    NoteC2=13;   NoteC3=25;   NoteC4=37;
  NoteCs1=2;   NoteCs2=14;  NoteCs3=26;  NoteCs4=38;
  NoteD1=3;    NoteD2=15;   NoteD3=27;   NoteD4=39;
  NoteDs1=4;   NoteDs2=16;  NoteDs3=28;  NoteDs4=40;
  NoteE1=5;    NoteE2=17;   NoteE3=29;   NoteE4=41; 
  NoteF1=6;    NoteF2=18;   NoteF3=30;   NoteF4=42; 
  NoteFs1=7;   NoteFs2=19;  NoteFs3=31;  NoteFs4=43;
  NoteG1=8;    NoteG2=20;   NoteG3=32;   NoteG4=44;
  NoteGs1=9;   NoteGs2=21;  NoteGs3=33;  NoteGs4=45;
  NoteA1=10;   NoteA2=22;   NoteA3=34;   NoteA4=46;
  NoteAs1=11;  NoteAs2=23;  NoteAs3=35;  NoteAs4=47;
  NoteB1=12;   NoteB2=24;   NoteB3=36;   NoteB4=48;

  NoteC5=49;   NoteC6=61;   NoteC7=73;   NoteC8=85;
  NoteCs5=50;  NoteCs6=62;  NoteCs7=74;  NoteCs8=86;
  NoteD5=51;   NoteD6=63;   NoteD7=75;   NoteD8=87;
  NoteDs5=52;  NoteDs6=64;  NoteDs7=76;  NoteDs8=88;
  NoteE5=53;   NoteE6=65;   NoteE7=77;   NoteE8=89;
  NoteF5=54;   NoteF6=66;   NoteF7=78;   NoteF8=90;
  NoteFs5=55;  NoteFs6=67;  NoteFs7=79;  NoteFs8=91;
  NoteG5=56;   NoteG6=68;   NoteG7=80;   NoteG8=92;
  NoteGs5=57;  NoteGs6=69;  NoteGs7=81;  NoteGs8=93;
  NoteA5=58;   NoteA6=70;   NoteA7=82;   NoteA8=94;
  NoteAs5=59;  NoteAs6=71;  NoteAs7=83;  NoteAs8=95;
  NoteB5=60;   NoteB6=72;   NoteB7=84;   NoteB8=96;

  NoteStop=97;

  EffectArpeggio=$00;
  EffectPortaUp=$01;
  EffectPortaDown=$02;
  EffectTonePorta=$03;
  EffectVibrato=$04;
  EffectTonePortaVolumeSlide=$05;
  EffectVibratoVolumeSlide=$06;
  EffectTremolo=$07;
  EffectPanning=$08;
  EffectSampleOffset=$09;
  EffectVolumeSlide=$0A;
  EffectPatternJump=$0B;
  EffectVolume=$0C;
  EffectPatternBreak=$0D;
  EffectExtendedEffects=$0E;
  EffectSpeedTempo=$0F;
  EffectGlobalVolume=$10;
  EffectGlobalVolumeSlide=$11;
  EffectKeyOff=$14;
  EffectSetEnvelopePosition=$15;
  EffectPanningSlide=$19;
  EffectResonance=$1A;
  EffectMultiRetrig=$1B;
  EffectTremor=$1D;
  EffectExtraFinePorta=$21;
  EffectMacro=$23;
  EffectSmoothMacro=$25;

  ExtendedEffectFinePortaUp=$1;
  ExtendedEffectFinePortaDown=$2;
  ExtendedEffectSetGlissControl=$3;
  ExtendedEffectSetVibratoType=$4;
  ExtendedEffectSetFineTune=$5;
  ExtendedEffectPatternLoop=$6;
  ExtendedEffectSetTremoloType=$7;
  ExtendedEffectRetrig=$9;
  ExtendedEffectFineVolumeSlideUp=$A;
  ExtendedEffectFineVolumeSlideDown=$B;
  ExtendedEffectNoteCut=$C;
  ExtendedEffectNoteDelay=$D;
  ExtendedEffectPatternDelay=$E;
  ExtendedEffectSetActiveMacro=$F;

type
  PSampleValue=^TSampleValue;
  TSampleValue=integer;

  PSampleData=^TSampleData;
  TSampleData=array[0..($7FFFFFFF div SizeOf(TSampleValue))-1] of TSampleValue;

  TPatternNote=record
    Note,Instrument,Volume,Effect,EffectParameter:integer;
  end;

  TSample=class
  public
    Data:PSampleData;
    SampleLength:integer; // in bytes
    Bits:integer;
    Channels:integer;
    ADPCM4:boolean;
    Name:string;
    Loop:boolean;
    PingPongLoop:boolean;
    LoopStart:integer;
    LoopLength:integer;
    Volume:integer;
    Panning:integer;
    RelativeNote:integer;
    FineTune:integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Resize(Samples:integer);
  end;

  TEnvelopePoint=record
    Tick:integer;
    Value:integer;
  end;

  TEnvelope=class
  public
    Active:boolean;
    Loop:boolean;
    Sustain:boolean;
    Points:array[0..12] of TEnvelopePoint;
    NumberOfPoints:integer;
    LoopStartPoint:integer;
    LoopEndPoint:integer;
    SustainPoint:integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;                                    

  TSamples=array[0..LastSample] of TSample;
     
  TInstrumentSampleMap=array[1..96] of byte;

  TInstrument=class
  public
    Name:string;
    InstrumentType:integer;
    Sample:TSamples;
    SampleMap:TInstrumentSampleMap;
    VolumeEnvelope:TEnvelope;
    PanningEnvelope:TEnvelope;
    FadeOut:integer;
    VibratoType:integer;
    VibratoSweep:integer;
    VibratoDepth:integer;
    VibratoRate:integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;
  
  TInstruments=array[1..LastInstrument] of TInstrument;

  TEnvelopeHandler=class
  public
    Envelope:TEnvelope;
    constructor Create;
    destructor Destroy; override;
    procedure Assign(From:TEnvelopeHandler);
  end;

  TXMModule=class;

  TPatternNotes=array of TPatternNote;

  TPattern=class
  public
    Pattern:TPatternNotes;
    Rows:integer;
    Channels:byte;
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source:TPattern);
    procedure Clear;
    procedure ClearPattern;
    function GetNote(Row,Channel:integer):TPatternNote;
    procedure SetNote(Row,Channel:integer;Note:TPatternNote);
    procedure Resize(NewRows:integer;NewChannels:byte);
    function IsEmpty:boolean;
  end;
  TPatterns=array[0..LastPattern] of TPattern;

  TPatternOrder=array[0..LastPatternOrder] of byte;

  TXMModule=class
  public
    Name:string;
    Comment:string;
    Instrument:TInstruments;
    Pattern:TPatterns;
    PatternOrder:TPatternOrder;
    GlobalVolume:integer;
    MasterVolume:integer;
    StartSpeed:byte; // in frames/row
    StartTempo:byte; // in beats per minute
    TrackLength:integer;
    RestartPosition:integer;
    LinearSlides:boolean;
    ExtendedFilterRange:boolean;
    NumberOfChannels:integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function LoadMemory(DataPointer:pointer;DataSize:longword):boolean;
    function Load(Data:TStream):boolean;
    function LoadFile(FileName:string):boolean;
    function LoadFromResource(Instance:THandle;const ResName:string;ResType:pchar):boolean;
    function Save(Data:TStream):boolean;
    function SaveFile(FileName:string):boolean;
    function NumberOfPatterns:integer; {ADD by Grom PE}
    function NumberOfInstruments:integer; {ADD by Grom PE}
  end;

implementation

type
  TXMHeader=packed record
    Signature:array[0..16] of char;
    Name:array[0..19] of char;
    End1AValue:byte;
    Tracker:array[0..19] of char;
    Version:word;
    Size:longword;
    TrackLength:word;
    RestartPosition:word;
    NumberOfChannels:word;
    NumberOfPatterns:word;
    NumberOfInstruments:word;
    Flags:word;
    Speed:word;
    Tempo:word;
    PatternOrder:TPatternOrder;
  end;

  TXMInstrumentHeader=packed record
    Size:longword;
    Name:packed array[0..22-1] of char;
    InstrumentType:byte;
    CountOfSamples:word;
  end;

  TXMPatternHeader=packed record
    Size:longword;
    PackingType:byte;
    Rows:word;
    PackedSize:word;
  end;

  TXMOldPatternHeader=packed record
    Size:longword;
    PackingType:byte;
    Rows:byte;
    PackedSize:word;
  end;

  TXMInstrumentExtraHeader=packed record
    Size:longword;
    SampleMap:packed array[1..96] of byte;
    VolumeEnvelope:packed array[0..24-1] of word;
    PanningEnvelope:packed array[0..24-1] of word;
    VolumeEnvelopeNumPoints:byte;
    PanningEnvelopeNumPoints:byte;
    VolumeEnvelopeSustain:byte;
    VolumeEnvelopeLoopStart:byte;
    VolumeEnvelopeLoopEnd:byte;
    PanningEnvelopeSustain:byte;
    PanningEnvelopeLoopStart:byte;
    PanningEnvelopeLoopEnd:byte;
    VolFlags:byte;
    PanFlags:byte;
    VibratoType:byte;
    VibratoSweep:byte;
    VibratoDepth:byte;
    VibratoRate:byte;
    FadeOut:word;
    Reserved:word;
  end;

  TXMSampleHeader=packed record
    SampleLength:longword;
    LoopStart:longword;
    LoopLength:longword;
    Volume:byte;
    FineTune:shortint;
    Flags:byte;
    Panning:byte;
    RelativeNote:shortint;
    Reserved:byte;
    Name:packed array[0..22-1] of char;
  end;

  TMODSample=packed record
    Name:array[0..21] of char;
    LengthCounter:word;
    FineTune:byte;
    Volume:byte;
    LoopStart:word;
    LoopLength:word;
  end;

  TMODHeader15=packed record
    Title:array[0..19] of char;
    Samples:array[1..15] of TMODSample;
    TrackLength:byte;
    RestartPosition:byte;
    PatternOrder:array[0..127] of byte;
  end;

  TMODHeader31=packed record
    Title:array[0..19] of char;
    Samples:array[1..31] of TMODSample;
    TrackLength:byte;
    RestartPosition:byte;
    PatternOrder:array[0..127] of byte;
    Tag:array[0..3] of char;
  end;

function SwapWordBigEndian(Value:word):word; register;
begin
  Result:=((Value and $ff00) shr 8) or ((Value and $ff) shl 8);
end;

constructor TSample.Create;
begin
  inherited Create;
  Data:=nil;
  Clear;
end;

destructor TSample.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TSample.Clear;
begin
  if assigned(Data) then
  begin
    freemem(Data);
    Data:=nil;
  end;
  Bits:=8;
  Channels:=1;
  Name:='';
  Loop:=False;
  PingPongLoop:=False;
  LoopStart:=0;
  LoopLength:=0;
  Volume:=64;
  Panning:=128;
  RelativeNote:=0;
  FineTune:=0;
end;

procedure TSample.Resize(Samples:integer);
begin
  if Samples=0 then
  begin
    if Assigned(Data) then
    begin
      FreeMem(Data);
    end;
    Data:=nil;
  end else begin
    if Assigned(Data) then
    begin
      ReallocMem(Data,Samples*SizeOf(TSampleValue));
    end else begin
      GetMem(Data,Samples*SizeOf(TSampleValue));
      FillChar(Data^,Samples*SizeOf(TSampleValue),#0);
    end;
  end;
end;

constructor TEnvelope.Create;
begin
  inherited Create;
  Clear;
end;

destructor TEnvelope.Destroy;
begin
  inherited Destroy;
end;

procedure TEnvelope.Clear;
begin
  FillChar(Points,SizeOf(Points),#0);
  Active:=False;
  Loop:=False;
  Sustain:=False;
  NumberOfPoints:=0;
  LoopStartPoint:=0;
  LoopEndPoint:=0;
  SustainPoint:=0;
end;

constructor TInstrument.Create;
var Counter:integer;
begin
  inherited Create;
  VolumeEnvelope:=TEnvelope.Create;
  PanningEnvelope:=TEnvelope.Create;
  for Counter:=0 to LastSample do Sample[Counter]:=nil;
  Clear;
end;

destructor TInstrument.Destroy;
begin
  Clear;
  VolumeEnvelope.Destroy;
  PanningEnvelope.Destroy;
  inherited Destroy;
end;

procedure TInstrument.Clear;
var Counter:integer;
begin
  for Counter:=0 to LastSample do
  begin
    if Assigned(Sample[Counter]) then Sample[Counter].Destroy;
    Sample[Counter]:=nil;
  end;
  for Counter:=1 to 96 do SampleMap[Counter]:=0;
  VolumeEnvelope.Clear;
  PanningEnvelope.Clear;
  FadeOut:=0;
  VibratoType:=0;
  VibratoSweep:=0;
  VibratoDepth:=0;
  VibratoRate:=0;
end;

constructor TEnvelopeHandler.Create;
begin
  inherited Create;
  Envelope:=nil;
end;

destructor TEnvelopeHandler.Destroy;
begin
  inherited Destroy;
end;

procedure TEnvelopeHandler.Assign(From:TEnvelopeHandler);
begin
  Envelope:=From.Envelope;
end;

constructor TPattern.Create;
begin
  inherited Create;
  Pattern:=nil;
  Channels:=0;
  Rows:=0;
  Clear;
end;

destructor TPattern.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TPattern.Assign(Source:TPattern);
begin
  if Assigned(Source) then
  begin
    Rows:=Source.Rows;
    Channels:=Source.Channels;
    Pattern:=Copy(Source.Pattern); {FIX by Grom PE}
  end;
end;

procedure TPattern.Clear;
begin
  if Assigned(Pattern) then
  begin
    SetLength(Pattern,0);
    Pattern:=nil;
  end;
end;

procedure TPattern.ClearPattern;
var Row,Channel:integer;
    EmptyNote:TPatternNote;
begin
  FillChar(EmptyNote,SizeOf(TPatternNote),#0);
  for Row:=0 to Rows-1 do
  begin
    for Channel:=0 to Channels-1 do
    begin
      Pattern[(Row*Channels)+Channel]:=EmptyNote;
    end;
  end;
end;

function TPattern.GetNote(Row,Channel:integer):TPatternNote;
var Cell:integer;
begin
  FillChar(Result,SizeOf(TPatternNote),#0);
  Cell:=(Row*Channels)+Channel;
  if Cell<Length(Pattern) then Result:=Pattern[Cell];
end;

procedure TPattern.SetNote(Row,Channel:integer;Note:TPatternNote);
var Cell:integer;
begin
  Cell:=(Row*Channels)+Channel;
  if Cell<Length(Pattern) then Pattern[Cell]:=Note;
end;

procedure TPattern.Resize(NewRows:integer;NewChannels:byte);
var OldRows,OldChannels,Row,Channel:integer;
    OldPattern:TPatternNotes;
    EmptyNote:TPatternNote;
begin
  {FIX by Grom PE}
  OldRows:=Rows;
  OldChannels:=Channels;
  {/FIX}
  Rows:=NewRows;
  Channels:=NewChannels;
  if (Rows>0) and (Channels>0) then
  begin
    OldPattern:=Pattern;
    Pattern:=nil;
    SetLength(Pattern,(Rows+1)*Channels);
    FillChar(EmptyNote,SizeOf(TPatternNote),#0);

    for Row:=0 to Rows-1 do
    begin
      for Channel:=0 to Channels-1 do
      begin
        if Channel<OldChannels then {FIX by Grom PE}
        begin
          if Row<OldRows then
          begin
            Pattern[(Row*Channels)+Channel]:=OldPattern[(Row*OldChannels)+Channel];
          end else begin
            Pattern[(Row*Channels)+Channel]:=EmptyNote;
          end;
        end else begin
          Pattern[(Row*Channels)+Channel]:=EmptyNote;
        end;
      end;
    end;
    SetLength(OldPattern,0);
  end else if Assigned(Pattern) then
  begin
    SetLength(Pattern,0);
  end;
end;

function TPattern.IsEmpty:boolean;
var Row,Channel:integer;
    Note:TPatternNote;
begin
  Result:=True;
  for Row:=0 to Rows-1 do
  begin
    for Channel:=0 to Channels-1 do
    begin
      Note:=Pattern[(Row*Channels)+Channel];
      if (Note.Note<>0) or (Note.Instrument<>0) or (Note.Volume<>0) or
            (Note.Effect<>0) or (Note.EffectParameter<>0) then
      begin
        Result:=False;
        Exit;
      end;
    end;
  end;
end;

constructor TXMModule.Create;
var Counter:integer;
begin
  inherited Create;
  MasterVolume:=128;
  for Counter:=1 to LastInstrument do Instrument[Counter]:=nil;
  for Counter:=0 to LastPattern do
  begin
    Pattern[Counter]:=TPattern.Create;
  end;
end;

destructor TXMModule.Destroy;
var Counter:integer;
begin
  Clear;
  for Counter:=0 to LastPattern do
  begin
    Pattern[Counter].Destroy;
  end;
  inherited Destroy;
end;

procedure TXMModule.Clear;
var Counter:integer;
begin
  GlobalVolume:=64;
  Name:='';
  Comment:='';
  for Counter:=1 to LastInstrument do
  begin
    if Assigned(Instrument[Counter]) then
    begin
      Instrument[Counter].Destroy;
      Instrument[Counter]:=nil;
    end;
  end;
  for Counter:=0 to LastPattern do Pattern[Counter].Clear;
  FillChar(PatternOrder,SizeOf(TPatternOrder),#0);
  StartSpeed:=6;
  StartTempo:=125;
  TrackLength:=0;
  RestartPosition:=0;
  LinearSlides:=True;
  ExtendedFilterRange:=False;
end;

function TXMModule.LoadMemory(DataPointer:pointer;DataSize:longword):boolean;
var DataPosition,NextDataPosition:longword;
    Header:TXMHeader;
    EmptyNote,ANote:TPatternNote;
    NumberOfPatterns:integer;
    NumberOfInstruments:integer;
    InstrumentSamplesCount:array[0..LastInstrument] of integer;

  function Read(var Buffer;LengthCounter:longword):longword;
  var RealSize:longword;
  begin
    RealSize:=LengthCounter;
    if (DataPosition+RealSize)>DataSize then RealSize:=DataSize-DataPosition;
    if RealSize<>LengthCounter then FillChar(Buffer,LengthCounter,#0);
    if RealSize>0 then
    begin
      Move(PStreamData(DataPointer)^[DataPosition],Buffer,RealSize);
    end;
    Inc(DataPosition,RealSize);
    Result:=RealSize;
  end;

  function StreamRead(Stream:TStream;LengthCounter:longword):longword;
  var RealSize:longword;
  begin
    RealSize:=LengthCounter;
    if (DataPosition+RealSize)>DataSize then RealSize:=DataSize-DataPosition;
    if RealSize>0 then
    begin
      Stream.Read(PStreamData(DataPointer)^[DataPosition],RealSize);
    end;
    Inc(DataPosition,RealSize);
    Result:=RealSize;
   end;

  function ReadByte:byte;
  begin
    Read(Result,SizeOf(BYTE));
  end;

  function ReadShortInt:shortint;
  begin
    Read(Result,SizeOf(shortint));
  end;

  function ReadSmallInt:smallint;
  begin
    Read(Result,SizeOf(smallint));
  end;

  procedure ReadADPCM4Sample(Size:longword;Sample:TSample);
  var AByte:byte;
      Delta:shortint;
      Counter,SampleCounter,HalfLength:longword;
      ADPCM4Table:array[0..15] of BYTE;
      Buffer:array of shortint;
  begin
    SetLength(Buffer,Size);
    Read(ADPCM4Table,16);
    HalfLength:=(Size+1) div 2;
    Delta:=0;
    for Counter:=0 to HalfLength-1 do
    begin
      AByte:=ReadByte;
      Delta:=shortint(BYTE(BYTE(Delta)+ADPCM4Table[AByte and $F]));
      Buffer[Counter*2]:=Delta;
      Delta:=shortint(BYTE(BYTE(Delta)+ADPCM4Table[AByte shr 4]));
      Buffer[(Counter*2)+1]:=Delta;
    end;
    Sample.Resize(Size);
    if Sample.Channels=2 then
    begin
      SampleCounter:=0;
      for Counter:=0 to (Size div 2)-1 do
      begin
        Sample.Data[SampleCounter]:=Buffer[Counter]*256;
        Inc(SampleCounter);
        Sample.Data[SampleCounter]:=Buffer[Counter+(Size div 2)]*256;
        Inc(SampleCounter);
      end;
    end else begin
      for Counter:=0 to Size-1 do Sample.Data[Counter]:=Buffer[Counter]*256;
    end;
    SetLength(Buffer,0);
  end;
  procedure Read8BitSample(Size:longword;Sample:TSample);
  var Counter,SampleCounter:longword;
          Current,Last,New:shortint;
  begin
    Sample.Resize(Size);
    if Sample.Channels=2 then
    begin
      Last:=0;
      SampleCounter:=0;
      for Counter:=0 to (Size div 2)-1 do
      begin
        Current:=ReadShortInt;
        New:=Current+Last;
        Sample.Data[SampleCounter]:=New*256;
        Inc(SampleCounter,2);
        Last:=New;
      end;
      Last:=0;
      SampleCounter:=1;
      for Counter:=0 to (Size div 2)-1 do
      begin
        Current:=ReadShortInt;
        New:=Current+Last;
        Sample.Data[SampleCounter]:=New*256;
        Inc(SampleCounter,2);
        Last:=New;
      end;
    end else begin
      Last:=0;
      for Counter:=0 to Size-1 do
      begin
        Current:=ReadShortInt;
        New:=Current+Last;
        Sample.Data[Counter]:=New*256;
        Last:=New;
      end;
    end;
  end;
  procedure Read16BitSample(Size:longword;Sample:TSample);
  var Counter,SampleCounter:longword;
          Current,Last,New:smallint;
  begin
    Sample.Resize(Size div 2);
    if Sample.Channels=2 then
    begin
      Last:=0;
      SampleCounter:=0;
      for Counter:=0 to (Size div 4)-1 do
      begin
        Current:=ReadSmallInt;
        New:=Current+Last;
        Sample.Data[SampleCounter]:=New;
        Inc(SampleCounter,2);
        Last:=New;
      end;
      Last:=0;
      SampleCounter:=1;
      for Counter:=0 to (Size div 4)-1 do
      begin
        Current:=ReadSmallInt;
        New:=Current+Last;
        Sample.Data[SampleCounter]:=New;
        Inc(SampleCounter,2);
        Last:=New;
      end;
    end else begin
      Last:=0;
      for Counter:=0 to (Size div 2)-1 do
      begin
        Current:=ReadSmallInt;
        New:=Current+Last;
        Sample.Data[Counter]:=New;
        Last:=New;
      end;
    end;
  end;
  function MOD2XMNote(Period:longword):longword;
  const AmigaMODPeriods:array[1..60] of WORD=(1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906,856,808,762,720,678,640,604,570,538,508,480,453,428,404,381,360,339,320,302,285,269,254,240,226,214,202,190,180,170,160,151,143,135,127,120,113,107,101,
95,90,85,80,75,71,67,63,60,56);
  var Note:longword;
  begin
    Result:=0;
    if Period>0 then
    begin
      for Note:=1 to 60 do
      begin
        if Period>=AmigaMODPeriods[Note] then
        begin
          Result:=Note+24;
          BREAK;
        end;
      end;
    end;
  end;
  function MOD2XMFineTune(FineTune:LONGINT):LONGINT;
  begin
    Result:=FineTune;
    if Result<0 then Result:=0;
    if Result>15 then Result:=15;
    if Result>7 then Result:=-(8-(Result-8));
    Result:=Result*16;
  end;
  function LoadMOD:boolean;
  var TotalSampleLength,PatternStartPosition,PatternA,PatternB,
          HowManyChannels,HowManySamples,HowManyPatterns:longword;
          ASample:TMODSample;
          OldMODFormat:LONGBOOL;
          Counter,SampleCounter,RowCounter,ChannelChannel:integer;
          Buffer:array[1..4] of BYTE;
          S:shortint;
          Header15:TMODHeader15;
          Header31:TMODHeader31;
          ADPCM:array[1..5] of char;
  begin
    Result:=False;
    OldMODFormat:=False;

    HowManyChannels:=0;
    HowManySamples:=31;

    Name:='';

    DataPosition:=0;
    Read(Header31,SizeOf(TMODHeader31));

    if Header31.Tag[0]='P' then if Header31.Tag[1]='P' then Exit;
    if (Header31.Tag='M.K.') or (Header31.Tag='M!K!') or (Header31.Tag='M&K!') or (Header31.Tag='N.T.') then
    begin
      HowManyChannels:=4;
    end else if (Header31.Tag='OCTA') or (Header31.Tag='OKTA') or (Header31.Tag='CD81') or (Header31.Tag='WOW!') then
    begin
      HowManyChannels:=8;
    end else if (Header31.Tag[0]='T') and (Header31.Tag[1]='D') and (Header31.Tag[2]='Z') then
    begin
      HowManyChannels:=ORD(Header31.Tag[3])-48;
    end else if (Header31.Tag[0]='F') and (Header31.Tag[1]='L') and (Header31.Tag[2]='T') then
    begin
      HowManyChannels:=ORD(Header31.Tag[3])-48;
      if not HowManyChannels IN [1..8] then HowManyChannels:=0;
    end else if (Header31.Tag[0]='E') and (Header31.Tag[1]='X') and (Header31.Tag[2]='O') then
    begin
      HowManyChannels:=ORD(Header31.Tag[3])-48;
      if not HowManyChannels IN [1..8] then HowManyChannels:=0;
    end else if (Header31.Tag[1]='C') and (Header31.Tag[2]='H') and (Header31.Tag[3]='N') then
    begin
      HowManyChannels:=ORD(Header31.Tag[0])-48;
    end else if (Header31.Tag[2]='C') and (Header31.Tag[3]='N') then
    begin
      HowManyChannels:=((ORD(Header31.Tag[0])-48)*10)+(ORD(Header31.Tag[1])-48);
    end else if (Header31.Tag[2]='C') and (Header31.Tag[3]='H') then
    begin
      HowManyChannels:=((ORD(Header31.Tag[0])-48)*10)+(ORD(Header31.Tag[1])-48);
    end else if (Header31.Tag[0]='E') and (Header31.Tag[1]='X') then
    begin
      HowManyChannels:=((ORD(Header31.Tag[2])-48)*10)+(ORD(Header31.Tag[3])-48);
    end;
    if HowManyChannels=0 then
    begin
      HowManySamples:=15;
      HowManyChannels:=4;
      OldMODFormat:=True;

      DataPosition:=0;
      Read(Header15,SizeOf(TMODHeader15));

      Name:=Header15.Title;

      TrackLength:=Header15.TrackLength;
      RestartPosition:=Header15.RestartPosition;

      Move(Header15.PatternOrder,PatternOrder,128);
    end else begin
      Name:=Header31.Title;

      TrackLength:=Header31.TrackLength;
      RestartPosition:=Header31.RestartPosition;

      Move(Header31.PatternOrder,PatternOrder,128);
    end;

    if RestartPosition>TrackLength then RestartPosition:=0;

    TotalSampleLength:=0;
    for Counter:=1 to HowManySamples do
    begin
      if OldMODFormat then
      begin
        ASample:=Header15.Samples[Counter];
      end else begin
        ASample:=Header31.Samples[Counter];
      end;
      if not Assigned(Instrument[Counter]) then Instrument[Counter]:=TInstrument.Create;
      Instrument[Counter].Clear;
      Instrument[Counter].FadeOut:=65536;
      Instrument[Counter].VolumeEnvelope.Active:=False;
      Instrument[Counter].PanningEnvelope.Active:=False;
      Instrument[Counter].VibratoRate:=0;
      if not Assigned(Instrument[Counter].Sample[0]) then Instrument[Counter].Sample[0]:=TSample.Create;
      Instrument[Counter].Sample[0].Clear;
      Instrument[Counter].Sample[0].Bits:=8;
      Instrument[Counter].Sample[0].Channels:=1;
      Instrument[Counter].Sample[0].SampleLength:=SwapWordBigEndian(ASample.LengthCounter) shl 1;
      Instrument[Counter].Sample[0].LoopStart:=SwapWordBigEndian(ASample.LoopStart) shl 1;
      Instrument[Counter].Sample[0].LoopLength:=SwapWordBigEndian(ASample.LoopLength) shl 1;
      Instrument[Counter].Sample[0].Loop:=False;
      Instrument[Counter].Sample[0].FineTune:=MOD2XMFineTune(ASample.FineTune);
      Instrument[Counter].Sample[0].Volume:=ASample.Volume;
      Instrument[Counter].Sample[0].Panning:=128;
      Instrument[Counter].Sample[0].Name:=ASample.Name; {ADD by Grom PE}
      Inc(TotalSampleLength,Instrument[Counter].Sample[0].SampleLength);
    end;

    if OldMODFormat then
    begin
      PatternStartPosition:=SizeOf(TMODHeader15);
    end else begin
      PatternStartPosition:=SizeOf(TMODHeader31);
    end;

    PatternB:=0;
    for Counter:=0 to 127 do if PatternOrder[Counter]<=127 then
    begin
      if PatternOrder[Counter]>PatternB then PatternB:=PatternOrder[Counter];
    end;
    Inc(PatternB);

    if HowManyChannels=4 then
    begin
      if longword(PatternStartPosition+(PatternB*8*4*64)+TotalSampleLength)=DataSize then
      begin
        HowManyChannels:=8;
      end;
    end;

    PatternA:=(longword(DataSize)-PatternStartPosition-TotalSampleLength) div ((((1024 div 4)*HowManyChannels) div 64)*64);

    if OldMODFormat or (((PatternA>64) and (PatternB<=64))) then
    begin
      PatternA:=PatternB;
    end;
    if PatternA=PatternB then
    begin
      HowManyPatterns:=PatternA;
    end else begin
      if PatternB<PatternA then
      begin
        HowManyPatterns:=PatternB;
      end else if ((PatternB>64) and ((Header31.Tag<>'M!K!') and not OldMODFormat)) then
      begin
        HowManyPatterns:=PatternA;
      end else begin
        HowManyPatterns:=PatternB;
      end;
    end;
    if HowManyPatterns>128 then HowManyPatterns:=128;

    if longword(PatternStartPosition+(HowManyPatterns*HowManyChannels*4*64)+TotalSampleLength)<>DataSize then
    begin
      Clear;
      Exit;
    end;

    for Counter:=0 to HowManyPatterns-1 do
    begin
      Pattern[Counter].Resize(64,HowManyChannels);
      for RowCounter:=0 to 63 do
      begin
        for ChannelChannel:=0 to HowManyChannels-1 do
        begin
          Read(Buffer,4);
          ANote.Note:=MOD2XMNote(((Buffer[1] and $0F) shl 8) or Buffer[2]);
          ANote.Instrument:=(Buffer[1] and $F0) or (Buffer[3] shr 4);
          ANote.Volume:=0;
          ANote.Effect:=Buffer[3] and $F;
          ANote.EffectParameter:=Buffer[4];
          Pattern[Counter].SetNote(RowCounter,ChannelChannel,ANote);
        end;
      end;
    end;

    for Counter:=1 to HowManySamples do
    begin
      if Instrument[Counter].Sample[0].SampleLength>1 then
      begin
        if Instrument[Counter].Sample[0].LoopStart>Instrument[Counter].Sample[0].SampleLength then
        begin
          Instrument[Counter].Sample[0].LoopStart:=0;
          Instrument[Counter].Sample[0].LoopLength:=0;
        end;
        if (Instrument[Counter].Sample[0].LoopStart+Instrument[Counter].Sample[0].LoopLength)>Instrument[Counter].Sample[0].SampleLength then
        begin
          Instrument[Counter].Sample[0].LoopLength:=Instrument[Counter].Sample[0].SampleLength-Instrument[Counter].Sample[0].LoopStart;
          if Instrument[Counter].Sample[0].LoopLength<2 then Instrument[Counter].Sample[0].LoopLength:=2;
        end;
        Instrument[Counter].Sample[0].Loop:=Instrument[Counter].Sample[0].LoopLength>2;
        if Instrument[Counter].Sample[0].SampleLength>0 then
        begin
          Read(ADPCM,SizeOf(ADPCM));
          if ADPCM='ADPCM' then
          begin
            ReadADPCM4Sample(Instrument[Counter].Sample[0].SampleLength,Instrument[Counter].Sample[0]);
          end else begin
            Dec(DataPosition,4);
            Instrument[Counter].Sample[0].Resize(Instrument[Counter].Sample[0].SampleLength);
            for SampleCounter:=0 to Instrument[Counter].Sample[0].SampleLength-1 do
            begin
              Read(S,SizeOf(shortint));
              Instrument[Counter].Sample[0].Data^[SampleCounter]:=S*256;
            end;
          end;
        end;
      end;
    end;

    NumberOfChannels:=HowManyChannels;

    LinearSlides:=False;

    Result:=True;
  end;
  function LoadPatterns:boolean;
  var PatternCounter,RowChannel,ChannelCounter,Rows:integer;
          PackedSize:longword;
          PatternHeader:TXMPatternHeader;
          OldPatternHeader:TXMOldPatternHeader;
          ANote:TPatternNote;
          AByte:byte;
  begin
    for PatternCounter:=0 to NumberOfPatterns-1 do
    begin
      if Header.Version<=$102 then
      begin
        if Read(OldPatternHeader,SizeOf(TXMOldPatternHeader))<>SizeOf(TXMOldPatternHeader) then
        begin
          Clear;
          Result:=False;
          Exit;
        end;
        PackedSize:=OldPatternHeader.PackedSize;
        Rows:=OldPatternHeader.Rows+1;
      end else begin
        if Read(PatternHeader,SizeOf(TXMPatternHeader))<>SizeOf(TXMPatternHeader) then
        begin
          Clear;
          Result:=False;
          Exit;
        end;
        PackedSize:=PatternHeader.PackedSize;
        Rows:=PatternHeader.Rows;
      end;
      Pattern[PatternCounter].Clear;
      Pattern[PatternCounter].Resize(Rows,NumberOfChannels);
      if PackedSize>0 then
      begin
        NextDataPosition:=DataPosition+PackedSize;
        if (Rows>256) or (Rows=0) then
        begin
          DataPosition:=NextDataPosition;
          CONTINUE;
        end;
        for RowChannel:=0 to Rows-1 do
        begin
          for ChannelCounter:=0 to NumberOfChannels-1 do
          begin
            ANote:=EmptyNote;
            AByte:=ReadByte;
            if (AByte and 128)=0 then
            begin
              ANote.Note:=AByte;
              ANote.Instrument:=ReadByte;
              ANote.Volume:=ReadByte;
              ANote.Effect:=ReadByte;
              ANote.EffectParameter:=ReadByte;
            end;
            if (AByte and 128)<>0 then
            begin
              if (AByte and 1)<>0 then ANote.Note:=ReadByte;
              if (AByte and 2)<>0 then ANote.Instrument:=ReadByte;
              if (AByte and 4)<>0 then ANote.Volume:=ReadByte;
              if (AByte and 8)<>0 then ANote.Effect:=ReadByte;
              if (AByte and 16)<>0 then ANote.EffectParameter:=ReadByte;
            end;
            if ANote.Instrument=$FF then ANote.Instrument:=0;
            Pattern[PatternCounter].SetNote(RowChannel,ChannelCounter,ANote);
          end;
        end;
        DataPosition:=NextDataPosition;
      end;
    end;
    Result:=True;
  end;
  function LoadInstrumentSamplesData(InstrumentCounter,SamplesCount:integer):boolean;
  var SampleCounter:integer;
  begin
    for SampleCounter:=0 to SamplesCount-1 do
    begin
      NextDataPosition:=DataPosition;
      Inc(NextDataPosition,Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength);
      if Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength>MaxSampleSize then
      begin
        Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength:=MaxSampleSize;
        if Instrument[InstrumentCounter].Sample[SampleCounter].LoopStart>Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength then
        begin
          Instrument[InstrumentCounter].Sample[SampleCounter].LoopStart:=0;
          Instrument[InstrumentCounter].Sample[SampleCounter].Loop:=False;
        end;
      end;
      if Assigned(Instrument[InstrumentCounter].Sample[SampleCounter]) then
      begin
        if Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength>0 then
        begin
          if Instrument[InstrumentCounter].Sample[SampleCounter].ADPCM4 then
          begin
            ReadADPCM4Sample(Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength,Instrument[InstrumentCounter].Sample[SampleCounter]);
          end else if Instrument[InstrumentCounter].Sample[SampleCounter].Bits=16 then
          begin
            Read16BitSample(Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength,Instrument[InstrumentCounter].Sample[SampleCounter]);
            Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength:=Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength div 2;
            Instrument[InstrumentCounter].Sample[SampleCounter].LoopStart:=Instrument[InstrumentCounter].Sample[SampleCounter].LoopStart div 2;
            Instrument[InstrumentCounter].Sample[SampleCounter].LoopLength:=Instrument[InstrumentCounter].Sample[SampleCounter].LoopLength div 2;
          end else begin
            Read8BitSample(Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength,Instrument[InstrumentCounter].Sample[SampleCounter]);
          end;
          if Instrument[InstrumentCounter].Sample[SampleCounter].Channels=2 then
          begin
            Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength:=Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength div 2;
            Instrument[InstrumentCounter].Sample[SampleCounter].LoopStart:=Instrument[InstrumentCounter].Sample[SampleCounter].LoopStart div 2;
            Instrument[InstrumentCounter].Sample[SampleCounter].LoopLength:=Instrument[InstrumentCounter].Sample[SampleCounter].LoopLength div 2;
          end;
        end;
      end;
      DataPosition:=NextDataPosition;
    end;
    Result:=True;
  end;
  function LoadInstruments:boolean;
  var InstrumentCounter,SampleCounter,SubCounter:integer;
          InstrumentHeader:TXMInstrumentHeader;
          InstrumentExtraHeader:TXMInstrumentExtraHeader;
          SampleHeader:TXMSampleHeader;
  begin
    for InstrumentCounter:=1 to NumberOfInstruments do
    begin
      if Read(InstrumentHeader,SizeOf(TXMInstrumentHeader))<>SizeOf(TXMInstrumentHeader) then
      begin
        Clear;
        Result:=False;
        Exit;
      end;
      if not Assigned(Instrument[InstrumentCounter]) then
      begin
        Instrument[InstrumentCounter]:=TInstrument.Create;
      end;
      Instrument[InstrumentCounter].Clear;
      Instrument[InstrumentCounter].Name:=InstrumentHeader.Name;
      if InstrumentHeader.CountOfSamples=0 then
      begin
        Inc(DataPosition,integer(InstrumentHeader.Size)-SizeOf(TXMInstrumentHeader));
      end else if InstrumentHeader.CountOfSamples>0 then
      begin
        if Read(InstrumentExtraHeader,SizeOf(TXMInstrumentExtraHeader))<>SizeOf(TXMInstrumentExtraHeader) then
        begin
          Clear;
          Result:=False;
          Exit;
        end;
        Inc(DataPosition,integer(InstrumentHeader.Size)-SizeOf(TXMInstrumentHeader)-SizeOf(TXMInstrumentExtraHeader));

        Instrument[InstrumentCounter].FadeOut:=InstrumentExtraHeader.FadeOut;

        for SubCounter:=1 to 96 do
        begin
          Instrument[InstrumentCounter].SampleMap[SubCounter]:=InstrumentExtraHeader.SampleMap[SubCounter];
        end;

        for SubCounter:=0 to 12-1 do
        begin
          Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Tick:=InstrumentExtraHeader.VolumeEnvelope[SubCounter*2];
          Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Value:=(BYTE(InstrumentExtraHeader.VolumeEnvelope[(SubCounter*2)+1]) and $FF);
          Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Tick:=InstrumentExtraHeader.PanningEnvelope[SubCounter*2];
          Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Value:=(BYTE(InstrumentExtraHeader.PanningEnvelope[(SubCounter*2)+1]) and $FF);
          if SubCounter>0 then
          begin
            if Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Tick<Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter-1].Tick then
            begin
              Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Tick:=Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Tick and $FF;
              Inc(Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Tick,Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter-1].Tick and $FF00);
              if Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Tick<Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter-1].Tick then Inc(Instrument[InstrumentCounter].VolumeEnvelope.Points[SubCounter].Tick,$100);
            end;
            if Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Tick<Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter-1].Tick then
            begin
              Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Tick:=Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Tick and $FF;
              Inc(Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Tick,Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter-1].Tick and $FF00);
              if Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Tick<Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter-1].Tick then Inc(Instrument[InstrumentCounter].PanningEnvelope.Points[SubCounter].Tick,$100);
            end;
          end;
        end;

        Instrument[InstrumentCounter].VolumeEnvelope.NumberOfPoints:=InstrumentExtraHeader.VolumeEnvelopeNumPoints;
        Instrument[InstrumentCounter].VolumeEnvelope.LoopStartPoint:=InstrumentExtraHeader.VolumeEnvelopeLoopStart;
        Instrument[InstrumentCounter].VolumeEnvelope.LoopEndPoint:=InstrumentExtraHeader.VolumeEnvelopeLoopEnd;
        Instrument[InstrumentCounter].VolumeEnvelope.SustainPoint:=InstrumentExtraHeader.VolumeEnvelopeSustain;

        Instrument[InstrumentCounter].PanningEnvelope.NumberOfPoints:=InstrumentExtraHeader.PanningEnvelopeNumPoints;
        Instrument[InstrumentCounter].PanningEnvelope.LoopStartPoint:=InstrumentExtraHeader.PanningEnvelopeLoopStart;
        Instrument[InstrumentCounter].PanningEnvelope.LoopEndPoint:=InstrumentExtraHeader.PanningEnvelopeLoopEnd;
        Instrument[InstrumentCounter].PanningEnvelope.SustainPoint:=InstrumentExtraHeader.PanningEnvelopeSustain;

        Instrument[InstrumentCounter].VolumeEnvelope.Active:=(InstrumentExtraHeader.VolFlags and 1)<>0;
        Instrument[InstrumentCounter].VolumeEnvelope.Sustain:=(InstrumentExtraHeader.VolFlags and 2)<>0;
        Instrument[InstrumentCounter].VolumeEnvelope.Loop:=(InstrumentExtraHeader.VolFlags and 4)<>0;
        Instrument[InstrumentCounter].PanningEnvelope.Active:=(InstrumentExtraHeader.PanFlags and 1)<>0;
        Instrument[InstrumentCounter].PanningEnvelope.Sustain:=(InstrumentExtraHeader.PanFlags and 2)<>0;
        Instrument[InstrumentCounter].PanningEnvelope.Loop:=(InstrumentExtraHeader.PanFlags and 4)<>0;

        if Instrument[InstrumentCounter].VolumeEnvelope.NumberOfPoints=0 then Instrument[InstrumentCounter].VolumeEnvelope.Active:=False;
        if Instrument[InstrumentCounter].PanningEnvelope.NumberOfPoints=0 then Instrument[InstrumentCounter].PanningEnvelope.Active:=False;
        if Instrument[InstrumentCounter].VolumeEnvelope.SustainPoint>12 then Instrument[InstrumentCounter].VolumeEnvelope.Sustain:=False;
        if Instrument[InstrumentCounter].PanningEnvelope.SustainPoint>12 then Instrument[InstrumentCounter].PanningEnvelope.Sustain:=False;
        if Instrument[InstrumentCounter].VolumeEnvelope.LoopStartPoint>=Instrument[InstrumentCounter].VolumeEnvelope.LoopEndPoint then Instrument[InstrumentCounter].VolumeEnvelope.Loop:=False;
        if Instrument[InstrumentCounter].PanningEnvelope.LoopStartPoint>=Instrument[InstrumentCounter].PanningEnvelope.LoopEndPoint then Instrument[InstrumentCounter].PanningEnvelope.Loop:=False;

        Instrument[InstrumentCounter].VibratoType:=InstrumentExtraHeader.VibratoType;
        Instrument[InstrumentCounter].VibratoSweep:=InstrumentExtraHeader.VibratoSweep;
        Instrument[InstrumentCounter].VibratoDepth:=InstrumentExtraHeader.VibratoDepth;
        Instrument[InstrumentCounter].VibratoRate:=InstrumentExtraHeader.VibratoRate;

        for SampleCounter:=0 to InstrumentHeader.CountOfSamples-1 do
        begin
          if Read(SampleHeader,SizeOf(SampleHeader))<>SizeOf(SampleHeader) then
          begin
            Clear;
            Result:=False;
            Exit;
          end;
          if SampleHeader.LoopStart>=SampleHeader.SampleLength then SampleHeader.Flags:=SampleHeader.Flags and not 3;
          if (SampleHeader.LoopStart+SampleHeader.LoopLength)>SampleHeader.SampleLength then
          begin
            SampleHeader.LoopLength:=SampleHeader.SampleLength-SampleHeader.LoopStart;
          end;
          if SampleHeader.LoopLength<=0 then SampleHeader.Flags:=SampleHeader.Flags and not 3;
          if not Assigned(Instrument[InstrumentCounter].Sample[SampleCounter]) then
          begin
            Instrument[InstrumentCounter].Sample[SampleCounter]:=TSample.Create;
          end;
          Instrument[InstrumentCounter].Sample[SampleCounter].Clear;
          Instrument[InstrumentCounter].Sample[SampleCounter].Name:=SampleHeader.Name;
          Instrument[InstrumentCounter].Sample[SampleCounter].SampleLength:=SampleHeader.SampleLength;
          Instrument[InstrumentCounter].Sample[SampleCounter].LoopStart:=SampleHeader.LoopStart;
          Instrument[InstrumentCounter].Sample[SampleCounter].LoopLength:=SampleHeader.LoopLength;
          Instrument[InstrumentCounter].Sample[SampleCounter].Volume:=SampleHeader.Volume;
          Instrument[InstrumentCounter].Sample[SampleCounter].FineTune:=SampleHeader.FineTune;
          Instrument[InstrumentCounter].Sample[SampleCounter].RelativeNote:=SampleHeader.RelativeNote;
          Instrument[InstrumentCounter].Sample[SampleCounter].Panning:=SampleHeader.Panning;
          Instrument[InstrumentCounter].Sample[SampleCounter].Bits:=8+(8*ORD((SampleHeader.Flags and 16)<>0));
          Instrument[InstrumentCounter].Sample[SampleCounter].Channels:=1+ORD((SampleHeader.Flags and 32)<>0);
          Instrument[InstrumentCounter].Sample[SampleCounter].ADPCM4:=(SampleHeader.Reserved=$AD) and ((SampleHeader.Flags and $30)=0);
          Instrument[InstrumentCounter].Sample[SampleCounter].Loop:=(SampleHeader.Flags and (1 or 2))<>0;
          Instrument[InstrumentCounter].Sample[SampleCounter].PingPongLoop:=(SampleHeader.Flags and 2)<>0;
        end;
        if Header.Version<=$103 then
        begin
          InstrumentSamplesCount[InstrumentCounter]:=InstrumentHeader.CountOfSamples;
        end else begin
          LoadInstrumentSamplesData(InstrumentCounter,InstrumentHeader.CountOfSamples);
        end;
      end;
    end;
    Result:=True;
  end;
  function LoadInstrumentSamples:boolean;
  var InstrumentCounter:integer;
  begin
    Result:=False;
    for InstrumentCounter:=1 to NumberOfInstruments do
    begin
      Result:=LoadInstrumentSamplesData(InstrumentCounter,InstrumentSamplesCount[InstrumentCounter]);
      if not Result then Exit;
    end;
  end;
  function LoadExtendedData:boolean;
  var Counter:integer;
          LastPosition,BlockLastPosition,BlockSize:longword;
          Signature:array[1..4] of char;
          CommentChar:char;
  begin
    LastPosition:=DataPosition;
    WHILE (DataPosition+8)<DataSize do
    begin
      BlockLastPosition:=DataPosition;
      if Read(Signature,4*SizeOf(char))<>(4*SizeOf(char)) then
      begin
        Result:=False;
        Exit;
      end;
      if Read(BlockSize,SizeOf(longword))<>SizeOf(longword) then
      begin
        Result:=False;
        Exit;
      end;
      if Signature='text' then
      begin
        Comment:='';
        for Counter:=0 to BlockSize-1 do
        begin
          if Read(CommentChar,1)<>1 then
          begin
            Result:=False;
            Exit;
          end;
          Comment:=Comment+CommentChar;
          if CommentChar=#13 then Comment:=Comment+#10;
        end;
      end else begin
        BREAK;
      end;
      DataPosition:=BlockLastPosition+BlockSize+8;
    end;
    DataPosition:=LastPosition;
    Result:=True;
  end;
begin
  Result:=False;
  Clear;
  DataPosition:=0;
  if Read(Header,SizeOf(TXMHeader))<>SizeOf(TXMHeader) then
  begin
    Clear;
    Result:=False;
    Exit;
  end;
  if (Header.Signature<>'Extended Module: ') or (Header.NumberOfChannels>LastChannel) or (Header.NumberOfInstruments>LastInstrument) then
  begin
    Clear;
    Result:=LoadMOD;
    Exit;
  end;

  Name:=Header.Name;
  TrackLength:=Header.TrackLength;
  RestartPosition:=Header.RestartPosition;
  NumberOfChannels:=Header.NumberOfChannels;
  NumberOfPatterns:=Header.NumberOfPatterns;
  NumberOfInstruments:=Header.NumberOfInstruments;

  LinearSlides:=(Header.Flags and $1)<>0;
  ExtendedFilterRange:=(Header.Flags and $1000)<>0;

  StartSpeed:=Header.Speed;
  StartTempo:=Header.Tempo;
  if StartSpeed=0 then StartSpeed:=6;
  if StartTempo=0 then StartTempo:=125;

  PatternOrder:=Header.PatternOrder;

  Inc(DataPosition,integer(Header.Size-(SizeOf(TXMHeader)-60)));

  FillChar(EmptyNote,SizeOf(TPatternNote),#0);

  if Header.Version<=$103 then
  begin
    FillChar(InstrumentSamplesCount,SizeOf(InstrumentSamplesCount),#0);
    if not LoadInstruments then Exit;
    if not LoadPatterns then Exit;
    if not LoadInstrumentSamples then Exit;
  end else begin
    if not LoadPatterns then Exit;
    if not LoadInstruments then Exit;
  end;

  LoadExtendedData;

  Result:=True;
end;

function TXMModule.Load(Data:TStream):boolean;
var DataPointer:pointer;
begin
  GetMem(DataPointer,Data.Size);
  Data.Seek(0);
  if Data.Read(DataPointer^,Data.Size)=Data.Size then
  begin
    Result:=LoadMemory(Data,Data.Size);
  end else begin
    Result:=False;
  end;
  FreeMem(DataPointer);
end;

function TXMModule.LoadFile(FileName:string):boolean;
var TheFile:THandle;
    Data:pointer;
    Size:longword;
    Temp:cardinal;
begin
  Result:=False;
  TheFile:=CreateFile(pchar(FileName),GENERIC_READ,0,nil,OPEN_EXISTING,0,0);
  if TheFile=INVALID_HANDLE_VALUE then Exit;
  Size:=GetFileSize(TheFile,nil);
  GetMem(Data,Size);
  ReadFile(TheFile,Data^,Size,Temp,nil);
  CloseHandle(TheFile);
  Result:=LoadMemory(Data,Size);
  FreeMem(Data);
end;

function TXMModule.LoadFromResource(Instance:THandle;const ResName:string;ResType:pchar):boolean;
var ResourceHandle,Handle:THandle;
    Data:pointer;
    Size:longword;
begin
  Result:=False;
  ResourceHandle:=FindResource(Instance,pchar(ResName),ResType);
  if ResourceHandle<>0 then
  begin
    Handle:=LoadResource(Instance,ResourceHandle);
    if Handle<>0 then
    begin
      Data:=LockResource(Handle);
      if Assigned(Data) then
      begin
        Size:=SizeOfResource(Instance,ResourceHandle);
        if Size>0 then
        begin
          Result:=LoadMemory(Data,Size);
        end;
      end;
      UnlockResource(Handle);
      FreeResource(Handle);
    end;
  end;
end;

function TXMModule.Save(Data:TStream):boolean;
var Header:TXMHeader;
    InstrumentHeader:TXMInstrumentHeader;
    InstrumentExtraHeader:TXMInstrumentExtraHeader;
    SampleHeader:TXMSampleHeader;
    Count,Counter,SubCounter,SubSubCounter,SampleCounter,SourceValue:integer;
    Sample:TSample;
    SampleBuffer:pointer;
    LastByte,DeltaByte:shortint;
    LastWord,DeltaWord:smallint;
    DestByte:pshortint;
    DestWord:psmallint;
    NumberOfSamples:integer;
    TrackComment:string;
    Value:longword;
  procedure WritePattern(PatternNummer:integer);
  var Row,Channel:integer;
      PatternHeader:TXMPatternHeader;
      PatternNote:TPatternNote;
      PatternDaten:TMemoryStream;
      Flags:byte;
    procedure WriteByte(B:byte);
    begin
      PatternDaten.Write(B,SizeOf(BYTE));
    end;
  begin
    PatternDaten:=TMemoryStream.Create;
    FillChar(PatternHeader,SizeOf(TXMPatternHeader),#0);
    PatternHeader.Size:=9;
    PatternHeader.PackingType:=0;
    PatternHeader.Rows:=Pattern[PatternNummer].Rows;
    if not Pattern[PatternNummer].IsEmpty then
    begin
      for Row:=0 to Pattern[PatternNummer].Rows-1 do
      begin
        for Channel:=0 to Pattern[PatternNummer].Channels-1 do
        begin
          PatternNote:=Pattern[PatternNummer].GetNote(Row,Channel);
          if (PatternNote.Note<>0) and (PatternNote.Instrument<>0) and (PatternNote.Volume>$F) and ((PatternNote.Effect<>EffectArpeggio) or (PatternNote.EffectParameter<>0)) then
          begin
            WriteByte(PatternNote.Note);
            WriteByte(PatternNote.Instrument);
            WriteByte(PatternNote.Volume);
            WriteByte(PatternNote.Effect);
            WriteByte(PatternNote.EffectParameter);
          end else begin
            Flags:=$80;
            if PatternNote.Note<>0 then Flags:=Flags or 1;
            if PatternNote.Instrument<>0 then Flags:=Flags or 2;
            if PatternNote.Volume>$F then Flags:=Flags or 4;
            if PatternNote.Effect<>EffectArpeggio then Flags:=Flags or 8;
            if PatternNote.EffectParameter<>0 then Flags:=Flags or 16;
            WriteByte(Flags);
            if (Flags and 1)<>0 then WriteByte(PatternNote.Note);
            if (Flags and 2)<>0 then WriteByte(PatternNote.Instrument);
            if (Flags and 4)<>0 then WriteByte(PatternNote.Volume);
            if (Flags and 8)<>0 then WriteByte(PatternNote.Effect);
            if (Flags and 16)<>0 then WriteByte(PatternNote.EffectParameter);
          end;
        end;
      end;
    end;
    PatternHeader.PackedSize:=PatternDaten.Size;
    Data.Write(PatternHeader,SizeOf(TXMPatternHeader));
    Data.Append(PatternDaten);
    PatternDaten.Free;
  end;
begin
  Result:=False;
  Data.Clear;

  FillChar(Header,SizeOf(TXMHeader),#0);
  Header.Signature:='Extended Module: ';

  for Counter:=1 to 20 do Header.Name[Counter-1]:=#0;
  Count:=Length(Name);
  if Count>20 then Count:=20;
  Move(Name[1],Header.Name,Count);

  Header.End1AValue:=$1A;
  Header.Tracker:='FastTracker v2.00   ';
  Header.Version:=$0104;
  Header.Size:=SizeOf(TXMHeader)-60;
  Header.TrackLength:=TrackLength;
  Header.RestartPosition:=RestartPosition;
  Header.NumberOfChannels:=NumberOfChannels;
  Header.NumberOfInstruments:=NumberOfInstruments;
  Header.NumberOfPatterns:=NumberOfPatterns;
  Header.PatternOrder:=PatternOrder;

  Header.Flags:=0;
  if LinearSlides then Header.Flags:=Header.Flags or $1;
  if ExtendedFilterRange then Header.Flags:=Header.Flags or $1000;

  Header.Speed:=StartSpeed;
  Header.Tempo:=StartTempo;

  if Data.Write(Header,SizeOf(TXMHeader))<>SizeOf(TXMHeader) then Exit;

  for Counter:=0 to Header.NumberOfPatterns-1 do WritePattern(Counter);

  for Counter:=1 to Header.NumberOfInstruments do
  begin
    FillChar(InstrumentHeader,SizeOf(TXMInstrumentHeader),#0);
    FillChar(InstrumentExtraHeader,SizeOf(TXMInstrumentExtraHeader),#0);
    NumberOfSamples:=0;
    if Assigned(Instrument[Counter]) then
    begin
      for SubCounter:=0 to LastSample do
      begin
        if Assigned(Instrument[Counter].Sample[SubCounter]) then
        begin
          NumberOfSamples:=SubCounter+1;
        end;
      end;
    end;
    if NumberOfSamples>0 then
    begin
      InstrumentHeader.Size:=SizeOf(TXMInstrumentHeader)+SizeOf(TXMInstrumentExtraHeader);
    end else begin
      InstrumentHeader.Size:=SizeOf(TXMInstrumentHeader);
    end;
    for SubCounter:=1 to 21 do InstrumentHeader.Name[SubCounter]:=#0;
    if Assigned(Instrument[Counter]) then
    begin
      Count:=Length(Instrument[Counter].Name);
      if Count>21 then Count:=21;
      if Count>0 then
      begin
        Move(Instrument[Counter].Name[1],InstrumentHeader.Name,Count);
      end;
    end;
    InstrumentHeader.InstrumentType:=0;
    InstrumentHeader.CountOfSamples:=NumberOfSamples;
    if NumberOfSamples>0 then
    begin
      InstrumentExtraHeader.Size:=SizeOf(TXMSampleHeader);
      InstrumentExtraHeader.FadeOut:=Instrument[Counter].FadeOut;
      for SubCounter:=1 to 96 do
      begin
        InstrumentExtraHeader.SampleMap[SubCounter]:=Instrument[Counter].SampleMap[SubCounter];
      end;
      InstrumentExtraHeader.VolumeEnvelopeNumPoints:=Instrument[Counter].VolumeEnvelope.NumberOfPoints;
      InstrumentExtraHeader.PanningEnvelopeNumPoints:=Instrument[Counter].PanningEnvelope.NumberOfPoints;
      if InstrumentExtraHeader.VolumeEnvelopeNumPoints>12 then InstrumentExtraHeader.VolumeEnvelopeNumPoints:=12;
      if InstrumentExtraHeader.PanningEnvelopeNumPoints>12 then InstrumentExtraHeader.PanningEnvelopeNumPoints:=12;
      for SubCounter:=0 to 12-1 do
      begin
        InstrumentExtraHeader.VolumeEnvelope[SubCounter*2]:=Instrument[Counter].VolumeEnvelope.Points[SubCounter].Tick;
        InstrumentExtraHeader.VolumeEnvelope[(SubCounter*2)+1]:=Instrument[Counter].VolumeEnvelope.Points[SubCounter].Value;
        InstrumentExtraHeader.PanningEnvelope[SubCounter*2]:=Instrument[Counter].PanningEnvelope.Points[SubCounter].Tick;
        InstrumentExtraHeader.PanningEnvelope[(SubCounter*2)+1]:=Instrument[Counter].PanningEnvelope.Points[SubCounter].Value;
      end;
      InstrumentExtraHeader.VolumeEnvelopeSustain:=Instrument[Counter].VolumeEnvelope.SustainPoint;
      InstrumentExtraHeader.VolumeEnvelopeLoopStart:=Instrument[Counter].VolumeEnvelope.LoopStartPoint;
      InstrumentExtraHeader.VolumeEnvelopeLoopEnd:=Instrument[Counter].VolumeEnvelope.LoopEndPoint;
      if Instrument[Counter].VolumeEnvelope.Active then InstrumentExtraHeader.VolFlags:=InstrumentExtraHeader.VolFlags or 1;
      if Instrument[Counter].VolumeEnvelope.Sustain then InstrumentExtraHeader.VolFlags:=InstrumentExtraHeader.VolFlags or 2;
      if Instrument[Counter].VolumeEnvelope.Loop then InstrumentExtraHeader.VolFlags:=InstrumentExtraHeader.VolFlags or 4;

      InstrumentExtraHeader.PanningEnvelopeSustain:=Instrument[Counter].PanningEnvelope.SustainPoint;
      InstrumentExtraHeader.PanningEnvelopeLoopStart:=Instrument[Counter].PanningEnvelope.LoopStartPoint;
      InstrumentExtraHeader.PanningEnvelopeLoopEnd:=Instrument[Counter].PanningEnvelope.LoopEndPoint;
      if Instrument[Counter].PanningEnvelope.Active then InstrumentExtraHeader.PanFlags:=InstrumentExtraHeader.PanFlags or 1;
      if Instrument[Counter].PanningEnvelope.Sustain then InstrumentExtraHeader.PanFlags:=InstrumentExtraHeader.PanFlags or 2;
      if Instrument[Counter].PanningEnvelope.Loop then InstrumentExtraHeader.PanFlags:=InstrumentExtraHeader.PanFlags or 4;

      InstrumentExtraHeader.VibratoType:=Instrument[Counter].VibratoType;
      InstrumentExtraHeader.VibratoSweep:=Instrument[Counter].VibratoSweep;
      InstrumentExtraHeader.VibratoDepth:=Instrument[Counter].VibratoDepth;
      InstrumentExtraHeader.VibratoRate:=Instrument[Counter].VibratoRate;
    end;
    if Data.Write(InstrumentHeader,SizeOf(TXMInstrumentHeader))<>SizeOf(TXMInstrumentHeader) then Exit;
    if NumberOfSamples>0 then
    begin
      if Data.Write(InstrumentExtraHeader,SizeOf(TXMInstrumentExtraHeader))<>SizeOf(TXMInstrumentExtraHeader) then Exit;
      for SubCounter:=0 to NumberOfSamples-1 do
      begin
        FillChar(SampleHeader,SizeOf(TXMSampleHeader),#0);
        if Assigned(Instrument[Counter].Sample[SubCounter]) then
        begin
          Sample:=Instrument[Counter].Sample[SubCounter];

          for SubSubCounter:=1 to 22 do SampleHeader.Name[SubSubCounter]:=#0;
          Count:=Length(Sample.Name);
          if Count>22 then Count:=22;
          Move(Sample.Name[1],SampleHeader.Name,Count);

          SampleHeader.SampleLength:=Sample.SampleLength;
          SampleHeader.LoopStart:=Sample.LoopStart;
          SampleHeader.LoopLength:=Sample.LoopLength;
          SampleHeader.Volume:=Sample.Volume;
          SampleHeader.FineTune:=Sample.FineTune;
          SampleHeader.RelativeNote:=Sample.RelativeNote;
          SampleHeader.Flags:=0;
          if Sample.PingPongLoop then
          begin
            SampleHeader.Flags:=SampleHeader.Flags or 2;
          end else if Sample.Loop then
          begin
            SampleHeader.Flags:=SampleHeader.Flags or 1;
          end;
          if Sample.Bits=16 then
          begin
            SampleHeader.Flags:=SampleHeader.Flags or 16;
            SampleHeader.SampleLength:=SampleHeader.SampleLength*2;
            SampleHeader.LoopStart:=SampleHeader.LoopStart*2;
            SampleHeader.LoopLength:=SampleHeader.LoopLength*2;
          end;
          if Sample.Channels=2 then
          begin
            SampleHeader.Flags:=SampleHeader.Flags or 32;
            SampleHeader.SampleLength:=SampleHeader.SampleLength*2;
            SampleHeader.LoopStart:=SampleHeader.LoopStart*2;
            SampleHeader.LoopLength:=SampleHeader.LoopLength*2;
          end;
          SampleHeader.Panning:=Sample.Panning;
        end;
        if Data.Write(SampleHeader,SizeOf(TXMSampleHeader))<>SizeOf(TXMSampleHeader) then
        begin
          Result:=False;
          Exit;
        end;
      end;
      for SubCounter:=0 to NumberOfSamples-1 do
      begin
        if Assigned(Instrument[Counter].Sample[SubCounter]) then
        begin
          Sample:=Instrument[Counter].Sample[SubCounter];
          if Sample.Channels=1 then
          begin
            if Sample.Bits=8 then
            begin
              GetMem(SampleBuffer,Sample.SampleLength);
              DestByte:=SampleBuffer;
              LastByte:=0;
              for SampleCounter:=0 to Sample.SampleLength-1 do
              begin
                SourceValue:=Sample.Data^[SampleCounter] div 256;
                if SourceValue<-128 then SourceValue:=-128;
                if SourceValue>127 then SourceValue:=127;
                DeltaByte:=SourceValue-LastByte;
                DestByte^:=DeltaByte;
                LastByte:=SourceValue;
                Inc(DestByte);
              end;
              if Data.Write(SampleBuffer^,Sample.SampleLength)<>cardinal(Sample.SampleLength) then Exit;
              FreeMem(SampleBuffer);
            end else if Sample.Bits=16 then
            begin
              GetMem(SampleBuffer,Sample.SampleLength*2);
              DestWord:=SampleBuffer;
              LastWord:=0;
              for SampleCounter:=0 to Sample.SampleLength-1 do
              begin
                SourceValue:=Sample.Data^[SampleCounter];
                if SourceValue<-32768 then SourceValue:=-32768;
                if SourceValue>32767 then SourceValue:=32767;
                DeltaWord:=SourceValue-LastWord;
                DestWord^:=DeltaWord;
                LastWord:=Sourcevalue;
                Inc(DestWord);
              end;
              if Data.Write(SampleBuffer^,Sample.SampleLength*2)<>cardinal(Sample.SampleLength*2) then Exit;
              FreeMem(SampleBuffer);
            end;
          end else if Sample.Channels=2 then
          begin
            if Sample.Bits=8 then
            begin
              GetMem(SampleBuffer,Sample.SampleLength);
              DestByte:=SampleBuffer;
              LastByte:=0;
              for SampleCounter:=0 to Sample.SampleLength-1 do
              begin
                SourceValue:=Sample.Data^[SampleCounter*2] div 256;
                if SourceValue<-128 then SourceValue:=-128;
                if SourceValue>127 then SourceValue:=127;
                DeltaByte:=SourceValue-LastByte;
                DestByte^:=DeltaByte;
                LastByte:=SourceValue;
                Inc(DestByte);
              end;
              if Data.Write(SampleBuffer^,Sample.SampleLength)<>cardinal(Sample.SampleLength) then Exit;
              DestByte:=SampleBuffer;
              LastByte:=0;
              for SampleCounter:=0 to Sample.SampleLength-1 do
              begin
                SourceValue:=Sample.Data^[(SampleCounter*2)+1] div 256;
                if SourceValue<-128 then SourceValue:=-128;
                if SourceValue>127 then SourceValue:=127;
                DeltaByte:=SourceValue-LastByte;
                DestByte^:=DeltaByte;
                LastByte:=SourceValue;
                Inc(DestByte);
              end;
              if Data.Write(SampleBuffer^,Sample.SampleLength)<>cardinal(Sample.SampleLength) then Exit;
              FreeMem(SampleBuffer);
            end else if Sample.Bits=16 then
            begin
              GetMem(SampleBuffer,Sample.SampleLength*2);
              DestWord:=SampleBuffer;
              LastWord:=0;
              for SampleCounter:=0 to Sample.SampleLength-1 do
              begin
                SourceValue:=Sample.Data^[SampleCounter*2];
                if SourceValue<-32768 then SourceValue:=-32768;
                if SourceValue>32767 then SourceValue:=32767;
                DeltaWord:=SourceValue-LastWord;
                DestWord^:=DeltaWord;
                LastWord:=Sourcevalue;
                Inc(DestWord);
              end;
              if Data.Write(SampleBuffer^,Sample.SampleLength*2)<>cardinal(Sample.SampleLength*2) then Exit;
              DestWord:=SampleBuffer;
              LastWord:=0;
              for SampleCounter:=0 to Sample.SampleLength-1 do
              begin
                SourceValue:=Sample.Data^[(SampleCounter*2)+1];
                if SourceValue<-32768 then SourceValue:=-32768;
                if SourceValue>32767 then SourceValue:=32767;
                DeltaWord:=SourceValue-LastWord;
                DestWord^:=DeltaWord;
                LastWord:=Sourcevalue;
                Inc(DestWord);
              end;
              if Data.Write(SampleBuffer^,Sample.SampleLength*2)<>cardinal(Sample.SampleLength*2) then Exit;
              FreeMem(SampleBuffer);
            end;
          end;
        end;
      end;
    end;
  end;
  if Length(Comment)>0 then
  begin
    TrackComment:='';
    for Counter:=1 to Length(Comment) do
    begin
      if Comment[Counter]<>#10 then
      begin
        TrackComment:=TrackComment+Comment[Counter];
      end;
    end;
    Value:=Length(TrackComment);
    Data.Write('text',4*SizeOf(char));
    Data.Write(Value,SizeOf(longword));
    Data.Write(TrackComment[1],Value);
  end;
  Result:=True;
end;

function TXMModule.SaveFile(FileName:string):boolean;
var TheFile:TFileStream;
begin
  TheFile:=TFileStream.CreateNew(FileName);
  Result:=Save(TheFile);
  TheFile.Destroy;
end;

function TXMModule.NumberOfPatterns:integer;
var Counter:integer;
begin
  Result:=0;
  for Counter:=0 to LastPattern do
  begin
    if Pattern[Counter].Rows>0 then Result:=Counter+1;
  end;
end;

function TXMModule.NumberOfInstruments:integer;
var Counter:integer;
begin
  Result:=0;
  for Counter:=1 to LastInstrument do
  begin
    if Assigned(Instrument[Counter]) then Result:=Counter;
  end;
end;

end.
