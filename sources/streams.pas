unit Streams;
// Streams from BeRoXM, Copyright (C) 2005-2007, Benjamin 'BeRo' Rosseaux
interface

uses Windows,Messages;

const
  bsoFromBeginning=0;
  bsoFromCurrent=1;
  bsoFromEnd=2;

type
  PStreamData=^TStreamData;
  TStreamData=packed array[0..$7FFFFFFE] of byte;

  PStreamBuffer=^TStreamBuffer;
  TStreamBuffer=packed array[1..4096] of byte;

  TStream=class
  private
    fPosition,fSize,fInMemorySize:cardinal;
    fData:PStreamData;
    procedure Realloc(NewInMemorySize:cardinal);
    procedure Resize(NewSize:integer);
  public
    constructor Create;
    destructor Destroy; override;
    function Assign(Src:TStream):integer;
    function Append(Src:TStream):integer;
    function AppendFrom(Src:TStream;Counter:integer):integer;
    procedure Clear; virtual;
    function Read(var Buf;Count:cardinal):cardinal; virtual;
    function Write(const Buf;Count:cardinal):cardinal; virtual;
    function SeekEx(APosition:cardinal):cardinal; virtual;
    function Seek(APosition:cardinal):cardinal; overload;
    function Seek(APosition,Origin:cardinal):cardinal; overload;
    function Position:cardinal; virtual;
    function Size:cardinal; virtual;
    procedure SetSize(NewSize:integer);
  end;

  TMemoryStream=TStream;

  TFileStream=class(TStream)
  private
    fFile:THandle;
  public
    constructor Create(FileName:string);
    constructor CreateNew(FileName:string);
    destructor Destroy; override;
    function Read(var Buf;Count:cardinal):cardinal; override;
    function Write(const Buf;Count:cardinal):cardinal; override;
    function SeekEx(APosition:cardinal):cardinal; override;
    function Position:cardinal; override;
    function Size:cardinal; override;
  end;

implementation

const
  MemoryDelta=1 shl 16;
  MemoryDeltaMask=MemoryDelta-1;

constructor TStream.Create;
begin
  inherited Create;
  fData:=nil;
  ReallocMem(fData,0);
  fPosition:=0;
  fSize:=0;
  fInMemorySize:=0;
end;

destructor TStream.Destroy;
begin
  ReallocMem(fData,0);
  fPosition:=0;
  fSize:=0;
  fInMemorySize:=0;
  inherited Destroy;
end;

function TStream.Assign(Src:TStream):integer;
var Remain,Count:integer;
    Buf:TStreamBuffer;
begin
  Clear;
  Result:=0;
  Remain:=Src.Size;
  if (Seek(0)<>0) or (Src.Seek(0)<>0) then exit;
  while Remain>=SizeOf(TStreamBuffer) do
  begin
    Count:=Src.Read(Buf,SizeOf(TStreamBuffer));
    Write(Buf,Count);
    Inc(Result,Count);
    Dec(Remain,SizeOf(TStreamBuffer));
  end;
  Count:=Src.Read(Buf,Remain);
  Write(Buf,Count);
  Inc(Result,Count);
end;

function TStream.Append(Src:TStream):integer;
var Remain,Count:integer;
    Buf:TStreamBuffer;
begin
  Result:=0;
  Remain:=Src.Size;
  if Src.Seek(0)<>0 then exit;
  while Remain>=SizeOf(TStreamBuffer) do
  begin
    Count:=Src.Read(Buf,SizeOf(TStreamBuffer));
    Write(Buf,Count);
    Inc(Result,Count);
    Dec(Remain,SizeOf(TStreamBuffer));
  end;
  Count:=Src.Read(Buf,Remain);
  Write(Buf,Count);
  Inc(Result,Count);
end;

function TStream.AppendFrom(Src:TStream;Counter:integer):integer;
var Remain,Count:integer;
    Buf:TStreamBuffer;
begin
  Result:=0;
  Remain:=Counter;
  while Remain>=SizeOf(TStreamBuffer) do
  begin
    Count:=Src.Read(Buf,SizeOf(TStreamBuffer));
    Write(Buf,Count);
    Inc(Result,Count);
    Dec(Remain,SizeOf(TStreamBuffer));
  end;
  Count:=Src.Read(Buf,Remain);
  Write(Buf,Count);
  Inc(Result,Count);
end;

procedure TStream.Clear;
begin
  ReallocMem(fData,0);
  fPosition:=0;
  fSize:=0;
  fInMemorySize:=0;
