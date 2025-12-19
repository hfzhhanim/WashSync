class UserReport {
  final String id;
  final String userName;
  final String machineId;
  final String issueDescription;
  final DateTime date;

  UserReport({
    required this.id,
    required this.userName,
    required this.machineId,
    required this.issueDescription,
    required this.date,
  });
}