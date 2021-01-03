unit Delphi.Profile.TraceTest;

interface

uses
  DUnitX.TestFramework,
  Delphi.Mocks,
  Delphi.Profile,
  System.Generics.Collections;

type

  [TestFixture]
  TTraceTest = class
    private
      FTracer: TMock<ITracer>;
      FTraces: TStack<TTraceInfo>;

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
  System.Rtti,
  Delphi.Profile.Trace;

procedure TTraceTest.Setup;
begin
  FTracer := TMock<ITracer>.Create;
  FTraces := TStack<TTraceInfo>.Create;
  FTracer.Setup.WillExecute('Log',
      function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    begin
      FTraces.Push(args[1].AsType<TTraceInfo>());
    end);
  TTrace.Tracer := FTracer;
end;

procedure TTraceTest.TearDown;
begin
  FTracer.Free;
  FTraces.Free;
end;

procedure TTraceTest.TestSetTrace;
begin
  TTrace.Tracer := nil;
  FTracer.Setup.Expect.Never('Log');
  begin
    Trace(''); // this should do nothing
  end;
  Assert.AreEqual(0, FTraces.Count);
  FTracer.VerifyAll;
end;

procedure TTraceTest.TestTrace(const AScopeName: string);
begin
  FTracer.Setup.Expect.Exactly('Log', 2);
  begin
    Trace(AScopeName); // count number of ticks spent in this block
  end;
  Assert.AreEqual(2, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual(AScopeName, FScopeName);
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FElapsedTicks < 3);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual(AScopeName, FScopeName);
      Assert.AreEqual(TraceEnter, FEventType);
      Assert.IsTrue(FElapsedTicks > 0);
    end;
  FTracer.VerifyAll;
end;

procedure TTraceTest.TestNestedTrace;
begin
  FTracer.Setup.Expect.Exactly('Log', 4);
  begin
    Trace('Outer');
    begin
      Trace('Inner');
    end;
  end;
  Assert.AreEqual(4, FTraces.Count);
  with FTraces.Pop do
    begin
      Assert.AreEqual('Outer', FScopeName);
      Assert.AreEqual(TraceLeave, FEventType);
      Assert.IsTrue(FElapsedTicks < 3);
    end;
  with FTraces.Pop do
    begin
      Assert.AreEqual('Inner', FScopeName);
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
      Assert.IsTrue(FElapsedTicks > 0);
    end;
  FTracer.VerifyAll;
end;

initialization

TDUnitX.RegisterTestFixture(TTraceTest);

end.
