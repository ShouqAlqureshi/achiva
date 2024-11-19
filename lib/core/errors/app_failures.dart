import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServerFailure extends Failure {}

class InternetNotFoundFailure extends Failure {}

class InvalidDataEnteredByUserFailure extends Failure {}

class AccessTokenOfUserExpiredFailure extends Failure {}

class DoNotHavePermissionToAccessItemThisFailure extends Failure {}

