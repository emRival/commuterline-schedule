class CommuterSchedule {
  List<Data>? data;

  CommuterSchedule({this.data});

  CommuterSchedule.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? id;
  String? stationId;
  String? stationOriginId;
  String? stationDestinationId;
  String? trainId;
  String? line;
  String? route;
  String? departsAt;
  String? arrivesAt;
  Metadata? metadata;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
      this.stationId,
      this.stationOriginId,
      this.stationDestinationId,
      this.trainId,
      this.line,
      this.route,
      this.departsAt,
      this.arrivesAt,
      this.metadata,
      this.createdAt,
      this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    stationId = json['station_id'];
    stationOriginId = json['station_origin_id'];
    stationDestinationId = json['station_destination_id'];
    trainId = json['train_id'];
    line = json['line'];
    route = json['route'];
    departsAt = json['departs_at'];
    arrivesAt = json['arrives_at'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['station_id'] = this.stationId;
    data['station_origin_id'] = this.stationOriginId;
    data['station_destination_id'] = this.stationDestinationId;
    data['train_id'] = this.trainId;
    data['line'] = this.line;
    data['route'] = this.route;
    data['departs_at'] = this.departsAt;
    data['arrives_at'] = this.arrivesAt;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Metadata {
  Origin? origin;

  Metadata({this.origin});

  Metadata.fromJson(Map<String, dynamic> json) {
    origin =
        json['origin'] != null ? new Origin.fromJson(json['origin']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.origin != null) {
      data['origin'] = this.origin!.toJson();
    }
    return data;
  }
}

class Origin {
  String? color;

  Origin({this.color});

  Origin.fromJson(Map<String, dynamic> json) {
    color = json['color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['color'] = this.color;
    return data;
  }
}
