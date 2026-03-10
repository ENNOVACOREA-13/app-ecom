sealed class Resultado<T> {
  const Resultado();
}
class Exito<T> extends Resultado<T> {
  final T data;
  const Exito(this.data);
}
class Falla<T> extends Resultado<T> {
  final Object error;
  const Falla(this.error);
}
