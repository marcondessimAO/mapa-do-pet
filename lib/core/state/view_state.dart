import '../error/failure.dart';

/// Estado de carregamento de uma tela. Um `switch` exaustivo sobre ele garante
/// que nenhum estado fique sem tratamento na interface.
sealed class ViewState<T> {
  const ViewState();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Empty<T> extends ViewState<T> {
  const Empty();
}

final class Loaded<T> extends ViewState<T> {
  const Loaded(this.data);

  final T data;
}

final class Failed<T> extends ViewState<T> {
  const Failed(this.failure);

  final Failure failure;
}
