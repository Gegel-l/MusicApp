class Review {
  final String author;
  final String text;
  final double rating;
  final DateTime date;
  final String? uid;

  Review({
    required this.author,
    required this.text,
    required this.rating,
    required this.date,
    this.uid,
  });

  Map<String, dynamic> toMap() => {
    'author': author,
    'text': text,
    'rating': rating,
    'date': date.millisecondsSinceEpoch,
    if (uid != null) 'uid': uid,
  };

  factory Review.fromMap(Map<String, dynamic> m) => Review(
    author: m['author'] ?? '',
    text: m['text'] ?? '',
    rating: (m['rating'] as num).toDouble(),
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
  );
}
