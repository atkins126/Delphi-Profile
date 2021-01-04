unit Delphi.Profile.TraceTest;

interface

uses
  DUnitX.TestFramework,
  Delphi.Mocks,
  Delphi.Profile.Trace,
  System.Generics.Collections;

type

  TTraceEvent = record
    FEventType: (TraceEnter, TraceLeave);
    FElapsedTicks: Int64;
    FScopeName: string;
  end;

  [TestFixture]
  TTraceTest = class
    private
      FTracer: TMock<ITracer>;
      FTraces: TStack<TTraceEvent>;

      procedure SetupMock;

    public
      [Setup]
      procedure Setup;
      [TearDown]
      procedure TearDown;

      [Test]
      procedure TestSetTrace;

      [Test]
      [TestCase('Empty scope name', '')]
      [TestCase('Non-empty scope name', 'abcdefghijklmnopqrstuvwxyz')]
      procedure TestTrace(const AScopeName: string);

      [Test]
      procedure TestNestedTrace;
  end;

implementation

uses
  System.Rtti;

procedure TTraceTest.Setup;
begin
  FTracer       := TMock<ITracer>.Create;
  FTraces       := TStack<TTraceEvent>.Create;
  TTrace.Tracer := FTracer;
  SetupMock;
end;

procedure TTraceTest.SetupMock;
begin
  FTracer.Setup.WillExecute('OnEnter',
      function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    var
      Event: TTraceEvent;
    begin
      Event.FEventType := TraceEnter;
      Event.FElapsedTicks := args[1].AsType<Int64>();
      Event.FScopeName := args[2].AsType<string>();
      FTraces.Push(Event);
    end);
  FTracer.Setup.WillExecute('OnLeave',
    function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    var
      Event: TTraceEvent;
    begin
      Event.FEventType := TraceLeave;
      Event.FElapsedTicks := args[1].AsType<Int64>();
      FTraces.Push(Event);
    end);
end;

procedure TTraceTest.TearDown;
begin
  FTracer.Free;
  FTraces.Free;
end;

procedure TTraceTest.TestSetTrace;
begin
  TTrace.Tracer := nil;
  FTracer.Setup.Expect.Never('OnEnter');
  FTracer.Setup.Expect.Never('OnLeave');
  begin
    TTrace.Create('');
  end;
  Assert.AreEqual(0, FTraces.Count);
  FTracer.VerifyAll;
end;

procedure TTraceTest.TestTrace(const AScopeName: string);
begin
  FTracer.Setup.Expect.Once('OnEnter');
  FTracer.Setup.Expect.Once('OnLeave');
  begin
    TTrace.Create(AScopeName); // count number of ticks spent in this block
  end;
  Assert.AreEqual(2, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FElapsedTicks < 3);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual(AScopeName, FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
      Assert.IsTrue(FElapsedTicks > 1000);
    end;
  FTracer.VerifyAll;
end;

procedure TTraceTest.TestNestedTrace;
begin
  FTracer.Setup.Expect.Exactly('OnEnter', 2);
  FTracer.Setup.Expect.Exactly('OnLeave', 2);
  begin
    TTrace.Create('Outer');
    begin
      TTrace.Create('Inner');
    end;
  end;
  Assert.AreEqual(4, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FElapsedTicks < 3);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FElapsedTicks < 3);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual('Inner', FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
      Assert.IsTrue(FElapsedTicks < 3);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual('Outer', FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
      Assert.IsTrue(FElapsedTicks > 1000);
    end;
  FTracer.VerifyAll;
end;

initialization

TDUnitX.RegisterTestFixture(TTraceTest);

end.
