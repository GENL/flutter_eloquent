import 'dart:convert';

mixin JsonParsable {
  // convert json to string for database
  Map<String, dynamic> jsonStringify(Map<dynamic, dynamic> data) {
    Map json = new Map<String, dynamic>();
    data.forEach((key, value) {
      json[key] = _stringify(value);
    });
    return json;
  }

  String toFullString(Map<dynamic, dynamic> data) {
    String text = '{';
    data.forEach((key, value) {
      text += '\\"$key\\":${_toFullString(value)}';
    });
    text += '}';
    return text;
  }

  dynamic _toFullString(data) {
    if (data is List) {
      data = '[';
      data.forEach(
          (d) => data += ((d is Map) ? toFullString(d) : _toFullString(d)));
      data += ']';
    } else if (data is Map)
      data = toFullString(data);
    else if (data is String) {
      if ((num.tryParse(data) is num))
        data = data;
      else
        data = data.replaceAll('"', '""').replaceAll("'", "''");
    } else if (data is num) data = data;
    return data;
  }

  dynamic _stringify(data) {
    if (data is List) {
      data = jsonEncode(data
          .map((d) => (d is Map) ? jsonStringify(d) : _stringify(d))
          .toList());
    } else if (data is Map)
      data = jsonEncode(jsonStringify(data));
    else if (data is String) {
      if ((int.tryParse(data) is int))
        data = jsonEncode(data);
      else
        data = data.replaceAll('"', '""').replaceAll("'", "''");
    }
    return data;
  }

  // parse json data from database to native type bool int etc...
  Map<String, dynamic> dataParser(Map<String, dynamic> json) {
    Map parsedJson = new Map<String, dynamic>();
    json.forEach((key, value) {
      if (value is String)
        try {
          var res = _jsonParser(value);
          value = res is Map ? dataParser(res) : res;
        } catch (e) {
          try {
            value = _doubleParser(value);
          } catch (e2) {
            value = _boolParser(value);
          }
        }
      parsedJson[key] = value;
    });
    return parsedJson;
  }

  _jsonParser(String data) {
    return jsonDecode(data);
  }

  _boolParser(String data) {
    switch (data) {
      case "true":
        return true;
        break;
      case "false":
        return false;
        break;
      default:
        return data;
    }
  }

  _doubleParser(String data) {
    return double.parse(data);
  }
}

mixin JsonHelpable<E extends Map> {
  E jsonWithoutNull(E json) {
    assert(json != null);
    json.removeWhere((k, v) =>
        v == null ||
        v is String && v.trim().isEmpty ||
        v is List && v.isEmpty ||
        v is Map && v.isEmpty);
    return json;
  }

  E jsonClearDeep(E json) {
    assert(json != null);
    return _jsonClearDeep(json);
  }

  _jsonClearDeep(data) {
    if (data == null) return null;
    if (data is List) {
      var tmp = [];
      data.forEach((e) {
        var res = _jsonClearDeep(e);
        if (_check(res)) tmp.add(res);
      });
      return tmp;
    }
    if (data is Map) {
      var tmp = {};
      data.forEach((k, v) {
        var res = _jsonClearDeep(v);
        if (_check(res)) tmp[k] = res;
      });
      return tmp;
    }
    return data;
  }

  bool _check(data) {
    if (data is List || data is Map || data is String) return data.isNotEmpty;
    return data != null;
  }

  Map jsonMerge(Map json1, Map json2) {
    if (json1 == null) return json2;
    if (json2 == null) return json1;
    var data = {};
    json1.forEach((k, v) {
      if (json2.containsKey(k)) {
        data[k] = v is Map
            ? jsonMerge(v, json2[k])
            : (v is List ? (v..addAll(json2[k])) : json2[k]);
      } else
        data[k] = v;
    });
    return data;
  }
}
