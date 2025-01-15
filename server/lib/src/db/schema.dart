import 'package:mysql1/mysql1.dart';

Future<void> ensureSchema(MySqlConnection conn,
    {required String dbName}) async {
  await conn.query('CREATE DATABASE IF NOT EXISTS $dbName');
  await conn.query('USE $dbName');

  await conn.query('''
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      email VARCHAR(120) NOT NULL UNIQUE,
      password_hash VARCHAR(100) NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await conn.query('''
    CREATE TABLE IF NOT EXISTS investments (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      date DATE NOT NULL,
      asset VARCHAR(32) NOT NULL,
      amount DOUBLE NOT NULL
    )
  ''');

  // Backward-compatible migration for existing DBs created before user_id existed.
  await conn.query('''
    ALTER TABLE investments
    ADD COLUMN IF NOT EXISTS user_id INT NOT NULL DEFAULT 0
  ''');
}
