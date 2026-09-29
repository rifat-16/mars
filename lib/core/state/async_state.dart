enum AsyncStatus { idle, loading, success, error }

class AsyncState<T> {
  final AsyncStatus status;
  final T? data;
  final String? errorMessage;

  const AsyncState._({required this.status, this.data, this.errorMessage});

  const AsyncState.idle() : this._(status: AsyncStatus.idle);
  const AsyncState.loading() : this._(status: AsyncStatus.loading);
  const AsyncState.success(T data)
    : this._(status: AsyncStatus.success, data: data);
  const AsyncState.error(String message)
    : this._(status: AsyncStatus.error, errorMessage: message);

  bool get isIdle => status == AsyncStatus.idle;
  bool get isLoading => status == AsyncStatus.loading;
  bool get isSuccess => status == AsyncStatus.success;
  bool get isError => status == AsyncStatus.error;
}
