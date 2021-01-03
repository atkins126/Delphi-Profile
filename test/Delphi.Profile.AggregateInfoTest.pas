unit Delphi.Profile.AggregateInfoTest;

interface

uses
  DUnitX.TestFramework,
  Delphi.Profile.AggregateInfo;

type

  [TestFixture]
  TAggregateInfoTest = class
    private
      FAggregateInfo: TAggregateInfo;

    public
      [TearDown]
      procedure TearDown;

      [Test]
      procedure TestGetCommaHeader;

      [Test]
      [TestCase('Fibbo', '1|1|2|"abc","4.000","1.000","1.333","0.577"', '|')]
      procedure TestGetCommaText(AValue1, AValue2, AValue3: Double; const AExpected: string);

      [Test]
      [TestCase('Fibbo', '1,1,2,4')]
      procedure TestTotal(AValue1, AValue2, AValue3, AExpected: Double);

      [Test]
      [TestCase('Fibbo', '1,1,2,1')]
      procedure TestMedian(AValue1, AValue2, AValue3, AExpected: Double);

      [Test]
      [TestCase('Fibbo', '1,1,2,1.3333333333333')]
      procedure TestMean(AValue1, AValue2, AValue3, AExpected: Double);

      [Test]
      [TestCase('Fibbo', '1,1,2,0.57735026918963')]
      procedure TestStddev(AValue1, AValue2, AValue3, AExpected: Double);
  end;

implementation

uses
  System.SysUtils;

{ TAggregateInfoTest }

procedure TAggregateInfoTest.TearDown;
begin
  FAggregateInfo.Free;
end;

procedure TAggregateInfoTest.TestGetCommaHeader;
begin
  Assert.AreEqual('"Measure","Total","Median","Mean","Standard Deviation"', TAggregateInfo.CommaHeader);
end;

procedure TAggregateInfoTest.TestGetCommaText(AValue1, AValue2, AValue3: Double; const AExpected: string);
begin
  FAggregateInfo := TAggregateInfo.Create('abc', [AValue1, AValue2, AValue3]);
  Assert.AreEqual(AExpected, FAggregateInfo.CommaText);
end;

procedure TAggregateInfoTest.TestMean(AValue1, AValue2, AValue3, AExpected: Double);
begin
  FAggregateInfo := TAggregateInfo.Create('abc', [AValue1, AValue2, AValue3]);
  Assert.AreEqual(AExpected, FAggregateInfo.Mean);
end;

procedure TAggregateInfoTest.TestMedian(AValue1, AValue2, AValue3, AExpected: Double);
begin
  FAggregateInfo := TAggregateInfo.Create('abc', [AValue1, AValue2, AValue3]);
  Assert.AreEqual(AExpected, FAggregateInfo.Median);
end;

procedure TAggregateInfoTest.TestStddev(AValue1, AValue2, AValue3, AExpected: Double);
begin
  FAggregateInfo := TAggregateInfo.Create('abc', [AValue1, AValue2, AValue3]);
  Assert.AreEqual(AExpected, FAggregateInfo.Stddev);
end;

procedure TAggregateInfoTest.TestTotal(AValue1, AValue2, AValue3, AExpected: Double);
begin
  FAggregateInfo := TAggregateInfo.Create('abc', [AValue1, AValue2, AValue3]);
  Assert.AreEqual(AExpected, FAggregateInfo.Total);
end;

initialization

TDUnitX.RegisterTestFixture(TAggregateInfoTest);

end.
