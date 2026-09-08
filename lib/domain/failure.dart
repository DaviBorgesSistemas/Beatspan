/// Representa uma falha de domínio retornada via `Either<Failure, T>`.
///
/// `code` segue convenção por contexto de uso (ex.: 404 para "não
/// encontrado" em buscas por código, 0 para erro genérico/conexão) —
/// ver os repositórios concretos para o significado exato em cada caso.
class Failure {
  int code;
  String message; // error or success

  Failure(this.code, this.message);
}
