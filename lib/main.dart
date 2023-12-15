import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommentListWidget extends StatefulWidget {
  @override
  _CommentListWidgetState createState() => _CommentListWidgetState();
}

class Comment {
  final String text;
  final List<String> images;
  final List<String> names;

  Comment({
    required this.text,
    required this.images,
    required this.names,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      text: json['text'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      names: List<String>.from(json['names'] ?? []),
    );
  }
}

class _CommentListWidgetState extends State<CommentListWidget> {
  List<Comment> comments = [];
  bool isLoading = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      const String token =
          'Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoyLCJ0aW1lIjoxNzAxOTQ0NjE1fQ.ZCl1pDug6j90L4HqVcCjNMSYF3wRuRac1gy9XPUyXZY';

      final response = await http.get(
        Uri.parse(
          'https://staging.simmpli.com/api/v1/users/wall_posts_description.json?page=$currentPage',
        ),
        headers: {'Authorization': token},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        //   [
        //   {"text": "Hello!", "images": ["image1.jpg", "image2.jpg"]},
        //   {"text": "Another comment", "images": ["image3.jpg"]}
        //  ]
        // gaving the  of data jsonList using json list you iterate tha data

        final List<Comment> fetchedComments = jsonList.map((json) {
          return Comment.fromJson(json);
        }).toList();

        setState(() {
          comments.addAll(fetchedComments);
        });
      } else {
        print('Failed to load comments');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social App'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return SocialCommentsWidget(
                  comment: comment,
                  context: context,
                );
              },
            ),
    );
  }
}

class SocialCommentsWidget extends StatelessWidget {
  final Comment comment;
  final BuildContext context;

  SocialCommentsWidget({required this.comment, required this.context});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRichCommentText(
                context, comment.text, comment.images, comment.names),
          ],
        ),
      ),
    );
  }

 Widget _buildRichCommentText(BuildContext context, String text, List<String> images, List<String> names) {
  List<InlineSpan> textSpans = [];
  List<String> parts = text.split(RegExp(r'\[attachment-\d\]'));
  int imageIndex = 0; // Track the index of the current image

  for (int i = 0; i < parts.length; i++) {
    String partWithoutNames = parts[i];
    Set<String> addedNames = Set(); // Keep track of names that have been added

    // Remove names from the part
    for (String name in names) {
      partWithoutNames = partWithoutNames.replaceAll(name, '');
    }

    // Add bold name if corresponding to the current part
    for (String name in names) {
      if (parts[i].contains(name) && !addedNames.contains(name)) {
        textSpans.add(TextSpan(
          text: name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
        addedNames.add(name);
      }
    }

    textSpans.add(TextSpan(text: partWithoutNames));

    if (i < images.length) {
      // Add the image
      textSpans.add(WidgetSpan(
        child: _buildImageWidget(images[imageIndex]),
      ));

      imageIndex++;
    }

    // Print the current state of textSpans
    print(textSpans);
  }

  return RichText(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: textSpans,
    ),
  );
}

  Widget _buildImageWidget(String imageUrl) {
    String fullImageUrl = 'https://staging.simmpli.com$imageUrl';
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: CircleAvatar(
        backgroundImage: NetworkImage(
          fullImageUrl,
        ),
        radius: 8,
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      home: CommentListWidget(),
    ),
  );
}
