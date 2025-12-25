import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/failure.dart';
import '../../../../core/type_defs.dart';

final layoutRepositoryProvider = Provider((ref) => LayoutRepository());

class LayoutRepository {
  // Mock function: Server se Pending Requests ka count lana
  FutureEither<int> getPendingRequestsCount() async {
    try {
      // Fake delay to simulate network
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(12); // Assume 12 pending requests
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
