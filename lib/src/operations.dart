library dart_orm.operations;

import 'dart:collection';

class ConditionLogic {
  static const String AND = 'AND';
  static const String OR = 'OR';
  static const String IN = 'IN';
}

class SQL {
  static String camelCaseToUnderscore(String camelCase) {
    String result = '';
    int charNumber = 0;
    bool prevCharWasUpper = false;
    for (int char in camelCase.codeUnits) {
      String c = new String.fromCharCode(char);
      bool isUpper = c == c.toUpperCase();

      if (isUpper && charNumber > 0 && !prevCharWasUpper) {
        result += '_' + c.toLowerCase();
        prevCharWasUpper = true;
      } else {
        result += c.toLowerCase();
        if (charNumber > 0 && !isUpper) {
          prevCharWasUpper = false;
        } else {
          prevCharWasUpper = true;
        }
      }
      charNumber++;
    }
    return result;
  }
}

class Condition {
  /**
   * First variable for comparation.
   */
  dynamic firstVar;

  /**
   * Second variable for comparation.
   */
  dynamic secondVar;

  /**
   * Variable comparation rule. For example: '=' or '<'.
   */
  String condition;

  /**
   * Condition logic.
   * Can be not-null obly if this condition
   * is appended to another condition and here will be append
   * logic such as 'AND' or 'OR'
   */
  String logic;

  List<Condition> conditionQueue;

  Condition(this.firstVar, this.condition, this.secondVar, [this.logic]) {
    conditionQueue = new List<Condition>();
  }

  Condition and(Condition cond) {
    cond.logic = ConditionLogic.AND;
    conditionQueue.add(cond);
    return this;
  }

  Condition or(Condition cond) {
    cond.logic = ConditionLogic.OR;
    conditionQueue.add(cond);
    return this;
  }
}

class Equals extends Condition {
  Equals(var firstVar, var secondVar, [String logic])
      : super(firstVar, '=', secondVar, logic);
}

class In extends Condition {
  In(var firstVar, var secondVar, [String logic])
      : super(firstVar, 'IN', secondVar, logic);
}

class NotIn extends Condition {
  NotIn(var firstVar, var secondVar, [String logic])
      : super(firstVar, 'NOT IN', secondVar, logic);
}

class NotEquals extends Condition {
  NotEquals(var firstVar, var secondVar, [String logic])
      : super(firstVar, '<>', secondVar, logic);
}

class LowerThan extends Condition {
  LowerThan(var firstVar, var secondVar, [String logic])
      : super(firstVar, '<', secondVar, logic);
}

class BiggerThan extends Condition {
  BiggerThan(var firstVar, var secondVar, [String logic])
      : super(firstVar, '>', secondVar, logic);
}

class Join {
  String joinType;
  String tableName;
  String tableAlias;
  Condition joinCondition;

  Join(this.joinType, this.tableName, this.tableAlias, this.joinCondition);
}

class Select extends SQL {
  final Map<String, String> sorts = new Map<String, String>();
  final List<Join> joins = new List<Join>();

  List<String> columnsToSelect;
  Table table;
  Condition condition;
  int limit;
  int offset;

  Select(this.columnsToSelect);

  void setLimit(int limit) {
    this.limit = limit;
  }

  void setOffset(int offset) {
    this.offset = offset;
  }

  void join(String joinType, String tableName, String tableAlias,
      Condition joinCondition) {
    joins.add(new Join(joinType, tableName, tableAlias, joinCondition));
  }

  void leftJoin(String tableName, String tableAlias, Condition joinCondition) {
    joins.add(new Join('LEFT', tableName, tableAlias, joinCondition));
  }

  void rightJoin(String tableName, String tableAlias, Condition joinCondition) {
    joins.add(new Join('RIGHT', tableName, tableAlias, joinCondition));
  }

  void where(Condition cond) {
    this.condition = cond;
  }

  void orderBy(fieldName, String order) {
    sorts[fieldName] = order;
  }

  String toString() {
    return 'SELECT ' + columnsToSelect.join(',') + ' FROM ' + table.tableName;
  }
}

class Update {
  Table table;

  final LinkedHashMap<String, dynamic> fieldsToUpdate =
      new LinkedHashMap<String, dynamic>();

