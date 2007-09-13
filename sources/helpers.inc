function RoundBy(Value, By:integer):integer;
begin
  Result:=(Value+By div 2) div By*By;
end;

function S2Int(S:pchar):integer;
var M:integer;
begin
  Result:=0;
  if S='' then Exit;
  M:=1;
  if S^='-' then
  begin
    M:=-1;
    Inc(S);
  end else begin
    if S^='+' then Inc(S);
  end;
  while S^ in ['0'..'9'] do
  begin
    Result:=Result*10+integer(S^)-integer('0');
    Inc(S);
  end;
  if M<0 then Result:=-Result;
end;

function Str2Int(const Value:string):integer;
begin
  Result:=S2Int(pchar(Value));
end;

function Int2Str(Value:integer):string;
var Buf:array[0..15] of char;
    Dst:pchar;
    Minus:boolean;
    D:dword;
begin
  Dst:=@Buf[15];
  Dst^:=#0;
  Minus:=False;
  if Value<0 then
  begin
    Value:=-Value;
    Minus:=True;
  end;
  D:=Value;
  repeat
    Dec(Dst);
    Dst^:=Char((D mod 10)+Byte('0'));
    D:=D div 10;
  until D=0;
  if Minus then
  begin
    Dec(Dst);
    Dst^:='-';
  end;
  Result:=Dst;
end;

function OemStr(const S:string):string;
begin
  Result:=S;
  CharToOEM(@Result[1],@Result[1]);
end;

function LowerCase(const S:string):string;
var c:integer;
begin
  Result:=S;
  for c:=1 to Length(S) do if Result[c] in ['A'..'Z'] then Inc(Result[c],32);
end;

function WriteFile_(hFile: THandle; const Buffer: pointer;
  nNumberOfBytesToWrite: DWORD; var lpNumberOfBytesWritten: DWORD;
  lpOverlapped: POverlapped): BOOL; stdcall; external kernel32 name 'WriteFile';

// 2 kb smaller than Write
procedure Write2(s:string);
var Temp:dword;
begin
  WriteFile_(GetStdHandle(STD_OUTPUT_HANDLE),pchar(s),Length(s),Temp,nil);
end;

function LastChar(Ch:char; Str:string):integer;
var Counter:integer;
begin
  Result:=0;
  for Counter:=Length(Str) downto 1 do if Str[Counter]=Ch then
  begin
    Result:=Counter;
    Break;
  end;
end;

function CutExtension(FileName:string):string;
var DotPosition:integer;
begin
  DotPosition:=LastChar('.',FileName);
  if DotPosition=0 then Result:=FileName
    else Result:=Copy(FileName,1,DotPosition-1);
end;

function GetExtension(FileName:string):string;
var DotPosition:integer;
begin
  DotPosition:=LastChar('.',FileName);
  if DotPosition=0 then Result:=''
    else Result:=LowerCase(Copy(FileName,DotPosition+1,MaxInt));
end;

function ExtractFilePath(FileName:string):string;
var SlashPosition:integer;
begin
  SlashPosition:=LastChar('\',FileName);
  if SlashPosition=0 then Result:=''
    else Result:=Copy(FileName,1,SlashPosition);
end;

function ExtractFileName(FileName:string):string;
var SlashPosition:integer;
begin
  SlashPosition:=LastChar('\',FileName);
  if SlashPosition=0 then Result:=FileName
    else Result:=Copy(FileName,SlashPosition+1,MaxInt);
end;

function FileExists(const FileName:string):boolean;
var Code:integer;
begin
  Code:=GetFileAttributes(pchar(FileName));
  Result:=(Code<>-1) and (FILE_ATTRIBUTE_DIRECTORY and Code=0);
end;

function HomeDir:string;
begin
  Result:=ExtractFilePath(ParamStr(0));
end;

// only for positive values
function Int2Digs(Value,Digits:Integer):String;
begin
  Result:=Int2Str(Value);
  while Length(Result)<Digits do Result:='0'+Result;
end;
