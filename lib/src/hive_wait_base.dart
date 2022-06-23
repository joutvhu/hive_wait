// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:hive/src/util/indexable_skip_list.dart';
import 'package:meta/meta.dart';

class HiveRepository<E> {
  final String name;
  final bool lazy;
  final HiveCipher? encryptionCipher;
  final KeyComparator keyComparator;
  final CompactionStrategy compactionStrategy;
  final bool crashRecovery;
  final String? boxPath;
  final Uint8List? bytes;

  late HiveInterface hive;
  late Future<BoxBase<E>> _ready;
  late BoxBase<E> box;

  HiveRepository(
    this.name, {
    bool? lazy,
    this.encryptionCipher,
    KeyComparator? keyComparator,
    CompactionStrategy? compactionStrategy,
    bool? crashRecovery,
    this.boxPath,
    this.bytes,
  })  : lazy = lazy ?? true,
        keyComparator = keyComparator ?? defaultKeyComparator,
        compactionStrategy = compactionStrategy ?? defaultCompactionStrategy,
        crashRecovery = crashRecovery ?? true {
    _ready = init();
  }

  @mustCallSuper
  Future<BoxBase<E>> init([HiveInterface? hive]) async {
    this.hive = hive ?? Hive;
    return await _init();
  }

  Future<BoxBase<E>> _init() async {
    if (lazy) {
      box = await hive.openLazyBox<E>(
        name,
        encryptionCipher: encryptionCipher,
        keyComparator: keyComparator,
        compactionStrategy: compactionStrategy,
        crashRecovery: crashRecovery,
        path: boxPath,
      );
    } else {
      box = await hive.openBox<E>(
        name,
        encryptionCipher: encryptionCipher,
        keyComparator: keyComparator,
        compactionStrategy: compactionStrategy,
        crashRecovery: crashRecovery,
        path: boxPath,
        bytes: bytes,
      );
    }
    return box;
  }

  BoxBaseImpl<E>? get _baseBox {
    return box is BoxBaseImpl<E> ? box as BoxBaseImpl<E> : null;
  }

  BoxBaseImpl<E>? get _baseBoxOpened {
    BoxBaseImpl<E>? baseBox = _baseBox;
    if (baseBox != null) {
      baseBox.checkOpen();
      return baseBox;
    }
    return null;
  }

  IndexableSkipList<dynamic, Frame>? get _store {
    return (_baseBoxOpened?.keystore as dynamic)?._store;
  }

  @mustCallSuper
  Future<void> reopen() async {
    await _ready;
    _ready = _init();
  }

  Future<bool> get isOpen async {
    await _ready;
    return box.isOpen;
  }

  Future<String?> get path async {
    await _ready;
    return box.path;
  }

  Future<Iterable<dynamic>> get keys async {
    await _ready;
    return box.keys;
  }

  Future<int> get length async {
    await _ready;
    return box.length;
  }

  Future<bool> get isEmpty async {
    await _ready;
    return box.isEmpty;
  }

  Future<bool> get isNotEmpty async {
    await _ready;
    return box.isNotEmpty;
  }

  Future<Iterable<E>?> get values async {
    await _ready;
    if (box is Box<E>) return (box as Box<E>).values;
    Iterable<Frame> frames = _baseBoxOpened?.keystore.frames ?? [];
    return await Future.wait(frames.map(_getByFrame));
  }

  Future<E> _getByFrame(Frame frame) async {
    var value = await _baseBoxOpened?.backend.readValue(frame);
    if (value is HiveObjectMixin) {
      value.init(frame.key, box);
    }
    return value as E;
  }

  Future<Iterable<E>?> valuesBetween({dynamic startKey, dynamic endKey}) async {
    await _ready;
    if (box is Box<E>) return (box as Box<E>).valuesBetween(startKey: startKey, endKey: endKey);
    return await Future.wait(_getFrameBetween(startKey, endKey).map(_getByFrame));
  }

  Iterable<Frame> _getFrameBetween([dynamic startKey, dynamic endKey]) sync* {
    Iterable<Frame>? iterable;
    if (startKey != null) {
      iterable = _store?.valuesFromKey(startKey);
    } else {
      iterable = _baseBoxOpened?.keystore.frames;
    }

    if (iterable != null) {
      for (var frame in iterable) {
        yield frame;
        if (frame.key == endKey) break;
      }
    }
  }

  Future<E?> get(dynamic key, {E? defaultValue}) async {
    await _ready;
    if (box is Box<E>) return (box as Box<E>).get(key, defaultValue: defaultValue);
    if (box is LazyBox<E>) return (box as LazyBox<E>).get(key, defaultValue: defaultValue);
    return null;
  }

  Future<E?> getAt(int index) async {
    await _ready;
    if (box is Box<E>) return (box as Box<E>).getAt(index);
    if (box is LazyBox<E>) return (box as LazyBox<E>).getAt(index);
    return null;
  }

  Stream<BoxEvent> watch({dynamic key}) async* {
    await _ready;
    yield* box.watch(key: key);
  }

  Future<bool> containsKey(dynamic key) async {
    await _ready;
    return box.containsKey(key);
  }

  Future<void> put(dynamic key, E value) async {
    await _ready;
    return await box.put(key, value);
  }

  Future<void> putAt(int index, E value) async {
    await _ready;
    return await box.putAt(index, value);
  }

  Future<void> putAll(Map<dynamic, E> entries) async {
    await _ready;
    return await box.putAll(entries);
  }

  Future<int> add(E value) async {
    await _ready;
    return await box.add(value);
  }

  Future<Iterable<int>> addAll(Iterable<E> values) async {
    await _ready;
    return await box.addAll(values);
  }

  Future<void> delete(dynamic key) async {
    await _ready;
    return await box.delete(key);
  }

  Future<void> deleteAt(int index) async {
    await _ready;
    return await box.deleteAt(index);
  }

  Future<void> deleteAll(Iterable<dynamic> keys) async {
    await _ready;
    return await box.deleteAll(keys);
  }

  Future<void> compact() async {
    await _ready;
    return await box.compact();
  }

  Future<int> clear() async {
    await _ready;
    return await box.clear();
  }

  Future<void> deleteFromDisk() async {
    await _ready;
    return await box.deleteFromDisk();
  }

  Future<void> flush() async {
    await _ready;
    return await box.flush();
  }

  Future<Map<dynamic, E>?> toMap() async {
    await _ready;
    if (box is Box<E>) return (box as Box<E>).toMap();

    BoxBaseImpl<E>? baseBox = _baseBox;
    if (baseBox != null) {
      Map<dynamic, E> map = <dynamic, E>{};
      for (var frame in baseBox.keystore.frames) {
        map[frame.key] = await _getByFrame(frame);
      }
      return map;
    }
    return null;
  }

  @mustCallSuper
  Future<void> close() async {
    await _ready;
    box.close();
  }

  @mustCallSuper
  FutureOr<void> destroy() {
    return _ready.then((value) => box.close());
  }
}
