class JadwalKrl {
  int? status;
  List<DataJadwalKrl>? data;

  JadwalKrl({this.status, this.data});

  JadwalKrl.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <DataJadwalKrl>[];
      json['data'].forEach((v) {
        data!.add(new DataJadwalKrl.fromJson(v));
      });
    }
  }

}

class DataJadwalKrl {
  String? trainId;
  String? kaName;
  String? routeName;
  String? dest;
  String? timeEst;
  String? color;
  String? destTime;

  DataJadwalKrl(
      {this.trainId,
      this.kaName,
      this.routeName,
      this.dest,
      this.timeEst,
      this.color,
      this.destTime});

  DataJadwalKrl.fromJson(Map<String, dynamic> json) {
    trainId = json['train_id'];
    kaName = json['ka_name'];
    routeName = json['route_name'];
    dest = json['dest'];
    timeEst = json['time_est'];
    color = json['color'];
    destTime = json['dest_time'];
  }
}
