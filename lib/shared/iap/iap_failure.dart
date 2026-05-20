sealed class IapFailure {
  const IapFailure(this.message);
  final String message;
}

final class IapUserCancelled extends IapFailure {
  const IapUserCancelled() : super('User cancelled the purchase.');
}

final class IapProductNotFound extends IapFailure {
  const IapProductNotFound() : super('Product not available on this store.');
}

final class IapNetworkFailure extends IapFailure {
  const IapNetworkFailure() : super('Network error contacting the store.');
}

final class IapNothingToRestore extends IapFailure {
  const IapNothingToRestore() : super('No previous purchases found.');
}

final class IapUnknownFailure extends IapFailure {
  const IapUnknownFailure(super.message);
}
