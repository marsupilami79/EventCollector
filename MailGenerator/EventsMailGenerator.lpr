program EventsMailGenerator;

{$mode delphi}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, DmMain, SysUtils
  { you can add units after this };

var
  MainDM: TEvaluatorDM;

begin
  try
    MainDm := TEvaluatorDM.Create(nil);
    try
      MainDM.Evaluate;
    finally
      MainDm.Free;
    end;
  except
    on E: Exception do
      Writeln('Exception: ' + E.Message);
  end;
end.

