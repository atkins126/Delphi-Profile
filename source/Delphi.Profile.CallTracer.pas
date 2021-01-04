unit Delphi.Profile.CallTracer;

interface

uses
  Delphi.Profile.Trace,
  Delphi.Profile.CallReport,
  System.Generics.Collections,
  System.SyncObjs;

type

  TCallTracer = class(TInterfacedObject, ITracer)
    private
      FCallStack          : TStack<string>;
      FCallReport         : TCallReport;
      FCriticalSection    : TCriticalSection;
      FCallReportPath     : string;
      FAggregateReportPath: string;

      procedure OnEnter(AElapsedTicks: Int64; const AScopeName: string);
      procedure OnLeave(AElapsedTicks: Int64);

    public
      constructor Create;
      destructor Destroy; override;

      procedure SaveReport;

      property CallReportPath: string write FCallReportPath;
      property AggregateReportPath: string write FAggregateReportPath;
  end;

implementation

uses
  System.Classes;

{ TCallTracer }

constructor TCallTracer.Create;
begin
  FCriticalSection     := TCriticalSection.Create;
  FCallStack           := TStack<string>.Create;
  FCallReport          := TCallReport.Create;
  FCallReportPath      := 'calls.csv';
  FAggregateReportPath := 'aggregate.csv';
end;

destructor TCallTracer.Destroy;
begin
  try
    SaveReport;
  except
    // we cannot not raise in destructor
  end;
  FCallReport.Free;
  FCallStack.Free;
  FCriticalSection.Free;
  inherited;
end;

procedure TCallTracer.SaveReport;
var
  CallLines     : TStrings;
  AggregateLines: TStrings;
begin
  CallLines      := TStringList.Create;
  AggregateLines := TStringList.Create;
  try
    FCallReport.GetLines(CallLines, AggregateLines);
    CallLines.SaveToFile(FCallReportPath);
    AggregateLines.SaveToFile(FAggregateReportPath);
  finally
    CallLines.Free;
    AggregateLines.Free;
  end;
end;

procedure TCallTracer.OnEnter(AElapsedTicks: Int64; const AScopeName: string);
begin
  FCriticalSection.Acquire;
  try
    if FCallStack.Count > 0 then
      FCallReport.Add(FCallStack.Peek, AElapsedTicks);
    FCallStack.Push(AScopeName);
  finally
    FCriticalSection.Release;
  end;
end;

procedure TCallTracer.OnLeave(AElapsedTicks: Int64);
begin
  FCriticalSection.Acquire;
  try
    Assert(FCallStack.Count > 0);
    FCallReport.Add(FCallStack.Pop, AElapsedTicks);
  finally
    FCriticalSection.Release;
  end;
end;

initialization

TTrace.Tracer := TCallTracer.Create;

end.
