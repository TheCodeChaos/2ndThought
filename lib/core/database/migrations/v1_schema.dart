const String v1Schema = '''
CREATE TABLE blocked_apps (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  package_name TEXT    NOT NULL UNIQUE,
  app_name     TEXT    NOT NULL,
  icon_b64     TEXT,
  is_active    INTEGER NOT NULL DEFAULT 1,
  added_at     INTEGER NOT NULL
);

CREATE TABLE active_sessions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  package_name TEXT    NOT NULL,
  granted_at   INTEGER NOT NULL,
  expires_at   INTEGER NOT NULL,
  game_type    TEXT    NOT NULL
);

CREATE TABLE challenge_history (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  package_name TEXT    NOT NULL,
  app_name     TEXT    NOT NULL,
  game_type    TEXT    NOT NULL,
  outcome      TEXT    NOT NULL,
  duration_ms  INTEGER NOT NULL,
  focus_points INTEGER NOT NULL,
  played_at    INTEGER NOT NULL
);

CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
''';

const List<Map<String, String>> defaultSettings = [
  {'key': 'session_duration_minutes', 'value': '10'},
  {'key': 'daily_focus_goal', 'value': '5'},
  {'key': 'onboarding_complete', 'value': 'false'},
];
