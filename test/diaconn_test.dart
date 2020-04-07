import 'package:test/test.dart';

final pageSize = 10;
void main() {
  /* test('CASE 1: 0(0),	0(0), 40(0)', () {
    // 동기화 필요: 플랫폼, 앱
    expect(
      syncPumpLog(0, 0, 0, 0, 40, 0, pageSize),
      RequestPumpLogNo(start: 0, end: 41),
    );
  });
  test('CASE 2: 0(0),	40(0), 40(0)', () {
    // 동기화 필요: 플랫폼, 그러므로 펌프에는 요청하지 않음
    expect(
      syncPumpLog(0, 0, 40, 0, 40, 0, pageSize),
      RequestPumpLogNo(start: 0, end: 0),
    );
  });
  test('CASE 3: 40(0),	0(0), 50(0)', () {
    // 동기화 필요: 플랫폼, 앱, 하지만 전체 동기화는 아님
    expect(
      syncPumpLog(40, 0, 0, 0, 50, 0, pageSize),
      [RequestPumpLogNo(start: 40, end: 51)],
    );
  });
  test('CASE 4: 50(0),	50(0), 10(0)', () {
    // 동기화 필요: 플랫폼, 앱
    expect(
      syncPumpLog(50, 0, 50, 0, 10, 0, pageSize),
      RequestPumpLogNo(start: 0, end: 11),
    );
  });
  test('CASE 5: 9990(0),	9990(0), 5(1)', () {
    // 동기화 필요: 플랫폼, 앱
    expect(
      syncPumpLog(9990, 0, 9990, 0, 5, 1, pageSize),
      [
        RequestPumpLogNo(start: 9990, end: 9999),
        RequestPumpLogNo(start: 0, end: 6)
      ],
    );
  });

  test('CASE 6: 40(0),	0(0), 40(0)', () {
    // 동기화 필요없음
    expect(
      syncPumpLog(40, 0, 0, 0, 40, 0, pageSize),
      [RequestPumpLogNo(start: 0, end: 0)],
    );
  });*/

  test('CASE 1: 0(0),	0(0), 40(0)', () {
    // 동기화 필요: 플랫폼, 앱
    expect(
      calcRequestPumpLogNo(
        senderNo: 40,
        senderWrappingCount: 0,
        receiverNo: 0,
        receiverWrappingCount: 0,
      ),
      RequestPumpLogNo(start: 0, end: 41),
    );
  });
  test('CASE 2: 40(0),	40(0), 40(0)', () {
    expect(
      calcRequestPumpLogNo(
          senderNo: 40,
          senderWrappingCount: 0,
          receiverNo: 40,
          receiverWrappingCount: 0),
      [RequestPumpLogNo(start: 0, end: 0)],
    );
  });
  test('CASE 3: 40(0),	0(0), 50(0)', () {
    // 동기화 필요: 플랫폼, 앱, 하지만 전체 동기화는 아님
    expect(
      calcRequestPumpLogNo(
          senderNo: 50,
          senderWrappingCount: 0,
          receiverNo: 40,
          receiverWrappingCount: 0),
      [RequestPumpLogNo(start: 40, end: 51)],
    );
  });
  test('CASE 4: 50(0),	50(0), 10(0)', () {
    // 동기화 필요: 플랫폼, 앱
    expect(
      calcRequestPumpLogNo(
          senderNo: 10,
          senderWrappingCount: 0,
          receiverNo: 50,
          receiverWrappingCount: 0),
      RequestPumpLogNo(start: 0, end: 11),
    );
  });
  test('CASE 5: 9990(0),	9990(0), 5(1)', () {
    // 동기화 필요: 플랫폼, 앱
    expect(
      calcRequestPumpLogNo(
          senderNo: 5,
          senderWrappingCount: 1,
          receiverNo: 9990,
          receiverWrappingCount: 0),
      [
        RequestPumpLogNo(start: 9990, end: 9999),
        RequestPumpLogNo(start: 0, end: 6)
      ],
    );
  });

  test('CASE 6: 40(0),	0(0), 40(0)', () {
    // 동기화 필요없음
    expect(
      calcRequestPumpLogNo(
          senderNo: 40,
          senderWrappingCount: 0,
          receiverNo: 40,
          receiverWrappingCount: 0),
      [RequestPumpLogNo(start: 0, end: 0)],
    );
  });
}

class RequestPumpLogNo {
  final int start;
  final int end;

  RequestPumpLogNo({this.start, this.end});

  @override
  String toString() {
    return 'RequestPumpLogNo{start: $start, end: $end}';
  }
}

