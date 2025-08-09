import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/services/school_service.dart';
import 'package:finimoi/domain/entities/school_models.dart';

final schoolServiceProvider = Provider<SchoolService>((ref) {
  return SchoolService();
});

final myStudentsProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(schoolServiceProvider).getMyStudents();
});

final studentFeesProvider = StreamProvider.family<List<Fee>, String>((ref, studentId) {
  return ref.watch(schoolServiceProvider).getFeesForStudent(studentId);
});
