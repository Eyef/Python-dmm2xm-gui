program DMM2XM;
{$APPTYPE CONSOLE}
{$IFDEF VER180}{$SETPEFLAGS 1}{$ENDIF}
uses Windows,Messages,BeRoXM,Streams,WadFile;
{$R dmm2xm.res}
{
  TODO:
  - Fix bug with big delay (xm->dmm->xm(buggy))
  - Support volume slide down by turning off note (xm->dmm)
  - Support default volume in samples (xm->dmm)
  - Handle note cut and note delay, maybe more (xm->dmm)
  - Option to convert directly to WAD ;)

  Also, search for "todo" strings
}
const
  DMM_8_CHANNELS=8;
  DMM2XM_VERSION_TEXT='dmm2xm v1.5 [31 Mar 2023] by Grom PE & Artem Vasilev (wormsbiysk)';

  MAX_SAMPLES=11;
  PAN_SETTING:array[0..MAX_SAMPLES-1] of array[0..MAX_SAMPLES-1] of byte=(
                    (128,0,0,0,0,0,0,0,0,0,0),
                  (120,136,0,0,0,0,0,0,0,0,0),
                (112,128,144,0,0,0,0,0,0,0,0),
              (102,120,136,152,0,0,0,0,0,0,0),
             (96,112,128,144,160,0,0,0,0,0,0),
           (88,102,120,136,152,168,0,0,0,0,0),
          (80,96,112,128,144,160,176,0,0,0,0),
        (72,88,102,120,136,152,168,184,0,0,0),
       (64,80,96,112,128,144,160,176,192,0,0),
     (56,72,88,102,120,136,152,168,184,200,0),
    (48,64,80,96,112,128,144,160,176,192,208));

type
  PIntegers=^TIntegers;
  TIntegers=array[0..0] of integer;

  TDMMNote=packed record
    Note,Instrument,Volume,Delay:byte;
  end;
  TDMMNotes=array of TDMMNote;
  TDMMInstrument=packed record
    UnusedByte:byte;
    Name:array[0..14] of char;
  end;

  TMisalignedNote=record
    Delay,NewDelay,Pattern,Row,Channel:integer;
  end;
  TMisalignedNotes=array of TMisalignedNote;

  TWadRecord=packed record
    Offset:cardinal;
    Size:cardinal;
    Name:array[0..7] of char;
  end;

{$I helpers.inc}

function Log2(x:extended):extended;
begin
  Result:=Ln(x)/Ln(2);
end;

function Pow(Number,Exponent:single):single;
begin
  Result:=Exp(Exponent*Ln(Number));
end;

var EmulateBug:boolean;

procedure SampleRateToXM(SampleRate:integer; var RelativeNote,FineTune:integer);
begin
  if SampleRate<>0 then
  begin
    FineTune:=Round(Log2(SampleRate/8363)*1536);
  end else begin
    FineTune:=Round(Log2(1)*1536);
  end;
  if EmulateBug then FineTune:=FineTune+64;
  RelativeNote:=FineTune div 128;
  if FineTune<0 then
  begin
    RelativeNote:=(FineTune-63) div 128;
  end else begin
    RelativeNote:=(FineTune+64) div 128;
  end;
  Dec(FineTune,RelativeNote*128);
  if FineTune<0 then
  begin
    FineTune:=-((-FineTune) mod 128);
  end else begin
    FineTune:=FineTune mod 128;
  end;
  if RelativeNote<-127 then RelativeNote:=-127;
  if RelativeNote>127 then RelativeNote:=127;
end;

function XMToSampleRate(RelativeNote,FineTune:integer):integer;
begin
  Result:=Round(8363*Pow(2,((RelativeNote*128)+FineTune)/1536));
end;

function MakeNote(Note:integer; Instrument:integer=0; Volume:integer=0;
  Effect:integer=0; EffectParameter:integer=0):TPatternNote;
begin
  Result.Note:=Note;
  Result.Instrument:=Instrument;
  Result.Volume:=Volume;
  Result.Effect:=Effect;
  Result.EffectParameter:=EffectParameter;
end;

function IsFinishNote(Note:TDMMNote):boolean;
begin
  Result:=(Note.Note=255) and (Note.Instrument=0) and (Note.Volume=128) and (Note.Delay=0);
end;

procedure ListDMMInWad(FileName:string);
var Wad:TWadFile;
    DMMHeader:array[0..4] of char;
    Counter:integer;
