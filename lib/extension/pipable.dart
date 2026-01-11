extension PipeExtension<T> on T {
  R pipe<R>(R Function(T) f) => f(this);

  (R, S) fork<R, S>(R Function(T) f, S Function(T) g) => (f(this), g(this));

  T tap(void Function(T) f) {
    f(this);
    return this;
  }

  T check(({bool expect, String message}) Function(T) convert) {
    final result = convert(this);
    if (!result.expect) {
      throw Exception(result.message);
    }
    return this;
  }
}
