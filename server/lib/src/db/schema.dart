import 'package:mysql1/mysql1.dart';

// This file defines the database schema and ensures that the necessary tables exist
Future<void> ensureSchema(MySqlConnection conn,
    {required String dbName}) async {
  // the ensureSchema function takes a MySqlConnection and a database name as parameters,
  // and creates the database and tables if they do not already exist, including
  // a migration for existing databases that may not have the user_id column
  // in the investments table. It also ensures that the user_id column is added
  // to the investments table if it does not exist, with a default value of
  // 0 for backward compatibility with existing databases.
  await conn.query('CREATE DATABASE IF NOT EXISTS $dbName');
  await conn.query('USE $dbName');

  await conn.query('''
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      email VARCHAR(120) NOT NULL UNIQUE,
      role VARCHAR(24) NOT NULL DEFAULT 'user',
      token_version INT NOT NULL DEFAULT 0,
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

  await conn.query('''
    CREATE TABLE IF NOT EXISTS registration_otps (
      id INT AUTO_INCREMENT PRIMARY KEY,
      email VARCHAR(120) NOT NULL UNIQUE,
      password_hash VARCHAR(100) NOT NULL,
      otp_code VARCHAR(8) NOT NULL,
      expires_at DATETIME NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  // Backward-compatible migration for existing DBs created before user_id existed.
  await conn.query('''
    ALTER TABLE investments
    ADD COLUMN IF NOT EXISTS user_id INT NOT NULL DEFAULT 0
  ''');

  await conn.query('''
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS role VARCHAR(24) NOT NULL DEFAULT 'user'
  ''');

  await conn.query('''
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS token_version INT NOT NULL DEFAULT 0
  ''');
}
