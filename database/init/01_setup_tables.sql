-- initialize the database tables

CREATE TYPE game_status_enum AS ENUM (
    'waiting_for_players',
    'active',
    'finished'
);

CREATE TABLE IF NOT EXISTS games (
    game_id SERIAL PRIMARY KEY,
    admin_code CHAR(16) NOT NULL UNIQUE,
    game_name VARCHAR(255) NOT NULL,
    game_description TEXT NOT NULL CHECK (char_length(game_description) < 2500),
    game_status game_status_enum NOT NULL DEFAULT 'waiting_for_players',
    min_songs_per_playlist SMALLINT NOT NULL DEFAULT 1 CHECK (
        min_songs_per_playlist >= 1 AND
        min_songs_per_playlist <= 100 AND
        min_songs_per_playlist <= max_songs_per_playlist
    ),
    max_songs_per_playlist SMALLINT NOT NULL DEFAULT 100 CHECK (
        max_songs_per_playlist >= 1 AND
        max_songs_per_playlist <= 100 AND
        min_songs_per_playlist <= max_songs_per_playlist
    ),
    require_playlist_link BOOLEAN NOT NULL,
    invite_code CHAR(16) UNIQUE,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS players (
    player_id SERIAL PRIMARY KEY,
    game_id INT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    player_code CHAR(16) NOT NULL UNIQUE,
    player_name VARCHAR(255) NOT NULL,
    playlist_link VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS songs (
    song_id SERIAL PRIMARY KEY,
    player_id INT NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS ratings (
    rating_id SERIAL PRIMARY KEY,
    song_id INT NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,
    rater_player_id INT NOT NULL REFERENCES players(player_id),
    rating REAL CHECK (rating >= 0 AND rating <= 10),
    UNIQUE (song_id, rater_player_id)   -- 1 rating per person per song
);

-- create indexes on fields that are typically used for joins
-- these tables are read from far more then they're written to

CREATE INDEX idx_games_admin_code ON games(admin_code);

CREATE INDEX idx_players_game_id_player_id ON players(game_id, player_id);
CREATE INDEX idx_players_player_code ON players(player_code);

CREATE INDEX idx_songs_player_id_song_id ON songs(player_id, song_id);
CREATE INDEX idx_songs_player_id ON songs(player_id);

-- the lack of an index on the ratings table is because it has significantly
-- higher write volume than read volume
