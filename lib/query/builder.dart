class Builder {
  List<String> _select = [];

  String _table;

  List<String> _wheres = [];

  /// This represents the boolean of the where clause.
  /// So [_whereBooleans.elementAt(0)] is the boolean of
  /// _where.elementAt(0).
  ///
  /// A where boolean is "AND" or "OR".
  List<String> _whereBooleans = [];

  List<String> _group = [];

  String _order;

  String _limit;

  Verb _verb;

  /// All of the available clause operators.
  final _operators = [
    '=', '<', '>', '<=', '>=', '<>', '!=', /*'<=>'*/
    'like', /*'like binary'*/ 'not like', /*'ilike'*/ 'in',
    'is', 'is not'
    /*'&', '|', '^', '<<', '>>',
    'rlike', 'not rlike', 'regexp', 'not regexp',
    '~', '~*', '!~', '!~*', 'similar to',
    'not similar to', 'not ilike', '~~*', '!~~*'*/
  ];

  Builder();

  Builder table(String table) {
    _table = table;
    return this;
  }

  Builder select(List<String> fields) {
    _verb = Verb.select;
    _select = fields;
    return this;
  }

  List<Map<String, dynamic>> get() {
    // Todo return th same thing as execute but for selection only
  }

  Map<String, dynamic> first() {
    // Todo: select with limit applied
  }

  Map<String, dynamic> last() {
    // Todo: select the last entry of that respect the conditions
  }

  /// Add a basic where clause to the query.
  /// Do not use this to check nullability, instead use [whereNull] and [whereNotNull].
  Builder where(String column, dynamic operator, [dynamic value, String boolean = 'AND']) {
    assert(value is String || value is num || value == null || value is bool);

    // Here we will make some assumptions about the operator. If only 2 values are
    // passed to the method, we will assume that the operator is an equals sign
    // and keep going. Otherwise, we'll require the operator to be passed in.
    assert(
        (value != null || _operators.contains(operator)) ||
            (value == null && !_operators.contains(operator)),
        'Ambiguous operator-value pair. If the value is null the only '
        'valid values for the operator are: $_operators');

    boolean = boolean.toUpperCase();
    assert(boolean == 'AND' || boolean == 'OR');

    // The first WHERE is always considered as an "AND" condition.
    if (_wheres.isEmpty) boolean = 'AND';
    if (operator == '<>') operator = '!=';

    if (value == null && !_operators.contains(operator)) {
      value = operator;
      operator = '=';
    }

    // If the value is "null", we will just assume the developer wants to add a
    // where null clause to the query. So, we will allow a short-cut here to
    // that method for convenience so the developer doesn't have to check.
    if (value == null) {
      return whereNull(column, boolean, operator != '=');
    }

    /*if (value == null) {
      //if (operator != '=' && operator != '!=') operator = '=';
      // When the operator is not defined, we assume that it is equal.
      if (operator == '=') {
        operator = 'is';
      } else if (operator == '!=') {
        operator = 'is not';
      }
    }*/

    _wheres.add("$column $operator ${_parseConditionValue(value)}");
    _whereBooleans.add(boolean);

    // Multi columns
    // [column].forEach((column_) {
        // _where.add("$column_$operator'$value'");
    // });

    return this;
  }

  Builder orWhere(String column, dynamic operator, [dynamic value]) {
    return where(column, operator, value, 'OR');
  }

  /// Add a "where null" clause to the query.
  Builder whereNull(String column, [String boolean = 'AND', bool notNull = false]) {
    boolean = boolean.toUpperCase();
    assert(boolean == 'AND' || boolean == 'OR');

    _wheres.add("$column is${notNull ? ' not' : ''} NULL");
    _whereBooleans.add(boolean);
    return this;
  }

  String toRawSql() {
    assert(_table != null);

    List<String> parts = [];

    parts = _makeSelect();

    return parts.join(' ');
  }

  List<String> _makeSelect() {
    List<String> parts = ['SELECT'];
    if (_select.isNotEmpty) {
      parts.add(_select.join(', '));
    } else {
      parts.add('*');
    }

    parts.addAll(['FROM', _table]);

    if (_wheres.isNotEmpty) {
      String completeCondition = '';
      bool whereBooleansContainOr = _whereBooleans.contains('OR');
      _wheres.asMap().forEach((index, condition) {
        int lastIndex = _wheres.length - 1;
        String boolean = _whereBooleans[index];
        String nextBoolean = index + 1 <= lastIndex ? _whereBooleans[index + 1] : null;

        if (boolean == 'AND') {
          if (whereBooleansContainOr) completeCondition += '(';
        } else /*if (boolean == 'OR')*/ {
          completeCondition += ' OR ';
        }

        completeCondition += condition;

        if (nextBoolean == 'AND' || index == lastIndex) {
          if (whereBooleansContainOr) completeCondition += ')';
          if (index < _wheres.length - 1) {
            completeCondition += ' AND ';
          }
        }
      });
      parts.addAll(['WHERE', completeCondition]);
    }

    return parts;
  }

  void _assertStringOrNum(dynamic value) {
    assert(value is String || value is num);
  }


  /// Sometimes where conditions contains spaces.
  /// We wrap non-numeral values into single-quotes.
  String _parseConditionValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is bool) return value ? '1' : '0';
    return num.tryParse(value.toString())?.toString() ?? "'$value'";
  }

  bool isWhereBooleanOr() {
    // if the condition contains only the and statement, remove  "( and )"
    // at the start and the end of the string. This just for visual convenience.
//    if (!_whereBooleans.contains('OR')) {
//      completeCondition = completeCondition.replaceFirst('(', '');
//      completeCondition = completeCondition
//        .split('')
//        .reversed
//        .join('')
//        .replaceFirst(')', '')
//        .split('')
//        .reversed
//        .join('');
  }
}



enum Verb {
  select, create, update, delete
}

enum ValueType {
  undefined
}
