unit Delphi.Profile.Trace;

interface

type

{$M+} // Enable RTTI for use in the unit tests

  ITracer = interface
    procedure OnEnter(AElapsedTicks: Int64; const AScopeName: string);
    procedure OnLeave(AElapsedTicks: Int64);
  end;

{$M-}

  TTrace = class(TInterfacedObject, IInterface)
    private
      class threadvar FStartTime: Int64;
      class var FTracer         : ITracer;

      function _Release: Integer; stdcall;

    public
      class property Tracer: ITracer write FTracer;
      class function Create(const AScopeName: string): IInterface;
  end;

implementation

uses
  System.Diagnostics;

{ TTrace }

function TTrace._Release: Integer;
var
  ElapsedTicks: Int64;
begin
  ElapsedTicks := TStopwatch.GetTimeStamp - FStartTime;
  Result       := inherited;
  if Result = 0 then
    try
      FTracer.OnLeave(ElapsedTicks);
    finally
      FStartTime := TStopwatch.GetTimeStamp;
    end;
end;

class function TTrace.Create(const AScopeName: string): IInterface;
var
  ElapsedTicks: Int64;
begin
  ElapsedTicks := TStopwatch.GetTimeStamp - FStartTime;
  if Assigned(FTracer) then
    try
      Result := inherited Create;
      FTracer.OnEnter(ElapsedTicks, AScopeName);
    finally
      FStartTime := TStopwatch.GetTimeStamp;
    end
  else
    Result := nil;
end;

initialization

TStopwatch.Create; // initialize the stopwatch type

end.
