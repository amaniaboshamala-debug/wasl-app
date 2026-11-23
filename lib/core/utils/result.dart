import 'package:wasl/core/errors/failure.dart';

/// نتيجة أي عملية: يا نجاح فيه بيانات، يا فشل فيه Failure.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
