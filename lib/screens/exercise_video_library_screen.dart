import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseVideoLibraryScreen extends StatelessWidget {
  final List<Map<String, String>> videos = [
    {
      'title': 'Beginner Cardio Routine',
      'url': 'https://www.youtube.com/watch?v=ml6cT4AZdqI',
      'thumbnail': 'https://img.youtube.com/vi/ml6cT4AZdqI/0.jpg',
    },
    {
      'title': 'Strength Training for Diabetes',
      'url': 'https://www.youtube.com/watch?v=UItWltVZZmE',
      'thumbnail': 'https://img.youtube.com/vi/UItWltVZZmE/0.jpg',
    },
    {
      'title': 'Stretching and Flexibility',
      'url': 'https://www.youtube.com/watch?v=JJAHGpe0AVU',
      'thumbnail': 'https://img.youtube.com/vi/JJAHGpe0AVU/0.jpg',
    },
  ];

  ExerciseVideoLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Video Library')),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: Image.network(
                video['thumbnail']!,
                width: 80,
                fit: BoxFit.cover,
              ),
              title: Text(video['title']!),
              trailing: const Icon(
                Icons.play_circle_fill,
                color: Colors.teal,
                size: 32,
              ),
              onTap: () async {
                final url = Uri.parse(video['url']!);
                final messenger = ScaffoldMessenger.of(context);
                // ignore: deprecated_member_use
                final can = await canLaunchUrl(url);
                if (!can) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Could not open video.')),
                  );
                  return;
                }
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
          );
        },
      ),
    );
  }
}

// Add dependencies in pubspec.yaml:
// url_launcher: ^6.2.5