/// 플랫폼, 앱, 펌프
/// 앱 <-> 펌프 동기화
///
/// * 시작번호와 끝번호가 같을 경우(동기화가 이미 완료된 경우) -> 요청 가지 않게 하는 로직도 필요
/// * 불필요한 데이터까지 가져오지 않고 플랫폼에 물어봐서 데이터양을 최소화
/// * 페이징은 10개씩
///
/// ------ ??? ----------
/// 어디의 값을 업데이트?
/// wrappingCount가 많이 차이날 경우 처리? 값은 일단 list 여러번 찍게 함
/// ---------------------
/// <비교, 체크>
/// 플랫폼, 펌프 확인 후 같지 않으면(동기화 필요하면)
///   - 앱과 펌프를 비교하여 같으면 동기화 X, 다르면 동기화O --> return no
///
/// 1. 플랫폼, 펌프가 동기화 체크(번호가 같은지)
///   + PumpLogNo
///   + WrappingCount
/// 2. 같은 경우 -> 요청가지 않게
/// 3. 다른 경우
///   - 3.1 앱, 펌프 동기화 비교
///   - 3.2 같은 경우
///     - (확인 필요) 펌프가 초기화 됐으나 운 좋게 번호가 같은게 아닌지?
///     - 3.2.1 동기화 넘버 계산
///     - 3.2.2 플랫폼에 동기화 작업
///   - 3.3 다른 경우
///     - 3.3.1 앱, 펌프 동기화 넘버 계산
///     - 3.3.2 동기화
///
///
List<RequestPumpLogNo> syncPumpLog(
  int platformNo,
  int platformWrappingCount,
  int appNo,
  int appWrappingCount,
  int pumpNo,
  int pumpWrappingCount,
  int pageSize,
) {
  int startNo;
  int endNo;
  startNo = 0;
  endNo = 0;
  List<RequestPumpLogNo> pumploginfo;

  /// 1. 플랫폼, 펌프가 동기화 체크(번호가 같은지) -> PumpLogNo, WrappingCount
  if (platformNo == pumpNo && platformWrappingCount == pumpWrappingCount) {
//  2. 같은 경우 -> 요청가지 않게(같으므로 동기화 불필요)
//    ex.  40(0), 40(0), 40(0) 이거나 40(0), 10(0), 40(0)
    return [RequestPumpLogNo(start: 0, end: 0)];
  }

  /// 3. 다른 경우
  ///   - 3.1 앱, 펌프 동기화 비교
  if (appNo == pumpNo && appWrappingCount == pumpWrappingCount) {
    ///   - 3.2 같은 경우
    ///     ex.  0(0), 40(0), 40(0)
    ///     - (확인 필요) 펌프가 초기화 됐으나 운 좋게 번호가 같은게 아닌지?
    ///     - 3.2.1 플랫폼 동기화 넘버 계산
    ///     - 3.2.2 플랫폼에 동기화 작업
    pumploginfo = calcRequestPumpLogNo(
      receiverNo: platformNo,
      receiverWrappingCount: platformWrappingCount,
      senderNo: appNo,
      senderWrappingCount: appWrappingCount,
    );
    syncPlatform();
    return pumploginfo;
  }

  ///   - 3.3 다른 경우
  ///     - 3.3.1 앱, 플랫폼 동기화 넘버 계산
  ///     - 3.3.2 앱, 플랫폼에 동기화 작업
  pumploginfo = calcRequestPumpLogNo(
    receiverNo: appNo,
    receiverWrappingCount: appWrappingCount,
    senderNo: pumpNo,
    senderWrappingCount: pumpWrappingCount,
  );
  syncPlatform();
  syncApp();
  return pumploginfo;
}

// 데이터가 덮어씌움 됐는지는 얘를 호출하는 애가 해야됨
List<RequestPumpLogNo> calcRequestPumpLogNo({
  int receiverNo,
  int receiverWrappingCount,
  int senderNo,
  int senderWrappingCount,
}) {
  int pumpSize = 9999;
  int receiverRealNo = receiverNo + receiverWrappingCount * pumpSize;
  int senderRealNo = senderNo + senderWrappingCount * pumpSize;
  List<RequestPumpLogNo> pumpLogNos = <RequestPumpLogNo>[];
  if (receiverRealNo == senderRealNo) {
    pumpLogNos.add(RequestPumpLogNo(start: 0, end: 0));
  } else if (receiverRealNo < senderRealNo) {
    //  case: 9990(0), 5(1) / 9999(0), 56(3)
    for (int i = receiverWrappingCount; i <= senderWrappingCount; i++) {
      int startNo = (i == receiverWrappingCount ? receiverNo : 1);
      int endNo = (i == senderWrappingCount ? senderNo : pumpSize);
      pumpLogNos.add(RequestPumpLogNo(start: startNo, end: endNo));
    }
  } else if (receiverRealNo > senderRealNo) {
    //  case: 5(1), 9990(0) / 1122(3), 78(1)
    pumpLogNos.add(RequestPumpLogNo(start: 1, end: senderNo));
  }
  return pumpLogNos;
}

/* abstract */
void syncPlatform() {}
void syncApp() {}
