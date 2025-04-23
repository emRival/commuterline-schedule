class ApiStationName {
  List<Data>? data;

  ApiStationName({this.data});

  ApiStationName.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? uid;
  String? id;
  String? name;
  String? type;
  Metadata? metadata;
  String? createdAt;
  String? updatedAt;

  Data({
    this.uid,
    this.id,
    this.name,
    this.type,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  Data.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    id = json['id'];
    name = json['name'];
    type = json['type'];
    metadata =
        json['metadata'] != null
            ? new Metadata.fromJson(json['metadata'])
            : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uid'] = this.uid;
    data['id'] = this.id;
    data['name'] = this.name;
    data['type'] = this.type;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }

  // Tambahkan ini:
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Data && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Metadata {
  bool? active;
  Origin? origin;

  Metadata({this.active, this.origin});

  Metadata.fromJson(Map<String, dynamic> json) {
    active = json['active'];
    origin =
        json['origin'] != null ? new Origin.fromJson(json['origin']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['active'] = this.active;
    if (this.origin != null) {
      data['origin'] = this.origin!.toJson();
    }
    return data;
  }
}

class Origin {
  int? daop;
  int? fgEnable;

  Origin({this.daop, this.fgEnable});

  Origin.fromJson(Map<String, dynamic> json) {
    daop = json['daop'];
    fgEnable = json['fg_enable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['daop'] = this.daop;
    data['fg_enable'] = this.fgEnable;
    return data;
  }
}