end;

procedure TStream.Realloc(NewInMemorySize:cardinal);
var OldInMemorySize,Count:cardinal;
begin
  NewInMemorySize:=(NewInMemorySize+MemoryDeltaMask) and not MemoryDeltaMask;
  if fInMemorySize<>NewInMemorySize then
  begin
    OldInMemorySize:=fInMemorySize;
    fInMemorySize:=NewInMemorySize;
    ReallocMem(fData,fInMemorySize);
    Count:=NewInMemorySize-OldInMemorySize;
    if Count>0 then
    begin
      FillChar(fData^[OldInMemorySize],Count,#0);
    end;
  end;
end;

procedure TStream.Resize(NewSize:integer);
begin
  fSize:=NewSize;
  if fPosition>fSize then fPosition:=fSize;
  Realloc(fSize);
end;

function TStream.Read(var Buf;Count:cardinal):cardinal;
begin
  if fSize>fPosition then
  begin
    Result:=fSize-fPosition;
    if Result>Count then Result:=Count;
    Move(fData^[fPosition],Buf,Result);
    Inc(fPosition,Result);
    Exit;
  end;
  Result:=0;
end;

function TStream.Write(const Buf;Count:cardinal):cardinal;
var EndPosition:cardinal;
begin
  EndPosition:=fPosition+Count;
  if EndPosition>fSize then Resize(EndPosition);
  Move(Buf,fData^[fPosition],Count);
  fPosition:=EndPosition;
  Result:=Count;
end;

function TStream.SeekEx(APosition:cardinal):cardinal;
var AltePos,RemainSize:cardinal;
begin
  fPosition:=APosition;
  if fPosition>fSize then
  begin
    AltePos:=fSize;
    if fPosition>fSize then
    begin
      RemainSize:=fPosition-fSize;
      Resize(fSize+RemainSize);
      FillChar(fData^[AltePos],RemainSize,#0);
    end;
    Result:=fPosition;
  end else begin
    Result:=fPosition;
  end;
end;

function TStream.Seek(APosition:cardinal):cardinal;
begin
  Result:=SeekEx(APosition);
end;

function TStream.Seek(APosition,Origin:cardinal):cardinal;
begin
  case Origin of
    bsoFromBeginning: Result:=SeekEx(APosition);
    bsoFromCurrent: Result:=SeekEx(Position+APosition);
    bsoFromEnd: Result:=SeekEx(Size-APosition);
    else Result:=SeekEx(APosition);
  end;
end;

function TStream.Position:cardinal;
begin
  Result:=fPosition;
end;

function TStream.Size:cardinal;
begin
  Result:=fSize;
end;

procedure TStream.SetSize(NewSize:integer);
begin
  fSize:=NewSize;
  if fPosition>fSize then fPosition:=fSize;
  ReallocMem(fData,fSize);
end;

constructor TFileStream.Create(FileName:string);
begin
  inherited Create;
  fFile:=CreateFile(pchar(FileName),GENERIC_READ,0,nil,OPEN_ALWAYS,0,0);
end;

constructor TFileStream.CreateNew(FileName:string);
begin
  inherited Create;
  fFile:=CreateFile(pchar(FileName),GENERIC_WRITE,0,nil,CREATE_ALWAYS,0,0);
end;

destructor TFileStream.Destroy;
begin
  CloseHandle(fFile);
  inherited Destroy;
end;

function TFileStream.Read(var Buf;Count:cardinal):cardinal;
var BytesRead:cardinal;
begin
  if not ReadFile(fFile,Buf,Count,BytesRead,nil) then
  begin
    Result:=0;
    Exit;
  end;
  Inc(fPosition,BytesRead);
  Result:=BytesRead;
end;

function TFileStream.Write(const Buf;Count:cardinal):cardinal;
var BytesWritten:cardinal;
begin
  if not WriteFile(fFile,Buf,Count,BytesWritten,nil) then
  begin
    Result:=0;
    Exit;
  end;
  Inc(fPosition,BytesWritten);
  Result:=BytesWritten;
end;

function TFileStream.SeekEx(APosition:cardinal):cardinal;
begin
  if APosition<=Size then
  begin
    Result:=SetFilePointer(fFile,APosition,nil,FILE_BEGIN);
  end else Result:=0;
end;

function TFileStream.Position:cardinal;
begin
  Result:=fPosition;
end;

function TFileStream.Size:cardinal;
begin
  Result:=GetFileSize(fFile,nil);
end;

end.
