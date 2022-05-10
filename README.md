# Hive Wait

Hive Wait provide a Hive repository to calling methods in the box as async.

Wait until the Hive is ready to use before calling the box's methods.

## Usage

- Wait init Hive
```dart
class CoreRepository<E> extends HiveRepository<E> {
  CoreRepository(
    String name, {
    bool? lazy,
    HiveCipher? encryptionCipher,
    KeyComparator? keyComparator,
    CompactionStrategy? compactionStrategy,
    bool? crashRecovery,
    String? boxPath,
    Uint8List? bytes,
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
    hive = await getIt.getAsync<HiveInterface>();
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