begin
  Wad:=TWadFile.Create(FileName);
  if not Wad.ValidWad then
  begin
    Wad.Free;
    Write2('Error: Invalid WAD file: "'+FileName+'".'#10);
    Exit;
  end;
  Write2('To convert XM directly from WAD file, set -f <name> parameter.'#10
    +'Valid DMM names found in "'+FileName+'":'#10);
  for Counter:=0 to Wad.FileNumber-1 do
  begin
    if Wad.Records[Counter].Size<80 then Continue; // skip too small files
    Wad.Seek(Wad.Records[Counter].Offset);
    Wad.Read(DMMHeader,SizeOf(DMMHeader));
    if (DMMHeader[0]='D') and (DMMHeader[1]='M') and (DMMHeader[2]='M')
      and (DMMHeader[3]=#0) and (DMMHeader[4]=#0) then
    begin
      Write2(Wad.Records[Counter].Name+#10);
    end;
  end;
  Wad.Free;
end;

// --- Main work with DMM ---

var
  MisalignedNotes:TMisalignedNotes;
  InputFileName:string;
  Quantization:integer;
  UsedChannels:integer;
  LoadingFromWad:boolean;
  NoStereo:boolean;
  // dmm2xm v1.4
  MinNoteDelay:integer;
  MaxRows:integer;

function LoadInstrumentFromDMI(Instrument:TInstrument; DMIInstrumentName:string;
  InstrumentNumber,InstrumentsTotal:integer; Wad:TWadFile):boolean;
var
  DMIFile:TFileStream;
  SampleBuffer:array of shortint;
  FoundDMIFileName:string;
  DMILength,DMISampleRate,DMILoopStart,DMILoopLength:word;
  Counter:integer;
  IndexInWad:integer;
begin
  if DMIInstrumentName='' then // skip empty instruments
  begin
    Result:=True;
    Exit;
  end;
  Result:=False;
  Instrument.SampleMap[1]:=0;
  Instrument.Sample[0]:=TSample.Create;
  Instrument.Sample[0].Bits:=8;
  Instrument.Sample[0].Channels:=1;
  Instrument.Sample[0].Name:=DMIInstrumentName;
  if not NoStereo and (InstrumentsTotal<=MAX_SAMPLES) then
    Instrument.Sample[0].Panning:=PAN_SETTING[InstrumentsTotal-1][InstrumentNumber];

  IndexInWad:=-1;
  if Wad<>nil then IndexInWad:=Wad.GetFileIndex(OemStr(DMIInstrumentName));

  if IndexInWad<>-1 then
  begin
    DMIFile:=nil; // prevent Warning: Variable 'DMIFile' might not have been initialized
    Wad.Seek(Wad.Records[IndexInWad].Offset);
    Wad.Read(DMILength,2);
    Wad.Read(DMISampleRate,2);
    Wad.Read(DMILoopStart,2);
    Wad.Read(DMILoopLength,2);
    if DMILength>Wad.Records[IndexInWad].Size-8 then
      DMILength:=Wad.Records[IndexInWad].Size-8; // prevent reading beyond the file
  end else begin
    FoundDMIFileName:=ExtractFilePath(InputFileName)+DMIInstrumentName;
    if not FileExists(FoundDMIFileName) then
    begin
      FoundDMIFileName:=HomeDir+DMIInstrumentName;
      if not FileExists(FoundDMIFileName) then
      begin
        FoundDMIFileName:=ExtractFilePath(InputFileName)+'dmi\'+DMIInstrumentName;
        if not FileExists(FoundDMIFileName) then
        begin
          FoundDMIFileName:=HomeDir+'dmi\'+DMIInstrumentName;
          if not FileExists(FoundDMIFileName) then Exit;
        end;
      end;
    end;
    DMIFile:=TFileStream.Create(FoundDMIFileName);
    DMIFile.Read(DMILength,2);
    DMIFile.Read(DMISampleRate,2);
    DMIFile.Read(DMILoopStart,2);
    DMIFile.Read(DMILoopLength,2);
    if DMILength>DMIFile.Size-8 then DMILength:=DMIFile.Size-8; // prevent reading beyond the file
  end;

  Instrument.Sample[0].SampleLength:=DMILength;
  Instrument.Sample[0].Resize(Instrument.Sample[0].SampleLength);

  SampleRateToXM(DMISampleRate,
    Instrument.Sample[0].RelativeNote,Instrument.Sample[0].Finetune);

  if DMILoopLength>0 then
  begin
    Instrument.Sample[0].Loop:=true;
    Instrument.Sample[0].LoopStart:=DMILoopStart;
    Instrument.Sample[0].LoopLength:=DMILoopLength;
  end;

  // dmm2xm v1.4: sample-specific fixes
  if (DMIInstrumentName='DMI0011') and (DMILoopStart=3326) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopLength:=5375;
  end;
  if (DMIInstrumentName='DMI0063') and (DMILoopStart=720) then
  begin
    Instrument.Sample[0].LoopLength:=6982;
  end;
  if (DMIInstrumentName='DMI0018') and (DMILoopLength=14868) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopStart:=2168;
    Instrument.Sample[0].LoopLength:=8338;
  end;
  if (DMIInstrumentName='DMI0055') and (DMILoopStart=3394) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopStart:=1897;
    Instrument.Sample[0].LoopLength:=4377;
  end;
  if (DMIInstrumentName='DMI0059') and (DMILoopLength=14864) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopStart:=2168;
    Instrument.Sample[0].LoopLength:=8595;
  end;
  if (DMIInstrumentName='DMI0040') and (DMILoopStart=4010) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
  end;
  if (DMIInstrumentName='DMI0004') and (DMILoopStart=14856) then
  begin
    Instrument.Sample[0].LoopLength:=7712;
  end;
  if (DMIInstrumentName='DMI0071') and (DMILoopStart=24) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopStart:=428;
    Instrument.Sample[0].LoopLength:=7525;
  end;
  if (DMIInstrumentName='DMI0022') and (DMILoopStart=4250) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopStart:=905;
    Instrument.Sample[0].LoopLength:=4606;
  end;
  if (DMIInstrumentName='DMI0050') and (DMILoopLength=20000) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopLength:=20946;
  end;
  if (DMIInstrumentName='DMI0074') and (DMILoopStart=6614) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopStart:=6339;
    Instrument.Sample[0].LoopLength:=738;
  end;
  if (DMIInstrumentName='DMI0045') and (DMILoopStart=1000) then
  begin
    Instrument.Sample[0].PingPongLoop:=true;
    Instrument.Sample[0].LoopStart:=80;
    Instrument.Sample[0].LoopLength:=9272;
  end;

  SetLength(SampleBuffer,DMILength);
  if IndexInWad<>-1 then
  begin
    Wad.Read(SampleBuffer[0],DMILength);
  end else begin
    DMIFile.Read(SampleBuffer[0],DMILength);
    DMIFile.Free;
  end;
  for Counter:=0 to DMILength-1 do
  begin
    PIntegers(Instrument.Sample[0].data)[Counter]:=SampleBuffer[Counter]*256;
  end;
  Result:=True;
end;

function RecordPatternsFromDMMPattern(XM:TXMModule; DMMPattern:TDMMNotes; PatternNumber, StartPatternNumber:integer):integer; // dmm2xm v1.4
var
  DMMNote:TDMMNote;
  Counter,Delay,Row,Channel,NotesRecorded:integer;
  MaxNoteRow:integer;
  ResultVolume:integer;
  // dmm2xm v1.4
  MyNote,OldNote:TPatternNote;
  CurrentChanDelay,MaxChanDelay,PutDelay,PushUp:integer;
  CurrentChanNotes,MaxChanNotes:integer;
begin
  MaxNoteRow:=0;
  for Counter:=0 to DMM_8_CHANNELS-1 do
  begin
    XM.Pattern[StartPatternNumber].SetNote(0,Counter,MakeNote(NoteStop));
  end;
  NotesRecorded:=0;
  Delay:=0;
  Row:=0;
  Channel:=0;
  CurrentChanDelay:=0;
  MaxChanDelay:=0;
  CurrentChanNotes:=0;
  MaxChanNotes:=0;
  repeat
    DMMNote:=DMMPattern[NotesRecorded];
    //if Delay mod Quantization<>0 then
    //begin
    //  SetLength(MisalignedNotes,Length(MisalignedNotes)+1);
    //  MisalignedNotes[Length(MisalignedNotes)-1].Delay:=Delay;
    //  MisalignedNotes[Length(MisalignedNotes)-1].NewDelay:=RoundBy(Delay,Quantization);
    //  MisalignedNotes[Length(MisalignedNotes)-1].Row:=Row;
    //  MisalignedNotes[Length(MisalignedNotes)-1].Channel:=Channel+1;
    //  MisalignedNotes[Length(MisalignedNotes)-1].Pattern:=PatternNumber;
    //end;
    //if Delay=0 then
    if Delay<Quantization then // dmm2xm v1.4
    begin
      Inc(NotesRecorded);

      if DMMNote.Volume=128 then
      begin
        Inc(Channel);
        if MaxChanDelay<CurrentChanDelay then MaxChanDelay:=CurrentChanDelay;
        if MaxChanNotes<CurrentChanNotes then MaxChanNotes:=CurrentChanNotes;
        Delay:=0;
        CurrentChanDelay:=0;
        CurrentChanNotes:=0;
        Row:=0;
        Continue;
      end;
      if DMMNote.Note=254 then
      begin
        // dmm2xm v1.4: removed old magic
        Inc(Delay,(DMMNote.Instrument*256)+DMMNote.Delay);
        Inc(CurrentChanDelay,(DMMNote.Instrument*256)+DMMNote.Delay);
        Continue;
      end;

      if DMMNote.Volume>126 then // just to make smaller patterns
        ResultVolume:=0 else ResultVolume:=DMMNote.Volume div 2+16;

      if DMMNote.Volume>0 then
      begin
        PushUp:=0;
        if Delay>0 then
        begin
          PutDelay:=Delay;
          if PutDelay>15 then
          begin
            PutDelay:=15;
            SetLength(MisalignedNotes,Length(MisalignedNotes)+1);
            MisalignedNotes[Length(MisalignedNotes)-1].Delay:=Delay;
            MisalignedNotes[Length(MisalignedNotes)-1].NewDelay:=PutDelay;
            MisalignedNotes[Length(MisalignedNotes)-1].Row:=Row;
            MisalignedNotes[Length(MisalignedNotes)-1].Channel:=Channel+1;
            MisalignedNotes[Length(MisalignedNotes)-1].Pattern:=PatternNumber;
          end;
          MyNote:=MakeNote(DMMNote.Note+25,DMMNote.Instrument,ResultVolume,EffectExtendedEffects,PutDelay or ExtendedEffectNoteDelay shl 4);
        end else if Delay<0 then
        begin
          PutDelay:=Quantization+Delay;
          if PutDelay<=0 then
          begin
            Write2(#10'Warning: Wrong delay, choose smaller quantization!'#10);
          end else begin
            if PutDelay>15 then
            begin
              PutDelay:=15;
              SetLength(MisalignedNotes,Length(MisalignedNotes)+1);
              MisalignedNotes[Length(MisalignedNotes)-1].Delay:=Delay;
              MisalignedNotes[Length(MisalignedNotes)-1].NewDelay:=PutDelay;
              MisalignedNotes[Length(MisalignedNotes)-1].Row:=Row;
              MisalignedNotes[Length(MisalignedNotes)-1].Channel:=Channel+1;
              MisalignedNotes[Length(MisalignedNotes)-1].Pattern:=PatternNumber;
            end;
            MyNote:=MakeNote(DMMNote.Note+25,DMMNote.Instrument,ResultVolume,EffectExtendedEffects,PutDelay or ExtendedEffectNoteDelay shl 4);
            PushUp:=1;
          end;
        end else begin
          MyNote:=MakeNote(DMMNote.Note+25,DMMNote.Instrument,ResultVolume);
        end;
        OldNote:=XM.Pattern[StartPatternNumber+(Row-PushUp) div MaxRows].GetNote((Row-PushUp) mod MaxRows,Channel);
        if (OldNote.Note<>0) and (OldNote.Note<>NoteStop) then
        begin
          Write2(#10'Warning: Note '+Int2Str(OldNote.Note)+' overwritten by '
            +Int2Str(MyNote.Note)+' at pattern '+Int2Str(StartPatternNumber+(Row-PushUp) div MaxRows)
            +' column '+Int2Str(Channel+1)+' row '+Int2Str(Row-PushUp)+', lost data! Set smaller quantization.'#10);
        end;
        XM.Pattern[StartPatternNumber+(Row-PushUp) div MaxRows].SetNote((Row-PushUp) mod MaxRows,Channel,MyNote);
        Inc(CurrentChanNotes);
      end else begin
        XM.Pattern[StartPatternNumber+Row div MaxRows].SetNote(Row mod MaxRows,Channel,MakeNote(NoteStop));
        Inc(CurrentChanNotes);
      end;
      if UsedChannels<Channel+1 then UsedChannels:=Channel+1;

      // dmm2xm v1.4
      if DMMNote.Delay=0 then
      begin
        Inc(Delay,256);
        Inc(CurrentChanDelay,256);
      end else begin
        Inc(Delay,DMMNote.Delay);
        Inc(CurrentChanDelay,DMMNote.Delay);
      end;
      if MinNoteDelay>Delay then MinNoteDelay:=Delay;
    end;
    Inc(Row);
    if MaxNoteRow<Row then MaxNoteRow:=Row;
    Dec(Delay,Quantization);
  until NotesRecorded=Length(DMMPattern);
  // dmm2xm v1.4
  Inc(Row,Delay div Quantization);
  PutDelay:=MaxChanDelay mod Quantization;
  if PutDelay<>0 then
  begin
    Write2(#10'Warning: '+Int2Str(PutDelay)+' ticks lost at the pattern end, trying to fix - not all players support this!'#10);
    for Counter:=0 to UsedChannels do
    begin
      OldNote:=XM.Pattern[StartPatternNumber+MaxNoteRow div MaxRows].GetNote((MaxNoteRow-1) mod MaxRows,Counter);
      if OldNote.Effect=0 then
      begin
        OldNote.Effect:=EffectExtraFinePorta;
        OldNote.EffectParameter:=$60 or PutDelay;
        XM.Pattern[StartPatternNumber+MaxNoteRow div MaxRows].SetNote((MaxNoteRow-1) mod MaxRows,Counter,OldNote);
        PutDelay:=0;
        break;
      end;
    end;
    if PutDelay>0 then
      Write2(#10'Warning: Effects are all occupied, couldn''t fix!'#10);
  end;
  if MaxNoteRow<Row then MaxNoteRow:=Row;
  if MaxNoteRow mod MaxRows<>0 then
    XM.Pattern[StartPatternNumber+MaxNoteRow div MaxRows].Resize(MaxNoteRow mod MaxRows,DMM_8_CHANNELS);
  Result:=(MaxNoteRow-1) div MaxRows+1; // number of patterns recorded
  Write2('...ok, ticks: '+Int2Str(MaxChanDelay)+', notes: '+Int2Str(MaxChanNotes)+', rows: '+Int2Str(MaxNoteRow));
end;

// We consider note "NoteStop" when converting to DMM if it have zero volume also.
function IsStopNoteForDMM(Note:TPatternNote):boolean;
begin
  Result:=((Note.Effect=EffectVolume) and (Note.EffectParameter=0))
    or (Note.Volume=16) or (Note.Note=NoteStop);
end;

var
  NewSpeed,NewTempo:integer;

procedure PatternToDMMNotes(Pattern:TPattern; var DMMNotes:TDMMNotes; Channels:integer);

  function GetNoteVolumeForDMM(Note:TPatternNote):integer;
  begin
    Result:=127;
    if (Note.Volume<>0) and (Note.Volume<64) then
      Result:=(Note.Volume-16)*2+1;
    if (Note.Effect=EffectVolume) then // EffectVolume always overrides Note.Volume.
    begin
      if (Note.EffectParameter<64) then
      begin
        Result:=Note.EffectParameter*2+1;
      end else begin
        Result:=127;
      end;
    end;
  end;

var ConvertedDMMChannel:array[0..DMM_8_CHANNELS-1] of TDMMNotes;
    Delay:array[0..DMM_8_CHANNELS-1] of integer;
    RememberedInstrument:array[0..DMM_8_CHANNELS-1] of integer;
    ChannelStarted:array[0..DMM_8_CHANNELS-1] of boolean;
    Note:array[0..DMM_8_CHANNELS-1] of TPatternNote;
    NewNote,TempNote:TPatternNote;
    DMMNote:TDMMNote;
    Counter,RowCounter,ChannelCounter,Len:integer;
    PatternEnd:boolean; // Set on real pattern end or on PatternBreak effect
    PatternEndOnNextRow:boolean; // when true and current row is finished, PatternEnd is set.
begin
  FillChar(Delay,SizeOf(Delay),0);
  FillChar(RememberedInstrument,SizeOf(RememberedInstrument),0);
  FillChar(ChannelStarted,SizeOf(ChannelStarted),false);
  PatternEnd:=false;
  PatternEndOnNextRow:=false;

  for RowCounter:=0 to Pattern.Rows do // RowCounter=Pattern.Rows - intentionally used value
  begin
    // Process any "immediate" effects
    for ChannelCounter:=0 to Channels-1 do
    begin
      TempNote:=Pattern.GetNote(RowCounter,ChannelCounter);
      if (TempNote.Effect=EffectSpeedTempo) and (TempNote.EffectParameter>0) then
      begin
        if TempNote.EffectParameter<32 then
          NewSpeed:=TempNote.EffectParameter
        else
          NewTempo:=TempNote.EffectParameter;
      end;
    end;
    // Process as usual
    for ChannelCounter:=0 to Channels-1 do
    begin
      if RowCounter=Pattern.Rows then PatternEnd:=true;
      if not PatternEnd then
        NewNote:=Pattern.GetNote(RowCounter,ChannelCounter);
      if ChannelStarted[ChannelCounter] then
      begin
        if (Delay[ChannelCounter] > 0) and ((NewNote.Note<>0) or IsStopNoteForDMM(NewNote) or PatternEnd) then
        begin
          Len:=Length(ConvertedDMMChannel[ChannelCounter]);
          SetLength(ConvertedDMMChannel[ChannelCounter],Len+1);
          if (Note[ChannelCounter].Note=0) and not IsStopNoteForDMM(Note[ChannelCounter]) then
          begin
            ConvertedDMMChannel[ChannelCounter][Len].Note:=254;
            ConvertedDMMChannel[ChannelCounter][Len].Instrument:=Delay[ChannelCounter] div 256;
            ConvertedDMMChannel[ChannelCounter][Len].Volume:=0;
            ConvertedDMMChannel[ChannelCounter][Len].Delay:=Delay[ChannelCounter] mod 256;
          end else begin
            if IsStopNoteForDMM(Note[ChannelCounter]) then
            begin
              ConvertedDMMChannel[ChannelCounter][Len].Note:=24; // Maybe it's safe to place 0 here?
              ConvertedDMMChannel[ChannelCounter][Len].Instrument:=0;
              ConvertedDMMChannel[ChannelCounter][Len].Volume:=0;
              ConvertedDMMChannel[ChannelCounter][Len].Delay:=Delay[ChannelCounter];
            end else begin
              ConvertedDMMChannel[ChannelCounter][Len].Note:=Note[ChannelCounter].Note-25;
              ConvertedDMMChannel[ChannelCounter][Len].Volume:=GetNoteVolumeForDMM(Note[ChannelCounter]);
              if Note[ChannelCounter].Instrument=0 then
              begin
                ConvertedDMMChannel[ChannelCounter][Len].Instrument:=RememberedInstrument[ChannelCounter];
                if RememberedInstrument[ChannelCounter]=0 then
                  ConvertedDMMChannel[ChannelCounter][Len].Volume:=0;
              end else begin
                ConvertedDMMChannel[ChannelCounter][Len].Instrument:=Note[ChannelCounter].Instrument;
              end;
              ConvertedDMMChannel[ChannelCounter][Len].Delay:=Delay[ChannelCounter];
              // todo: here we go handling various XM effects that apply to notes...
            end;
          end;
          Delay[ChannelCounter]:=0;
          Note[ChannelCounter]:=NewNote;
        end;
      end else begin
        ChannelStarted[ChannelCounter]:=true;
        Note[ChannelCounter]:=NewNote;
      end;
      // todo: here we go handling various XM effects that DOESN'T apply to notes...
      if NewNote.Effect=EffectPatternBreak then
      begin
        PatternEndOnNextRow:=true;
      end;
      if not PatternEnd then
      begin
        if NewNote.Instrument<>0 then RememberedInstrument[ChannelCounter]:=NewNote.Instrument;
        Inc(Delay[ChannelCounter],Round(NewSpeed*166/NewTempo));
        if Delay[ChannelCounter]>=256 then
        begin
          // FIXME: bugfix by copypaste
          if (Note[ChannelCounter].Note<>0) or IsStopNoteForDMM(Note[ChannelCounter]) then
          begin
            Len:=Length(ConvertedDMMChannel[ChannelCounter]);
            SetLength(ConvertedDMMChannel[ChannelCounter],Len+1);
            if IsStopNoteForDMM(Note[ChannelCounter]) then
            begin
              ConvertedDMMChannel[ChannelCounter][Len].Note:=24; // Maybe it's safe to place 0 here?
              ConvertedDMMChannel[ChannelCounter][Len].Instrument:=0;
              ConvertedDMMChannel[ChannelCounter][Len].Volume:=0;
            end else begin
              ConvertedDMMChannel[ChannelCounter][Len].Note:=Note[ChannelCounter].Note-25;
              ConvertedDMMChannel[ChannelCounter][Len].Volume:=GetNoteVolumeForDMM(Note[ChannelCounter]);
              if Note[ChannelCounter].Instrument=0 then
              begin
                ConvertedDMMChannel[ChannelCounter][Len].Instrument:=RememberedInstrument[ChannelCounter];
                if RememberedInstrument[ChannelCounter]=0 then
                  ConvertedDMMChannel[ChannelCounter][Len].Volume:=0;
              end else begin
                ConvertedDMMChannel[ChannelCounter][Len].Instrument:=Note[ChannelCounter].Instrument;
              end;
              // todo: here we go handling various XM effects that apply to notes...
            end;
            ConvertedDMMChannel[ChannelCounter][Len].Delay:=255;
            Dec(Delay[ChannelCounter],255);
            Note[ChannelCounter].Note := 0;
            Note[ChannelCounter].Instrument := 0;
            Note[ChannelCounter].Volume := 0;
            Note[ChannelCounter].Effect := 0;
            Note[ChannelCounter].EffectParameter := 0;
          end;
          // end copypaste
          Len:=Length(ConvertedDMMChannel[ChannelCounter]);
          SetLength(ConvertedDMMChannel[ChannelCounter],Len+1);
          ConvertedDMMChannel[ChannelCounter][Len].Note:=254;
          ConvertedDMMChannel[ChannelCounter][Len].Instrument:=Delay[ChannelCounter] div 256;
          ConvertedDMMChannel[ChannelCounter][Len].Volume:=0;
          ConvertedDMMChannel[ChannelCounter][Len].Delay:=Delay[ChannelCounter] mod 256;
          Delay[ChannelCounter]:=0;
        end;
      end;
    end; // for ChannelCounter:=0 to Channels-1 do
    if PatternEnd then break;
    if PatternEndOnNextRow then PatternEnd:=true;
  end; // for RowCounter:=0 to Pattern.Rows do
  // Saving channels into notes
  for ChannelCounter:=0 to DMM_8_CHANNELS-1 do
  begin
    Len:=Length(DMMNotes);
    SetLength(DMMNotes,Len+Length(ConvertedDMMChannel[ChannelCounter])+1);
    for Counter:=0 to Length(ConvertedDMMChannel[ChannelCounter])-1 do
    begin
      DMMNotes[Len+Counter]:=ConvertedDMMChannel[ChannelCounter][Counter];
    end;
    DMMNote.Note:=255;
    DMMNote.Instrument:=0;
    DMMNote.Volume:=128;
    DMMNote.Delay:=0;
    DMMNotes[Length(DMMNotes)-1]:=DMMNote;
  end;
end;

function MakeDMMSampleName(S:string):string;
var Counter,Counter2:integer;
begin
  Counter2:=1;
  SetLength(Result,Length(S));
  for Counter:=1 to Length(S) do
  begin
    if S[Counter] in ['0'..'9','A'..'Z','a'..'z','_'] then
    begin
      Result[Counter2]:=S[Counter];
      Inc(Counter2);
      if Counter2>7 then
      begin
        Counter2:=7;
        Break;
      end;
    end;
  end;
  SetLength(Result,Counter2-1);
end;

procedure SaveDMI(Sample:TSample; FileName:string);
var DMIFile:TFileStream;
    SampleBuffer:array of shortint;
    DMILength,DMISampleRate,DMILoopStart,DMILoopLength:word;
    Counter:integer;
begin
  DMILength:=Sample.SampleLength;
  DMISampleRate:=XMToSampleRate(Sample.RelativeNote,Sample.Finetune);
  if Sample.Loop then
  begin
    DMILoopStart:=Sample.LoopStart;
    DMILoopLength:=Sample.LoopLength;
  end else begin
    DMILoopStart:=0;
    DMILoopLength:=0;
  end;

  SetLength(SampleBuffer,DMILength);
  for Counter:=0 to DMILength-1 do
  begin
    SampleBuffer[Counter]:=PIntegers(Sample.data)[Counter] div 256;
  end;

  DMIFile:=TFileStream.CreateNew(FileName);
  DMIFile.Write(DMILength,2);
  DMIFile.Write(DMISampleRate,2);
  DMIFile.Write(DMILoopStart,2);
  DMIFile.Write(DMILoopLength,2);
  DMIFile.Write(SampleBuffer[0],DMILength);
  DMIFile.Free;
end;

var
  XM:TXMModule;
  DMMFile:TFileStream;
  Wad:TWadFile;
  Parameter,Parameter2:string;
  OutputFileName:string;
  DMMInWadName:string;
  DMMInstrumentName:string; // used in backward conversion
  TempNote:TPatternNote; // used in backward conversion

  DMMHeader:array[0..4] of char;
  DMMPatternNumber:byte;
  DMMNoteNumber:word;
  DMMNotes:TDMMNotes;
  DMMPatternOrderSize:byte;
  DMMPatternOrder:array of byte;
  DMMInstrumentNumber:byte;
  DMMInstruments:array of TDMMInstrument;
  // used for unpacking
  NotesRead,ChannelsFinished,NewPatternLength:integer;
  DMMPatterns:array of TDMMNotes;
  // dmm2xm v1.4
  StartPatternNumber:byte;
  DMM2XMPattern:array[0..255] of array[0..1] of byte; // 0 = shift, 1 = length
  PatShift,PatLength:byte;

  Counter,Counter2,Counter3:integer;
begin
  Randomize;
  if ParamCount=0 then
  begin
    Write2(#10+DMM2XM_VERSION_TEXT+#10
      +#10
      +'Usage: dmm2xm [-q <number>] [-r <number>] [-o <file>] [-f <name>] [-m] [-b]'#10
      +'              <song.dmm>|<file.wad>'#10
      +'Backward conversion: dmm2xm [-o <file>] <song.xm>|<song.mod>'#10
      +#10
      +'Parameters:'#10
      +'  -q   Set quantization. Default value: 4.'#10
      +'  -r   Set max number of rows per pattern. Default value: 256.'#10
      +'  -o   Set output file. Default value: name of input file + extension.'#10
      +'  -f   Specify DMM file to be converted from WAD. Default WAD: doom2d.wad'#10
      +'  -m   Leave converted song in mono.'#10
      +'  -b   Emulate SoundBlaster bug at 44 KHz (finetune+64).'#10
      +#10
      +'Note: Used DMI files (instruments) must be in same directory as DMM file'#10
      +'      or in DMI subfolder (dmi\*) and be without extension.'#10);
    Exit;
  end;

  // Set default values
  UsedChannels:=2; // 2 is minimum channels
  Quantization:=4;
  LoadingFromWad:=false;
  DMMInWadName:='';
  OutputFileName:='';
  NoStereo:=false;
  MaxRows:=256;

  Counter:=1;
  while Counter<=ParamCount do
  begin
    Parameter:=ParamStr(Counter);
    Write2('"'+Parameter+'"'#10);
    if Parameter='-q' then
    begin
      Quantization:=Str2Int(ParamStr(Counter+1));
      Inc(Counter);
    end else if Parameter='-o' then
    begin
      OutputFileName:=ParamStr(Counter+1);
      Inc(Counter);
    end else if Parameter='-f' then
    begin
      DMMInWadName:=ParamStr(Counter+1);
      InputFileName:='doom2d.wad';
      Inc(Counter);
    end else if Parameter='-r' then
    begin
      MaxRows:=Str2Int(ParamStr(Counter+1));
      Inc(Counter);
    end else if Parameter='-m' then
    begin
      NoStereo:=true;
    end else if Parameter='-b' then
    begin
      EmulateBug:=true;
    end else begin
      InputFileName:=Parameter;
    end;
    Inc(Counter);
  end;

  if not FileExists(InputFileName) then
  begin
    Write2('Error: File "'+InputFileName+'" not found!'#10);
    Exit;
  end;

  // Backward conversion
  if (GetExtension(InputFileName)='mod') or (GetExtension(InputFileName)='xm') then
  begin
    XM:=TXMModule.Create;
    Write2(':: Reading module: "'+InputFileName+'"...'#10);
    if not XM.LoadFile(InputFileName) then
    begin
      XM.Destroy;
      Write2('Error: Couldn''t load "'+InputFileName+'"!'#10);
      Exit;
    end;
    if OutputFileName='' then OutputFileName:=CutExtension(InputFileName)+'.dmm';
    Write2(':: Converting module to DMM...'#10);
    DMMPatternNumber:=XM.NumberOfPatterns;
    if XM.NumberOfChannels>8 then
    begin
      Write2('Warning: Too many channels in module, only first 8 will be used.'#10);
      XM.NumberOfChannels:=8;
    end;
    // remove NoteStops in the beginning of pattern
    for Counter:=0 to DMMPatternNumber-1 do
    begin
      for Counter2:=0 to XM.NumberOfChannels-1 do
      begin
        TempNote:=XM.Pattern[Counter].GetNote(0,Counter2);
        if IsStopNoteForDMM(TempNote) then
        begin
          XM.Pattern[Counter].SetNote(0,Counter2,MakeNote(0));
        end;
      end;
    end;

    NewSpeed:=XM.StartSpeed;
    NewTempo:=XM.StartTempo;
    for Counter:=0 to DMMPatternNumber-1 do
    begin
      PatternToDMMNotes(XM.Pattern[Counter],DMMNotes,XM.NumberOfChannels);
    end;
    DMMNoteNumber:=Length(DMMNotes);

    // Convert pattern order to DMM pattern order
    DMMPatternOrderSize:=XM.TrackLength+2;
    SetLength(DMMPatternOrder,DMMPatternOrderSize);
    for Counter:=0 to DMMPatternOrderSize-3 do
    begin
      DMMPatternOrder[Counter]:=XM.PatternOrder[Counter];
    end;
    DMMPatternOrder[DMMPatternOrderSize-2]:=255;
    // todo: handle pattern jumps too
    DMMPatternOrder[DMMPatternOrderSize-1]:=XM.RestartPosition;
    // Convert instruments
    DMMInstrumentNumber:=XM.NumberOfInstruments;
    SetLength(DMMInstruments,DMMInstrumentNumber);
    for Counter:=0 to DMMInstrumentNumber-1 do
    begin
      FillChar(DMMInstruments,0,SizeOf(TDMMInstrument));
      DMMInstrumentName:='';
      // todo: warn about multisample instuments
      // todo: support multisample instuments?
      if XM.Instrument[Counter+1].Sample[0]<>nil then
      begin
        if XM.Instrument[Counter+1].Sample[0].SampleLength=0 then
        begin
          DMMInstrumentName:='';
        end else begin
          DMMInstrumentName:=MakeDMMSampleName(XM.Instrument[Counter+1].Sample[0].Name)+Int2Digs(Counter+1,2);
          if DMMInstrumentName='' then
            DMMInstrumentName:=MakeDMMSampleName(XM.Instrument[Counter+1].Name)+Int2Digs(Counter+1,2);
          if DMMInstrumentName='' then
            DMMInstrumentName:='DMIU'+Int2Str(Random(10))+Int2Str(Random(10))+Int2Digs(Counter+1,2);
          // todo: better instuments naming?
          SaveDMI(XM.Instrument[Counter+1].Sample[0],DMMInstrumentName);
        end;
        for Counter2:=1 to Length(DMMInstrumentName) do
        begin
          DMMInstruments[Counter].Name[Counter2-1]:=DMMInstrumentName[Counter2];
        end;
      end;
    end;
    XM.Destroy;

    Write2(':: Saving DMM to "'+OutputFileName+'"...');
    DMMFile:=TFileStream.CreateNew(OutputFileName);
    DMMFile.Write('DMM'#0#0,5);
    DMMFile.Write(DMMPatternNumber,1);
    DMMFile.Write(DMMNoteNumber,2);
    DMMFile.Write(DMMNotes[0],DMMNoteNumber*SizeOf(TDMMNote));
    DMMFile.Write(DMMPatternOrderSize,1);
    DMMFile.Write(DMMPatternOrder[0],DMMPatternOrderSize);
    DMMFile.Write(DMMInstrumentNumber,1);
    DMMFile.Write(DMMInstruments[0],DMMInstrumentNumber*SizeOf(TDMMInstrument));
    DMMFile.Destroy;
    Write2(' OK.'#10#10);
    Exit;
  end;

  if (Quantization<1) or (Quantization>31) then
  begin
    Write2('Error: Invalid quantization value, should be 1 <= Q <= 31.'#10);
    Exit;
  end;
  if (MaxRows<1) or (MaxRows>1024) then
  begin
    Write2('Error: Invalid max rows value, should be 1 <= R <= 1024.'#10);
    Exit;
  end;
  if (MaxRows>256) then
  begin
    Write2('Warning: Rows value > 256, non-standard, some players WILL glitch!'#10);
  end;
  if GetExtension(InputFileName)='wad' then LoadingFromWad:=true;
  if LoadingFromWad then
  begin
    if DMMInWadName='' then
    begin
      ListDMMInWad(InputFileName);
      Exit;
    end;
    if OutputFileName='' then OutputFileName:=DMMInWadName+'.xm';
    Wad:=TWadFile.Create(InputFileName);
    if not Wad.ValidWad then
    begin
      Wad.Free;
      Write2('Error: Invalid WAD file: "'+InputFileName+'".'#10);
      Exit;
    end;
    if not Wad.SeekToFile(OemStr(DMMInWadName)) then
    begin
      Wad.Free;
      Write2('Error: File "'+DMMInWadName+'" not found in WAD!'#10);
      Exit;
    end;
    Write2(':: Reading DMM from WAD: "'+DMMInWadName+'"...'#10);
    Wad.Read(DMMHeader,SizeOf(DMMHeader));
    if (DMMHeader[0]<>'D') or (DMMHeader[1]<>'M') or (DMMHeader[2]<>'M')
      or (DMMHeader[3]<>#0) or (DMMHeader[4]<>#0) then
    begin
      Wad.Free;
      Write2('Error: Unknown DMM format!'#10);
      Exit;
    end;
    Wad.Read(DMMPatternNumber,1);
    Wad.Read(DMMNoteNumber,2);
    SetLength(DMMNotes,DMMNoteNumber);
    Wad.Read(DMMNotes[0],DMMNoteNumber*SizeOf(TDMMNote));
    Wad.Read(DMMPatternOrderSize,1);
    SetLength(DMMPatternOrder,DMMPatternOrderSize);
    Wad.Read(DMMPatternOrder[0],DMMPatternOrderSize);
    Wad.Read(DMMInstrumentNumber,1);
    SetLength(DMMInstruments,DMMInstrumentNumber);
    Wad.Read(DMMInstruments[0],DMMInstrumentNumber*SizeOf(TDMMInstrument));
  end else begin
    if OutputFileName='' then OutputFileName:=CutExtension(InputFileName)+'.xm';
    Wad:=nil;
    Write2(':: Reading DMM: "'+InputFileName+'"...'#10);
    DMMFile:=TFileStream.Create(InputFileName);
    DMMFile.Read(DMMHeader,SizeOf(DMMHeader));
    if (DMMHeader[0]<>'D') or (DMMHeader[1]<>'M') or (DMMHeader[2]<>'M')
      or (DMMHeader[3]<>#0) or (DMMHeader[4]<>#0) then
    begin
      DMMFile.Free;
      Write2('Error: Unknown DMM format!'#10);
      Exit;
    end;
    DMMFile.Read(DMMPatternNumber,1);
    DMMFile.Read(DMMNoteNumber,2);
    SetLength(DMMNotes,DMMNoteNumber);
    DMMFile.Read(DMMNotes[0],DMMNoteNumber*SizeOf(TDMMNote));
    DMMFile.Read(DMMPatternOrderSize,1);
    SetLength(DMMPatternOrder,DMMPatternOrderSize);
    DMMFile.Read(DMMPatternOrder[0],DMMPatternOrderSize);
    DMMFile.Read(DMMInstrumentNumber,1);
    SetLength(DMMInstruments,DMMInstrumentNumber);
    DMMFile.Read(DMMInstruments[0],DMMInstrumentNumber*SizeOf(TDMMInstrument));
    DMMFile.Free;
  end;

  XM:=TXMModule.Create;

  if LoadingFromWad then XM.Name:=DMMInWadName
    else XM.Name:=CutExtension(ExtractFileName(InputFileName));

  XM.LinearSlides:=true;
  XM.StartTempo:=166; //125+33%
  XM.StartSpeed:=Quantization;
  XM.Comment:='Converted with '+DMM2XM_VERSION_TEXT;

  Write2(':: Reading instuments...'#10);
  for Counter:=0 to DMMInstrumentNumber-1 do
  begin
    XM.Instrument[Counter+1]:=TInstrument.Create;
    if not LoadInstrumentFromDMI(XM.Instrument[Counter+1],
      DMMInstruments[Counter].Name,Counter,DMMInstrumentNumber,Wad) then
    begin
      Write2('Warning: Couldn''t find instrument "'+DMMInstruments[Counter].Name+'".'#10);
    end;
  end;
  if not NoStereo and (DMMInstrumentNumber>MAX_SAMPLES) then
  begin
    Write2('Warning: Found more than 11 instruments, stereo is not available.'#10);
  end;

  if LoadingFromWad then Wad.Free;

  Write2(':: Recording notes with quantization = '+Int2Str(Quantization)+'...'#10);
  SetLength(DMMPatterns,DMMPatternNumber);
  NotesRead:=0;
  // dmm2xm v1.4
  MinNoteDelay := 256;

  for Counter:=0 to DMMPatternNumber-1 do
  begin
    ChannelsFinished:=0;
    repeat
      if NotesRead=DMMNoteNumber then
      begin
        Write2('Warning: Unexpected end of notes, possibly broken data.'#10);
        Break;
      end;
      NewPatternLength:=Length(DMMPatterns[Counter])+1;
      SetLength(DMMPatterns[Counter],NewPatternLength);

      DMMPatterns[Counter][NewPatternLength-1]:=DMMNotes[NotesRead];
      if IsFinishNote(DMMNotes[NotesRead]) then Inc(ChannelsFinished);
      Inc(NotesRead);
    until ChannelsFinished=DMM_8_CHANNELS;
    if NotesRead=DMMNoteNumber then Break;
  end;

  // dmm2xm v1.4
  for Counter:=0 to LastPattern do
  begin
    XM.Pattern[Counter].Resize(MaxRows,DMM_8_CHANNELS);
  end;
  StartPatternNumber:=0;
  for Counter:=0 to DMMPatternNumber-1 do
  begin
    Write2('DMM pattern '+Int2Str(Counter)+'...');
    Counter2:=RecordPatternsFromDMMPattern(XM,DMMPatterns[Counter],Counter,StartPatternNumber);
    if Counter2=1 then
      Write2(' -> XM pattern '+Int2Str(StartPatternNumber)+#10)
    else
      Write2(' -> XM patterns '+Int2Str(StartPatternNumber)+'..'+Int2Str(StartPatternNumber+Counter2-1)+#10);
    DMM2XMPattern[Counter][0]:=StartPatternNumber;
    DMM2XMPattern[Counter][1]:=Counter2;
    Inc(StartPatternNumber,Counter2);
  end;

  for Counter:=0 to Length(MisalignedNotes)-1 do
  begin
    with MisalignedNotes[Counter] do
    begin
      Write2('Misaligned note at pattern '+Int2Str(Pattern)+', channel '
        +Int2Str(Channel)+', row '+Int2Str(Row)+' (Delay = '
        +Int2Str(Delay)+' -> '+Int2Str(NewDelay)+')'+#10);
    end;
  end;

  if Length(MisalignedNotes)>0 then
  begin
    Write2('Warning: Quantization may be wrong or too large, misaligned '
      +Int2Str(Length(MisalignedNotes))+' notes.'#10);
  end;
  // dmm2xm v1.4
  Write2('Minimum note delay was '+Int2Str(MinNoteDelay)+'.'#10);

  XM.TrackLength:=0;
  Counter3:=0;

  if DMMPatternOrderSize=0 then
  begin
    Write2('Warning: Pattern order missing, rebuilding as sequential.'#10);
    DMMPatternOrderSize:=DMMPatternNumber;
    SetLength(DMMPatternOrder,DMMPatternNumber);
    for Counter:=0 to DMMPatternNumber-1 do
      DMMPatternOrder[Counter]:=Counter;
  end;

  for Counter:=0 to DMMPatternOrderSize-1 do
  begin
    if DMMPatternOrder[Counter]=255 then
    begin
      if Counter=DMMPatternOrderSize-1 then
      begin
        Write2('Warning: Unexpected end of pattern order, possibly broken data.'#10);
        Break;
      end;
      XM.RestartPosition:=DMM2XMPattern[DMMPatternOrder[Counter+1]][0]; // dmm2xm v1.4
      Write2('Restart position: '+Int2Str(DMMPatternOrder[Counter+1])+' -> '+Int2Str(XM.RestartPosition)+#10);
      Break;
    end else begin
      PatShift:=DMM2XMPattern[DMMPatternOrder[Counter]][0];
      PatLength:=DMM2XMPattern[DMMPatternOrder[Counter]][1];
      Inc(XM.TrackLength,PatLength);
      for Counter2:=0 to PatLength-1 do
      begin
        XM.PatternOrder[Counter3]:=PatShift+Counter2;
        Inc(Counter3);
        //Write2('xm['+Int2Str(PatShift+Counter2)+']:=dmm['+Int2Str(PatShift+Counter2)+']'+#10);
      end;
    end;
  end;
  Write2('Track length: '+Int2Str(XM.TrackLength)+#10);

  Write2('DMM Patterns: ');
  for Counter:=0 to DMMPatternOrderSize-1 do
  begin
    if DMMPatternOrder[Counter]=255 then
    begin
      Write2('(loop)');
      break;
    end;
    Write2(Int2Str(DMMPatternOrder[Counter])+' ');
  end;
  Write2(#10' XM Patterns: ');
  for Counter:=0 to XM.TrackLength-1 do
  begin
    Write2(Int2Str(XM.PatternOrder[Counter])+' ');
  end;
  Write2(#10);

  Write2(':: Optimizing...'#10);
  // dmm2xm v1.4
  for Counter:=StartPatternNumber to LastPattern do
  begin
    XM.Pattern[Counter].Resize(0,0);
  end;
  if UsedChannels<DMM_8_CHANNELS then
  begin
    for Counter:=0 to StartPatternNumber-1 do
    begin
      if XM.Pattern[Counter].Rows>0 then
        XM.Pattern[Counter].Resize(XM.Pattern[Counter].Rows,UsedChannels);
    end;
    Write2('Only '+Int2Str(UsedChannels)+' of 8 channels used. Removed unused channels.'#10);
  end;
  XM.NumberOfChannels:=UsedChannels;

  Write2(':: Saving to "'+OutputFileName+'"...');
  XM.SaveFile(OutputFileName);
  XM.Destroy;
  Write2(' OK.'#10#10);
end.
