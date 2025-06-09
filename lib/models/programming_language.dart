class ProgrammingLanguage {
  final String name;
  final String icon;
  final String description;

  ProgrammingLanguage({
    required this.name,
    required this.icon,
    required this.description,
  });
}

class ProgrammingLanguages {
  static final List<ProgrammingLanguage> languages = [
    ProgrammingLanguage(
      name: 'Python',
      icon: '🐍',
      description:
          'General-purpose programming language focused on readability',
    ),
    ProgrammingLanguage(
      name: 'Java',
      icon: '☕',
      description:
          'Object-oriented programming language designed for portability',
    ),
    ProgrammingLanguage(
      name: 'JavaScript',
      icon: '🌐',
      description: 'Programming language that enables interactive web pages',
    ),
    ProgrammingLanguage(
      name: 'C',
      icon: '🔧',
      description:
          'General-purpose programming language ideal for system programming',
    ),
    ProgrammingLanguage(
      name: 'C++',
      icon: '⚙️',
      description: 'Extension of the C programming language with OOP features',
    ),
    ProgrammingLanguage(
      name: 'C#',
      icon: '🎮',
      description: 'Object-oriented programming language by Microsoft',
    ),
    ProgrammingLanguage(
      name: 'Go',
      icon: '🐹',
      description:
          'Statically typed, compiled language with garbage collection',
    ),
    ProgrammingLanguage(
      name: 'Rust',
      icon: '🦀',
      description:
          'Systems programming language focused on safety and performance',
    ),
    ProgrammingLanguage(
      name: 'Swift',
      icon: '🍎',
      description: 'Programming language for iOS and macOS development',
    ),
    ProgrammingLanguage(
      name: 'Kotlin',
      icon: '📱',
      description: 'Modern programming language for Android development',
    ),
    ProgrammingLanguage(
      name: 'TypeScript',
      icon: '📝',
      description:
          'Typed superset of JavaScript that compiles to plain JavaScript',
    ),
    ProgrammingLanguage(
      name: 'PHP',
      icon: '🌐',
      description: 'Server-side scripting language for web development',
    ),
  ];
}
