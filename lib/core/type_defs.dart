import 'package:fpdart/fpdart.dart';
import 'failure.dart';

// FutureEither ka matlab: Future men ya to Failure milega ya Success (T)
typedef FutureEither<T> = Future<Either<Failure, T>>;

// Agar kuch return nahi karna (jese signout), to FutureVoid use karenge
typedef FutureVoid = FutureEither<void>;
