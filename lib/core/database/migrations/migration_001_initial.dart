import 'package:sqflite/sqflite.dart';

const List<String> _statements = [
  '''
CREATE TABLE pets (
  id                 TEXT PRIMARY KEY,
  species            TEXT NOT NULL CHECK (species IN ('dog','cat')),
  name               TEXT,
  sex                TEXT NOT NULL DEFAULT 'unknown' CHECK (sex IN ('male','female','unknown')),
  age_group          TEXT NOT NULL DEFAULT 'unknown' CHECK (age_group IN ('puppy','young','adult','senior','unknown')),
  size               TEXT NOT NULL DEFAULT 'unknown' CHECK (size IN ('small','medium','large','unknown')),
  photo_file_name    TEXT,
  appearance         TEXT,
  is_docile          TEXT NOT NULL DEFAULT 'unknown' CHECK (is_docile IN ('yes','no','unknown')),
  is_neutered        TEXT NOT NULL DEFAULT 'unknown' CHECK (is_neutered IN ('yes','no','unknown')),
  is_pregnant        TEXT NOT NULL DEFAULT 'unknown' CHECK (is_pregnant IN ('yes','no','unknown')),
  has_litter         TEXT NOT NULL DEFAULT 'unknown' CHECK (has_litter IN ('yes','no','unknown')),
  litter_size        INTEGER CHECK (litter_size IS NULL OR litter_size BETWEEN 1 AND 20),
  has_injuries       TEXT NOT NULL DEFAULT 'unknown' CHECK (has_injuries IN ('yes','no','unknown')),
  injury_description TEXT,
  known_diseases     TEXT,
  rabies_vaccination TEXT NOT NULL DEFAULT 'unknown' CHECK (rabies_vaccination IN ('yes','no','unknown')),
  other_health_info  TEXT,
  notes              TEXT,
  latitude           REAL NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude          REAL NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  location_reference TEXT,
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL
)''',
  '''
CREATE TABLE care_records (
  id               TEXT PRIMARY KEY,
  pet_id           TEXT NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  type             TEXT NOT NULL CHECK (type IN ('feeding','bath','medication','health')),
  occurred_at      TEXT NOT NULL,
  has_time         INTEGER NOT NULL DEFAULT 0,
  responsible_name TEXT,
  notes            TEXT,
  medication_name  TEXT,
  health_kind      TEXT,
  created_at       TEXT NOT NULL,
  CHECK (type <> 'medication' OR medication_name IS NOT NULL),
  CHECK (type <> 'health' OR health_kind IS NOT NULL)
)''',
  'CREATE INDEX idx_care_pet_type_date ON care_records (pet_id, type, occurred_at DESC)',
  'CREATE INDEX idx_pets_species ON pets (species)',
];

/// Migração 1: esquema inicial. Nunca edite após publicada; crie a 002.
Future<void> migration001(Database db) async {
  for (final statement in _statements) {
    await db.execute(statement);
  }
}
