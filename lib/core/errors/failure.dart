/// خطأ مفهوم للمستخدم بدل رسائل الـ Exceptions التقنية.
class Failure {
  final String message;
  const Failure(this.message);

  static const network = Failure('لا يوجد اتصال بالإنترنت، حاولي مرة أخرى.');
  static const unknown = Failure('حدث خطأ غير متوقع.');
}

/// الحساب موجود بس لسا ما تأكد، وبعتنا (أو لازم نبعت) رابط تأكيد على الإيميل.
class ConfirmEmailFailure extends Failure {
  final String email;
  const ConfirmEmailFailure(this.email) : super('لازم تأكدي إيميلك أول 📩');
}
