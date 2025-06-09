class GoogleSearchResult {
  final String title;
  final String link;

  GoogleSearchResult({required this.title, required this.link});

  factory GoogleSearchResult.fromJson(Map<String, dynamic> json) {
    return GoogleSearchResult(
        title: json['title'] ?? '',
        link: json['link'] ?? ''
    );
  }
}