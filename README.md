# Hive Repository

Hive repository to calling methods in the box as async. Wait until Hive is ready to use.

## Usage

- Wait init Hive
```dart
class CoreRepository<E> extends HiveRepository<E> {
  CoreRepository(
    String name, {
    bool? lazy,
    final HiveCipher? encryptionCipher,
    final KeyComparator? keyComparator,
    final CompactionStrategy? compactionStrategy,
    final bool? crashRecovery,
    final String? boxPath,
    final Uint8List? bytes,
  }) : super(
          name,
          lazy: lazy,
          encryptionCipher: encryptionCipher,
          keyComparator: keyComparator,
          compactionStrategy: compactionStrategy,
          crashRecovery: crashRecovery,
          boxPath: boxPath,
          bytes: bytes,
        );

  @override
  Future<BoxBase<E>> init([HiveInterface? hive]) async {
    await Hive.initFlutter();
    // TODO: Register adapter
    return await super.init(Hive);
  }
}
```

- Using with get_it
```dart
class CoreRepository<E> extends HiveRepository<E> {
  CoreRepository(
    String name, {
    bool? lazy,
  }) : super(name, lazy: lazy);

  @override
  Future<BoxBase<E>> init([HiveInterface? hive]) async {
    await getIt.allReady();
    var hive = await getIt.getAsync<HiveInterface>();
    return await super.init(Hive);
  }
}
```

- Get data
```dart
getUser() async {
  var userRepository = CoreRepository<User>('user');
  return await userRepository.get(0);
}
```
