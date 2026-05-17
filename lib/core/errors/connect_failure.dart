sealed class ConnectFailure {
  const ConnectFailure(this.message);
  final String message;
}

final class DiscoveryFailure extends ConnectFailure {
  const DiscoveryFailure(super.message);
}

final class ConnectionFailure extends ConnectFailure {
  const ConnectionFailure(super.message);
}

final class CommandFailure extends ConnectFailure {
  const CommandFailure(super.message);
}

final class UnknownFailure extends ConnectFailure {
  const UnknownFailure(super.message);
}
