import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:http/http.dart' as http;
import 'package:characters/characters.dart'; // Import the characters package

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

class CommentListWidget extends StatefulWidget {
  @override
  _CommentListWidgetState createState() => _CommentListWidgetState();
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


Widget _buildRichCommentText(BuildContext context, String text, List<String> images, List<String> boldNames) {
  List<InlineSpan> textSpans = [];
  RegExp regExp = RegExp(r'\[attachment-\d\]|\b\w+\s*\w*\b|.');

  List<String> parts = regExp.allMatches(text).map((match) => match.group(0)!).toList();

  List<TextSpan> currentTextSpans = [];
  var parser = EmojiParser();

  void addCurrentTextSpans() {
    textSpans.addAll(currentTextSpans);
    currentTextSpans.clear();
  }

  bool isBold(String name) {
    return boldNames.map((e) => e.trim()).contains(name);
  }

  for (int i = 0; i < parts.length; i++) {
    if (parts[i].startsWith('[attachment-')) {
      // Handle attachments
      int imageIndex = int.parse(parts[i].replaceAll(RegExp(r'[^0-9]'), ''), radix: 10) - 1;
      if (imageIndex >= 0 && imageIndex < images.length) {
        addCurrentTextSpans(); // Add existing text spans before the image
        textSpans.add(WidgetSpan(
          child: _buildImageWidget(images[imageIndex]),
        ));
      }
    } else {
      // Handle names and other text
      String name = parts[i].trim(); // Remove leading and trailing whitespaces
      bool shouldBold = isBold(name);

      String parsedText = parser.unemojify(parts[i]);

      currentTextSpans.add(TextSpan(
        text: parsedText,
        style: TextStyle(
          fontWeight: shouldBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 16, // Adjust the font size as needed
        ),
      ));

      // Add space to the right of bold text, except for the last part
      if (shouldBold && i < parts.length - 1) {
        currentTextSpans.add(TextSpan(text: ' '));
      }
    }
  }

  addCurrentTextSpans(); // Add any remaining text spans

  return RichText(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: textSpans,
    ),
  );
}


  Widget _buildImageWidget(String imageUrl) {
    String fullImageUrl = 'https://staging.simmpli.com$imageUrl';
    return CircleAvatar(
      backgroundImage: NetworkImage(
        fullImageUrl,
      ),
      radius: 8,
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
