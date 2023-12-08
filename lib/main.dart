import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Comment {
  final String text;
  final List<String> images;

  Comment({required this.text, required this.images});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      text: json['text'],
      images: List<String>.from(json['images']),
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
            _buildRichCommentText(context, comment.text, comment.images),
            
          ],
        ),
      ),
    );
  }

  Widget _buildRichCommentText(BuildContext context, String text, List<String> images) {
    List<InlineSpan> textSpans = [];
    List<String> parts = text.split(RegExp(r'\[attachment-\d\]'));

    for (int i = 0; i < parts.length; i++) {
      textSpans.add(TextSpan(text: parts[i]));
      if (i < images.length) {
        textSpans.add(WidgetSpan(
          child: _buildImageWidget(images[i]),
        ));
      }
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
