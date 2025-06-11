class Complaint {
  final int id;
  final String userName;
  final String phoneNumber;
  final String date;
  final String status;
  final String details;
  final String? response;
  final String? respondedAt;

  Complaint({
    required this.id,
    required this.userName,
    required this.phoneNumber,
    required this.date,
    required this.status,
    required this.details,
    this.response,
    this.respondedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    DateTime problemDate = DateTime.parse(json['ProblemDate']);
    String formattedDate = "${problemDate.day}/${problemDate.month}/${problemDate.year}";

    String? formattedRespondedAt;
    if (json['ResponseDate'] != null) {
      DateTime respondedAt = DateTime.parse(json['ResponseDate']);
      formattedRespondedAt = "${respondedAt.day}/${respondedAt.month}/${respondedAt.year} ${respondedAt.hour}:${respondedAt.minute}";
    }

    print("Status from API: ${json['Status']}");
    print("ProblemStatus from API: ${json['ProblemStatus']}");
    print("PhoneNumber from API: ${json['PhoneNumber']}");


    String status;
    if (json.containsKey('Status')) {
      status = json['Status'] ?? "Unknown";
    } else if (json.containsKey('ProblemStatus')) {
      status = _mapProblemStatus(json['ProblemStatus']);
    } else {
      status = "Unknown";
    }

    return Complaint(
      id: json['ComplaintId'],
      userName: json['Complainer']?.isEmpty ?? true ? "Not Provided" : json['Complainer'],
      phoneNumber: json['PhoneNumber']?.isEmpty ?? true ? "Not Provided" : json['PhoneNumber'],
      date: formattedDate,
      status: status,
      details: json['Problem']?.isEmpty ?? true ? "No details provided" : json['Problem'],
      response: json['Response'],
      respondedAt: formattedRespondedAt,
    );
  }

  static String _mapProblemStatus(int? status) {
    switch (status) {
      case 0:
        return "New";
      case 1:
        return "In Progress";
      case 2:
        return "Resolved";
      default:
        return "Unknown";
    }
  }
}