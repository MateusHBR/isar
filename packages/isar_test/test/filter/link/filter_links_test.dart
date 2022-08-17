import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../../util/common.dart';
import '../../util/sync_async_helper.dart';

part 'filter_links_test.g.dart';

@Collection()
class SourceModel {
  Id id = Isar.autoIncrement;

  final links = IsarLinks<TargetModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  String toString() {
    return 'SourceModel{id: $id, links: $links}';
  }
}

@Collection()
class TargetModel {
  TargetModel(this.name);

  Id id = Isar.autoIncrement;

  String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'TargetModel{id: $id, name: $name}';
  }
}

void main() {
  group('Filter links', () {
    late Isar isar;

    late SourceModel source1;
    late SourceModel source2;
    late SourceModel source3;
    late SourceModel source4;
    late SourceModel source5;
    late SourceModel source6;

    late TargetModel target1;
    late TargetModel target2;
    late TargetModel target3;
    late TargetModel target4;
    late TargetModel target5;
    late TargetModel target6;

    setUp(() async {
      isar = await openTempIsar([SourceModelSchema, TargetModelSchema]);

      source1 = SourceModel();
      source2 = SourceModel();
      source3 = SourceModel();
      source4 = SourceModel();
      source5 = SourceModel();
      source6 = SourceModel();

      target1 = TargetModel('target 1');
      target2 = TargetModel('target 2');
      target3 = TargetModel('target 3');
      target4 = TargetModel('target 4');
      target5 = TargetModel('target 5');
      target6 = TargetModel('target 6');

      await isar.tWriteTxn(
        () => Future.wait([
          isar.sourceModels.tPutAll([
            source1,
            source2,
            source3,
            source4,
            source5,
            source6,
          ]),
          isar.targetModels.tPutAll([
            target1,
            target2,
            target3,
            target4,
            target5,
            target6,
          ]),
        ]),
      );

      source1.links.add(target1);
      source2.links.addAll([target1, target2, target3]);
      source3.links.add(target2);
      source4.links.addAll([target4, target2]);

      await isar.tWriteTxn(
        () => Future.wait([
          source1.links.tSave(),
          source2.links.tSave(),
          source3.links.tSave(),
          source4.links.tSave(),
        ]),
      );
    });

    isarTest('.links()', () async {
      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameStartsWith('target'))
            .tFindAll(),
        [source1, source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameEqualTo('target 1'))
            .tFindAll(),
        [source1, source2],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameEqualTo('target 2'))
            .tFindAll(),
        [source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameEqualTo('target 3'))
            .tFindAll(),
        [source2],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameEqualTo('target 4'))
            .tFindAll(),
        [source4],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameEqualTo('target 5'))
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameEqualTo('target 6'))
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links((q) => q.nameEqualTo('non existing'))
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links(
              (q) => q.nameEqualTo('target 1').or().nameEqualTo('target 2'),
            )
            .and()
            .links((q) => q.nameEqualTo('target 1'))
            .tFindAll(),
        [source1, source2],
      );
    });

    isarTest('.linksLengthEqualTo()', () async {
      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(-1).tFindAll(),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(0).tFindAll(),
        [source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(1).tFindAll(),
        [source1, source3],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(2).tFindAll(),
        [source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(3).tFindAll(),
        [source2],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(4).tFindAll(),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(5).tFindAll(),
        [],
      );
    });

    isarTest('.linksLengthGreaterThan()', () async {
      // FIXME: .linksLengthGreaterThan(X) where X <= -2 returns no values
      // await qEqualSet(
      //   isar.sourceModels.filter().linksLengthGreaterThan(-2).tFindAll(),
      //   [source1, source2, source3, source4, source5, source6],
      // );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(-1).tFindAll(),
        [source1, source2, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(0).tFindAll(),
        [source1, source2, source3, source4],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthGreaterThan(0, include: true)
            .tFindAll(),
        [source1, source2, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(1).tFindAll(),
        [source2, source4],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthGreaterThan(1, include: true)
            .tFindAll(),
        [source1, source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(2).tFindAll(),
        [source2],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthGreaterThan(2, include: true)
            .tFindAll(),
        [source2, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(3).tFindAll(),
        [],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthGreaterThan(3, include: true)
            .tFindAll(),
        [source2],
      );

      // FIXME: (minor) .linksLengthGreaterThan(X) where X == max i64 returns
      // all values
      // await qEqualSet(
      //   isar.sourceModels
      //       .filter()
      //       .linksLengthGreaterThan(9223372036854775807)
      //       .tFindAll(),
      //   [],
      // );
    });

    isarTest('.linksLengthLessThan()', () async {
      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(0).tFindAll(),
        [],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthLessThan(0, include: true)
            .tFindAll(),
        [source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(1).tFindAll(),
        [source5, source6],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthLessThan(1, include: true)
            .tFindAll(),
        [source1, source3, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(2).tFindAll(),
        [source1, source3, source5, source6],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthLessThan(2, include: true)
            .tFindAll(),
        [source1, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(3).tFindAll(),
        [source1, source3, source4, source5, source6],
      );
      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthLessThan(3, include: true)
            .tFindAll(),
        [source1, source2, source3, source4, source5, source6],
      );

      // FIXME: .linksLengthLessThan(X) where X < 0 returns all values
      // await qEqualSet(
      //   isar.sourceModels.filter().linksLengthLessThan(-1).tFindAll(),
      //   [],
      // );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthLessThan(9223372036854775807)
            .tFindAll(),
        [source1, source2, source3, source4, source5, source6],
      );
    });

    isarTest('.linksLengthBetween()', () async {
      await qEqualSet(
        isar.sourceModels.filter().linksLengthBetween(0, 3).tFindAll(),
        [source1, source2, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthBetween(0, 3, includeLower: false)
            .tFindAll(),
        [source1, source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthBetween(0, 3, includeUpper: false)
            .tFindAll(),
        [source1, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthBetween(0, 3, includeLower: false, includeUpper: false)
            .tFindAll(),
        [source1, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthBetween(1, 2).tFindAll(),
        [source1, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthBetween(3, 42).tFindAll(),
        [source2],
      );
    });

    isarTest('.linksIsEmpty', () async {
      await qEqualSet(
        isar.sourceModels.filter().linksIsEmpty().tFindAll(),
        [source5, source6],
      );

      await isar.tWriteTxn(() => source1.links.tReset());

      await qEqualSet(
        isar.sourceModels.filter().linksIsEmpty().tFindAll(),
        [source1, source5, source6],
      );

      await isar.tWriteTxn(() => isar.targetModels.where().tDeleteAll());

      await qEqualSet(
        isar.sourceModels.filter().linksIsEmpty().tFindAll(),
        [source1, source2, source3, source4, source5, source6],
      );
    });

    isarTest('.linksIsNotEmpty()', () async {
      await qEqualSet(
        isar.sourceModels.filter().linksIsNotEmpty().tFindAll(),
        [source1, source2, source3, source4],
      );

      await isar.tWriteTxn(() => source1.links.tReset());

      await qEqualSet(
        isar.sourceModels.filter().linksIsNotEmpty().tFindAll(),
        [source2, source3, source4],
      );

      await isar.tWriteTxn(() => isar.targetModels.where().tDeleteAll());

      await qEqualSet(
        isar.sourceModels.filter().linksIsNotEmpty().tFindAll(),
        [],
      );
    });
  });
}