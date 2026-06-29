/// A NEAT project the user has created or opened, persisted for the Hub's
/// "Recent Projects" list. [path] is the absolute project root (it holds a
/// `.neat.json`).
class RecentProject {
  const RecentProject({
    required this.path,
    required this.name,
    required this.lastOpened,
  });

  factory RecentProject.fromJson(Map<String, dynamic> json) => RecentProject(
        path: json['path'] as String,
        name: json['name'] as String,
        lastOpened: DateTime.parse(json['lastOpened'] as String),
      );

  final String path;
  final String name;
  final DateTime lastOpened;

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'lastOpened': lastOpened.toIso8601String(),
      };
}