  Update(Table this.table);

  Condition condition;

  set(String fieldName, dynamic fieldValue) {
    fieldsToUpdate[fieldName] = fieldValue;
  }

  void where(Condition cond) {
    condition = cond;
  }
}

class Delete {
  Table table;

  Delete(Table this.table);

  Condition condition;

  void where(Condition cond) {
    condition = cond;
  }
}

class Insert {
  Table table;
  final LinkedHashMap<String, dynamic> _fieldsToInsert =
      new LinkedHashMap<String, dynamic>();

  Insert(Table this.table);

  LinkedHashMap<String, dynamic> get fieldsToInsert => _fieldsToInsert;

  void value(String fieldName, dynamic fieldValue) {
    _fieldsToInsert[fieldName] = fieldValue;
  }
}

/**
 * Represents database field.
 */
class Field {
  bool isPrimaryKey = false;
  bool isUnique = false;

  /**
   * Raw database type string. For example: TIMESTAMP
   */
  String type;

  /**
   * Database column name.
   */
  String fieldName;

  /**
   * Model property name.
   */
  String propertyName;

  /**
   * Name of the Dart type this field is attached to.
   */
  String propertyTypeName;

  dynamic defaultValue;
  Symbol constructedFromPropertyName;

  Field() {}

  Field.fromJson(Map fieldJson) {
    isPrimaryKey = fieldJson["primaryKey"];
    isUnique = fieldJson["isUnique"];
    type = fieldJson["type"];
    fieldName = fieldJson["fieldName"];
    propertyName = fieldJson["propertyName"];
    propertyTypeName = fieldJson["propertyTypeName"];
    defaultValue = fieldJson["defaultValue"];
  }

  Map toJson() {
    return {
      "isPrimaryKey": isPrimaryKey,
      "isUnique": isUnique,
      "type": type,
      "fieldName": fieldName,
      "propertyName": propertyName,
      "propertyTypeName": propertyTypeName,
      "defaultValue": defaultValue
    };
  }
}

class Table {
  /**
   * Model class name.
   */
  String _className;

  /**
   * Database table name. Converted from _className to underscore notation.
   */
  String tableName;

  List<Field> fields = new List<Field>();

  String get className => _className;

  void set className(String className) {
    _className = className;
    tableName = SQL.camelCaseToUnderscore(className);
  }

  Field getPrimaryKeyField() {
    for (Field f in fields) {
      if (f.isPrimaryKey) {
        return f;
      }
    }
    return null;
  }

  Table() {}

  Table.fromJson(Map tableJson) {
    _className = tableJson["_className"];
    tableName = tableJson["tableName"];
    fields = new List.from(tableJson["fields"]
        .map((Map fieldJson) => new Field.fromJson(fieldJson)));
  }

  Map toJson() {
    return {
      "className": _className,
      "tableName": tableName,
      "fields": new List.from(fields.map((Field f) => f.toJson()))
    };
  }
}

/// Base alter table class.
class AlterTable {
  Table table;

  AlterTable(this.table);
}

/// Represents add new table database operation.
/// Instances of this class are created by [Migrator] when it detects
/// that new table should be added to database.
class CreateTable extends AlterTable {
  CreateTable(Table table) : super(table);
}

/// Represents drop table database opetaion.
/// Instances of this class are created by [Migrator] when it detects
/// that a table should be dropped from database.
class DropTable extends AlterTable {
  DropTable(Table table) : super(table);
}

/// Represents create field database operation.
/// Instances of this class are created by [Migrator] when it detects
/// that new Field should be added to database.
class CreateField extends AlterTable {
  /// Field to create
  Field field;

  CreateField(Table table, Field this.field) : super(table);
}

/// Represents drop field database operation.
/// Instances of this class are created by [Migrator] when it detects
/// that a Field should be dropped from database.
class DropField extends AlterTable {
  /// Field to drop.
  Field field;

  DropField(Table table, Field this.field) : super(table);
}

/// Represents alter field database operation.
/// Instances of this class are created by [Migrator] when it detects
/// that a Field should be altered on database.
class AlterField extends AlterTable {
  Field oldField;
  Field newField;

  AlterField(Table table, Field this.oldField, Field this.newField)
      : super(table);
}
