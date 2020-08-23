/// Represents Laravel's basic pagination model.
/// [T] is the type of list of data that contains the paginator.
class Paginator<T> {
  int currentPage;
  List<T> data;
  String firstPageUrl;
  String lastPageUrl;
  String nextPageUrl;
  String prevPageUrl;
  String path;
  /// The element the pagination starts from.
  int from;
  /// The element the pagination ends to.
  int to;
  int perPage;
  int total;

  Map<String, dynamic> _meta = _emptyMeta;

  int get nextPage => (currentPage ?? 0) + 1;

  Paginator({
    this.data,
    this.path,
    this.currentPage,
    this.firstPageUrl,
    this.from,
    this.lastPageUrl,
    this.nextPageUrl,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
    Map<String, dynamic> meta
  }) : _meta = meta;

  factory Paginator.empty() {
    return new Paginator(
      data: [],
      path: '',
      currentPage: 0,
      firstPageUrl: '',
      nextPageUrl: '',
      perPage: 10,
      prevPageUrl: '',
      to: 0,
      from: 0,
      total: 0,
      meta: _emptyMeta
    );
  }

  factory Paginator.fromJson(Map<String, dynamic> json, {dataFromMeta = true}) {
    if (dataFromMeta) {
      json.addAll(json['meta']);
      json.addAll(json['link']);
    }
    /*if (dataFromMeta) {
      json = _mapPaginatorStyle2(json);
    }*/
    return new Paginator(
      path: json['path'],
      currentPage: json['current_page'],
      nextPageUrl: json['next_page_url'],
      prevPageUrl: json['prev_page_url'],
      lastPageUrl: json['last_page_url'],
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      to: json['to'],
      total: json['total'],
      perPage: json['per_page'],
      data: json['data'],
      meta: json['meta']
    );
  }

  /// Note: The data property return the same object and not a map.
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'current_page': currentPage,
      'next_page_url': nextPageUrl,
      'first_page_url': firstPageUrl,
      'prev_page_url': prevPageUrl,
      'last_page_url': lastPageUrl,
      'path': path,
      'to': to,
      'from': from,
      'total': total,
      'per_page': perPage,
      'meta': _meta
    };
  }

  /// Laravel server has been configured to return the paginated data
  /// under another style. Not to modify the client app pagination model,
  /// this method just map the api model into the client app model
  /// for thinks being transparent for the rest of the app code.
  static Map<String, dynamic> _mapPaginatorStyle2(Map<String, dynamic> json) {
    var links = json['links'];
    var meta = json['meta'];
    return {
      'data': json['data'],
      'next_page_url': links['next'],
      'first_page_url': links['first'],
      'prev_page_url': links['prev'],
      'last_page_url': links['last'],
      'current_page': meta['current_page'],
      'path': meta['path'],
      'to': meta['to'],
      'from': meta['from'],
      'total': meta['total'],
      'per_page': meta['per_page']
    };
  }

  static final Map<String, dynamic> _emptyMeta = {
    'path': '',
    'to': 0,
    'from': 0,
    'total': 0,
    'current_page': 0,
    'per_page': 10
  };

  /// Returns the length of the data inside
  /// of the paginator at the current moment.
  int get currentLength => data.length;

  /// Merge a [other] inside of this paginator.
  ///
  /// If [currentPage] of both [other] and [this] are equal, nothing is done.
  ///
  /// If [other] is a paginator of a greater page, merge [this] inside of [other].
  /// If [other] is a paginator of an older page than [this], merge inside of [this]
  ///
  /// When a paginator is merge with another. The most recent paginator's (which has the largest [currentPage])
  /// metadata and links override the older. Only the [data] are really merged.
  Paginator<T> merge(Paginator<T> other) {
    if (other == null) return new Paginator<T>.fromJson(this.toJson());

    if (other == this) return new Paginator<T>.fromJson(this.toJson());

    if (other.data.isEmpty) return new Paginator<T>.fromJson(this.toJson());

    if (this.data.isEmpty) return new Paginator<T>.fromJson(other.toJson());

    /*if (other > this) {
      print('Other superior =====>');
      return other
        ..data.insertAll(0, this.data);
    } else {
      print('Other inferior =====>');
      return this
        ..data.addAll(other.data);
    }*/

    if (this > other) {
      var p = new Paginator<T>.fromJson(this.toJson());
      p.data.insertAll(0, other.data);
      return p;
    } else {
      var p = new Paginator<T>.fromJson(other.toJson());
      p.data.insertAll(0, this.data);
      return p;
    }
  }

  @override
  bool operator ==(other) {
    if (other == null || other is! Paginator<T>) return false;
    return identical(this, other) || currentPage == other.currentPage;
  }

  /// Tells that the paginator comes before [other]
  bool operator <(Paginator<T> other) => currentPage < other.currentPage;

  /// Tells that the paginator comes after [other]
  bool operator >(Paginator<T> other) => currentPage > other.currentPage;

  @override
  int get hashCode => currentPage ^ perPage ^ total;

}
