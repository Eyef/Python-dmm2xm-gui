unit WadFile;

interface

uses Windows,Messages,Streams;

type
  TWadRecord=packed record
    Offset: cardinal;
    Size: cardinal;
    Name: array[0..7] of char;
  end;
  TWadRecords=array of TWadRecord;

  TWadFile=class(TFileStream)
  private
    fRecords:TWadRecords;
    fFileNumber:integer;
    fRecordTableOffset:integer;
    fValidWad:boolean;
  public
    constructor Create(FileName:string);
    destructor Destroy; override;
    property Records:TWadRecords read fRecords;
    property FileNumber:integer read fFileNumber;
    property ValidWad:boolean read fValidWad;
    function GetFileIndex(FileName:string):integer;
    function SeekToFile(FileName:string):boolean;
  end;

implementation

constructor TWadFile.Create(FileName:string);
var WadHeader:array[0..3] of char;
begin
  inherited Create(FileName);
  Read(WadHeader,4);
  fValidWad:=((WadHeader[0]='I') or (WadHeader[0]='P'))
    and (WadHeader[1]='W') and (WadHeader[2]='A') and (WadHeader[3]='D');
  if fValidWad then
  begin
    Read(fFileNumber,4);
    Read(fRecordTableOffset,4);
    SetLength(fRecords,fFileNumber);
    Seek(fRecordTableOffset);
    Read(fRecords[0],fFileNumber*SizeOf(TWadRecord));
  end;
end;

destructor TWadFile.Destroy;
begin
  SetLength(fRecords,0);
  inherited Destroy;
end;

function TWadFile.GetFileIndex(FileName:string):integer;
var Counter:integer;
begin
  Result:=-1;
  for Counter:=0 to Length(fRecords)-1 do
  begin
    if FileName=fRecords[Counter].Name then
    begin
      Result:=Counter;
      Break;
    end;
  end;
end;

function TWadFile.SeekToFile(FileName:string):boolean;
var FileIndex:integer;
begin
  FileIndex:=GetFileIndex(FileName);
  Result:=FileIndex<>-1;
  if Result then Seek(fRecords[FileIndex].Offset);
end;

end.