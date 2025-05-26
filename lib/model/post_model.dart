class Post {
  final int id;

  final String slug;
  final int? parentVideoId;
  final int childVideoCount;
  final String title;
  final String thumbnail_url;
  final String videoLink;
  final Post? parentPost;

  Post({
    required this.id,

    required this.slug,
    this.parentVideoId,
    required this.childVideoCount,
    required this.title,
    required this.thumbnail_url,
    required this.videoLink,
    this.parentPost
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
     
      slug: json['slug'],
      parentVideoId: json['parent_video_id'],
      childVideoCount: json['child_video_count'],
      title: json['title'],
      thumbnail_url: json['thumbnail_url'],
      videoLink: json['video_link'],
    );
  }
}
