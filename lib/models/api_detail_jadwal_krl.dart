class DetailJadwalKrl {
  int? status;
  List<DataDetailJadwalKrl>? data;

  DetailJadwalKrl({this.status, this.data});

  DetailJadwalKrl.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <DataDetailJadwalKrl>[];
      json['data'].forEach((v) {
        data!.add(new DataDetailJadwalKrl.fromJson(v));
      });
    }
  }
}

class DataDetailJadwalKrl {
  String? trainId;
  String? kaName;
  String? stationId;
  String? stationName;
  String? timeEst;
  bool? transitStation;
  String? color;
  List<String>? transit;

  DataDetailJadwalKrl({
    this.trainId,
    this.kaName,
    this.stationId,
    this.stationName,
    this.timeEst,
    this.transitStation,
    this.color,
    this.transit,
  });

  DataDetailJadwalKrl.fromJson(Map<String, dynamic> json) {
    trainId = json['train_id'];
    kaName = json['ka_name'];
    stationId = json['station_id'];
    stationName = json['station_name'];
    timeEst = json['time_est'];
    transitStation = json['transit_station'];
    color = json['color'];

    if (json['transit'] != null) {
      if (json['transit'] is List) {
        transit = List<String>.from(json['transit']);
      } else if (json['transit'] is String) {
        transit = [json['transit']];
      }
    } else {
      transit = null;
    }
  }
}
