import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateCollectionSchema(ObjectInfo object) {
  final schema = generateSchema(object);
  final propertyIds = object.objectProperties
      .mapIndexed((index, p) => "'${p.dartName}': $index")
      .join(',');
  final indexIds = object.indexes
      .mapIndexed(
          (index, i) => "'${i.properties.first.property.dartName}': $index")
      .join(',');
  final indexTypes = object.indexes
      .map((i) =>
          "'${i.properties.first.property.dartName}': [${i.properties.map((e) => e.indexTypeEnum).join(',')},]")
      .join(',');
  final linkIds = object.links
      .where((l) => !l.backlink)
      .mapIndexed((i, link) => "'${link.dartName}': $i")
      .join(',');
  final backlinkIds = object.links
      .where((l) => l.backlink)
      .sortedBy((e) => e.targetCollectionIsarName)
      .thenBy((e) => e.isarName)
      .mapIndexed((i, link) => "'${link.dartName}': $i")
      .join(',');
  final linkedCollections = object.links
      .map((e) => "'${e.targetCollectionDartName}'")
      .distinct()
      .join(',');

  return '''
    final ${object.dartName.capitalize()}Schema = CollectionSchema(
      name: '${object.dartName}',
      schema: '$schema',
      adapter: const ${object.adapterName}(),
      idName: '${object.idProperty.isarName}',
      propertyIds: {$propertyIds},
      indexIds: {$indexIds},
      indexTypes: {$indexTypes},
      linkIds: {$linkIds},
      backlinkIds: {$backlinkIds},
      linkedCollections: [$linkedCollections],
      getId: (obj) => obj.${object.idProperty.dartName},
      version: ${CollectionSchema.generatorVersion},
    );''';
}

String generateSchema(ObjectInfo object) {
  final json = {
    'name': object.isarName,
    'properties': [
      for (var property in object.objectProperties)
        {
          'name': property.isarName,
          'type': property.isarType.name,
        },
    ],
    'indexes': [
      for (var index in object.indexes)
        {
          'name': index.name,
          'unique': index.unique,
          'replace': index.replace,
          'properties': [
            for (var indexProperty in index.properties)
              {
                'name': indexProperty.property.isarName,
                'type': indexProperty.type.name,
                'caseSensitive': indexProperty.caseSensitive,
              }
          ]
        }
    ],
    'links': [
      for (var link in object.links) ...[
        if (!link.backlink)
          {
            'name': link.isarName,
            'target': link.targetCollectionIsarName,
          }
      ]
    ]
  };
  return jsonEncode(json);
}

extension on IndexType {
  String get name {
    switch (this) {
      case IndexType.value:
        return 'Value';
      case IndexType.hash:
        return 'Hash';
      case IndexType.hashElements:
        return 'HashElements';
    }
  }
}

extension on IsarType {
  String get name {
    switch (this) {
      case IsarType.Bool:
        return "Byte";
      case IsarType.Int:
        return "Int";
      case IsarType.Float:
        return "Float";
      case IsarType.Long:
      case IsarType.DateTime:
        return "Long";
      case IsarType.Double:
        return "Double";
      case IsarType.String:
        return "String";
      case IsarType.Bytes:
      case IsarType.BoolList:
        return "ByteList";
      case IsarType.IntList:
        return "IntList";
      case IsarType.FloatList:
        return "FloatList";
      case IsarType.LongList:
      case IsarType.DateTimeList:
        return "LongList";
      case IsarType.DoubleList:
        return "DoubleList";
      case IsarType.StringList:
        return "StringList";
    }
  }
}