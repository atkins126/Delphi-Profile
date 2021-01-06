unit Delphi.Profile.Trace;

interface

uses
  Delphi.Profile.PerformanceMetrics;

type

{$M+} // Enable RTTI for use in the unit tests

  ITracer = interface
    function OnEnterScope(const AMetrics: TPerformanceMetrics; const AScopeName: string): Boolean;
    procedure OnLeaveScope(const AMetrics: TPerformanceMetrics);
  end;

{$M-}

  TTrace = class sealed(TInterfacedObject, IInterface)
    private
      class threadvar FStartMetrics: TPerformanceMetrics;
      class var FTracer            : ITracer; // set once during program initialization

      class function GetElapsed: TPerformanceMetrics; inline;

      function _Release: Integer; stdcall;

    public
      class property Tracer: ITracer write FTracer;

      class function Create(const AScopeName: string): IInterface;
  end;

implementation

{ TTrace }

class function TTrace.GetElapsed: TPerformanceMetrics;
begin
  Result.AcquireEnd;
  Result.Subtract(FStartMetrics);
end;

function TTrace._Release: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  Result := AtomicDecrement(FRefCount);
{$ELSE}
  Result := __ObjRelease;
{$ENDIF}
  if Result = 0 then
    try
      FTracer.OnLeaveScope(GetElapsed);
    finally
{$IFNDEF AUTOREFCOUNT}
      __MarkDestroying(Self);
      Destroy;
{$ENDIF}
      FStartMetrics.AcquireStart;
    end;
end;

class function TTrace.Create(const AScopeName: string): IInterface;
begin
  if Assigned(FTracer) and FTracer.OnEnterScope(GetElapsed, AScopeName) then
    begin
      Result := inherited Create; // create a trace only if the scope name was not filtered by the tracer
      FStartMetrics.AcquireStart; // start counting performance only if the trace was properly created
    end
  else
    Result := nil;
end;

end.
