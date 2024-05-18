-- ****************************  Tables *****************************
-- Movies
CREATE TABLE movies(
    movieID SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    duration INTEGER CHECK (duration>0),
    release_date DATE CHECK(release_date <= CURRENT_DATE) DEFAULT CURRENT_DATE);

-- Rooms
CREATE TABLE rooms(
    roomID SERIAL PRIMARY KEY,
    room_name VARCHAR(255) NOT NULL CHECK(room_name NOT LIKE '%test%'),
    seat_capacity INTEGER CHECK(seat_capacity>0));

-- Sessions
CREATE TABLE sessions(
    sessionID SERIAL PRIMARY KEY,
    movieID INTEGER REFERENCES movies(movieID) ON DELETE CASCADE,
    roomID INTEGER REFERENCES rooms(roomID) ON DELETE CASCADE,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    duration INTEGER CHECK(duration>0));

-- Tickets
CREATE TABLE tickets(
    ticketID SERIAL PRIMARY KEY,
    sessionID INTEGER REFERENCES sessions(sessionID) ON DELETE CASCADE,
    seat_nr INTEGER,
    price DECIMAL CHECK(price BETWEEN 0.01 AND 1000.0),
    purchase_date DATE DEFAULT CURRENT_DATE);

-- Genres
CREATE TABLE genres(
    genreID SERIAL PRIMARY KEY,
    genre_name VARCHAR(255) NOT NULL);

-- Directors
CREATE TABLE directors(
    directorID SERIAL PRIMARY KEY,
    director_name VARCHAR(255) NOT NULL);

-- MovieGenres
CREATE TABLE moviegenres(
    movieID INTEGER REFERENCES movies(movieID) ON DELETE CASCADE,
    genreID INTEGER REFERENCES genres(genreID) ON DELETE CASCADE);

-- MovieDirectors
CREATE TABLE moviedirectors(
    movieID INTEGER REFERENCES movies(movieID),
    directorID INTEGER REFERENCES directors(directorID));

-- ********************************* INDEXES *************************************
-- All the serial prim keys - unique
-- Non-unique on dif one movie sessions:
CREATE INDEX sessmovid_index ON sessions(movieID);

-- Unique seat for each session!!!
CREATE UNIQUE INDEX unq_seat_index ON tickets(sessionID, seat_nr);

-- ********************************* VIEWS ****************************************
CREATE MATERIALIZED VIEW ticket_sales AS
SELECT M.title, COUNT(*) AS tickets_sold, SUM(T.price) AS total_rev
FROM tickets T
JOIN sessions S ON T.sessionID = S.sessionID
JOIN movies M ON S.movieID = M.movieID
GROUP BY M.title;

-- DON'T FORGET TO REFRESH!!!
REFRESH MATERIALIZED VIEW ticket_sales;

-- View1
CREATE VIEW moviegenres_linked AS
SELECT M.title, G.genre_name
FROM movies M
JOIN moviegenres MG ON M.movieID = MG.movieID
JOIN genres G ON MG.genreID = G.genreID;

-- View2
CREATE VIEW moviedirectors_linked AS
SELECT M.title, D.director_name
FROM movies M
JOIN moviedirectors MD ON M.movieID = MD.movieID
JOIN directors D ON MD.directorID = D.directorID;
-- ********************************* TRIGGERS *********************************
-- SESSION DURATION = MOVIE DURATION ON SESSION INSERT!!
CREATE OR REPLACE FUNCTION update_session_duration() RETURNS TRIGGER AS $$
DECLARE
    movie_duration INTEGER;
BEGIN
    SELECT duration INTO movie_duration FROM movies WHERE movieID = NEW.movieID;
    NEW.duration := movie_duration;
    RETURN NEW;
END;
$$LANGUAGE plpgsql;

CREATE TRIGGER session_duration_trigger
BEFORE INSERT OR UPDATE OF movieID ON sessions
FOR EACH ROW EXECUTE FUNCTION update_session_duration();

-- SESSION EXISTS = MOVIE CAN'T BE DELETED!!
CREATE OR REPLACE FUNCTION prevent_movie_deletion() RETURNS TRIGGER AS $$
DECLARE
    future_sessions_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO future_sessions_count FROM sessions WHERE movieID = OLD.movieID AND start_date>CURRENT_DATE;
    IF future_sessions_count>0 THEN
        RAISE EXCEPTION 'Movie % has sessions, what u doin''?', OLD.movieID;
    END IF;
    RETURN OLD;
END;
$$LANGUAGE plpgsql;

CREATE TRIGGER prevent_movie_deletion_trigger
BEFORE DELETE ON movies
FOR EACH ROW EXECUTE FUNCTION prevent_movie_deletion();

-- ********************************* DATA INSERTS *********************************
-- GENRES 
INSERT INTO genres(genre_name) VALUES('Action');			-- 1
INSERT INTO genres(genre_name) VALUES('Adventure');			-- 2
INSERT INTO genres(genre_name) VALUES('Animation');			-- 3
INSERT INTO genres(genre_name) VALUES('Comedy');			-- 4
INSERT INTO genres(genre_name) VALUES('Crime');				-- 5
INSERT INTO genres(genre_name) VALUES('Documentary');		-- 6
INSERT INTO genres(genre_name) VALUES('Drama');				-- 7
INSERT INTO genres(genre_name) VALUES('Family');			-- 8
INSERT INTO genres(genre_name) VALUES('Fantasy');			-- 9
INSERT INTO genres(genre_name) VALUES('Historical');		-- 10
INSERT INTO genres(genre_name) VALUES('Horror');			-- 11
INSERT INTO genres(genre_name) VALUES('Music');				-- 12
INSERT INTO genres(genre_name) VALUES('Mystery');			-- 13
INSERT INTO genres(genre_name) VALUES('Romance');			-- 14
INSERT INTO genres(genre_name) VALUES('Science fiction');	-- 15
INSERT INTO genres(genre_name) VALUES('TV Movie');			-- 16
INSERT INTO genres(genre_name) VALUES('Thriller');			-- 17
INSERT INTO genres(genre_name) VALUES('War');				-- 18
INSERT INTO genres(genre_name) VALUES('Western');			-- 19

-- ROOMS
INSERT INTO Rooms(room_name, seat_capacity) VALUES('Mini room A', 25);
INSERT INTO Rooms(room_name, seat_capacity) VALUES('Mini room B', 50);
INSERT INTO Rooms(room_name, seat_capacity) VALUES('Room A', 100);
INSERT INTO Rooms(room_name, seat_capacity) VALUES('Room B', 250);
INSERT INTO Rooms(room_name, seat_capacity) VALUES('Room C', 500);

-- MOVIES
INSERT INTO movies(title, duration, release_date) VALUES('The Art of Racing in the Rain', 109, '2019-08-09');
INSERT INTO movies(title, duration, release_date) VALUES('High School Musical 3: Senior Year', 112, '2008-10-24');
INSERT INTO movies(title, duration, release_date) VALUES('Barbie and the Three Musketeers', 81, '2009-09-15');
INSERT INTO movies(title, duration, release_date) VALUES('The Man from Earth', 87, '2007-11-13');
INSERT INTO movies(title, duration, release_date) VALUES('Hang ''em High', 114, '1968-07-31');
INSERT INTO movies(title, duration, release_date) VALUES('Long Shot', 125, '2019-05-03');
INSERT INTO movies(title, duration, release_date) VALUES('Conspiracy Theory', 135, '1997-08-08');
INSERT INTO movies(title, duration, release_date) VALUES('Uncharted', 116, '2022-02-18');
INSERT INTO movies(title, duration, release_date) VALUES('Mother', 129, '2009-05-28');
INSERT INTO movies(title, duration, release_date) VALUES('The Devil''s Rejects', 107, '2005-07-22');
INSERT INTO movies(title, duration, release_date) VALUES('Luther: The Fallen Sun', 129, '2023-03-10');
INSERT INTO movies(title, duration, release_date) VALUES('JUNG_E', 98, '2023-01-20');
INSERT INTO movies(title, duration, release_date) VALUES('New Police Story', 123, '2004-09-24');
INSERT INTO movies(title, duration, release_date) VALUES('Deathstroke: Knights & Dragons - The Movie', 87, '2020-08-04');
INSERT INTO movies(title, duration, release_date) VALUES('Million Dollar Arm', 124, '2014-05-16');
INSERT INTO movies(title, duration, release_date) VALUES('Resident Evil: Apocalypse', 94, '2004-09-10');
INSERT INTO movies(title, duration, release_date) VALUES('Mister Happiness', 95, '2017-01-01');
INSERT INTO movies(title, duration, release_date) VALUES('The Prince of Hearts', 89, '1998-11-22');
INSERT INTO movies(title, duration, release_date) VALUES('The Matrix', 136, '1999-03-31');
INSERT INTO movies(title, duration, release_date) VALUES('Superman II', 127, '1981-06-19');

-- DIRECTORS
INSERT INTO directors(director_name) VALUES('Simon Curtis');
INSERT INTO directors(director_name) VALUES('Kenny Ortega');
INSERT INTO directors(director_name) VALUES('William Lau');
INSERT INTO directors(director_name) VALUES('Richard Schenkman');
INSERT INTO directors(director_name) VALUES('Ted Post');
INSERT INTO directors(director_name) VALUES('Jonathan Levine');
INSERT INTO directors(director_name) VALUES('Richard Donner');
INSERT INTO directors(director_name) VALUES('Ruben Fleischer');
INSERT INTO directors(director_name) VALUES('Bong Joon Ho');
INSERT INTO directors(director_name) VALUES('Rob Zombie');
INSERT INTO directors(director_name) VALUES('Jamie Payne');
INSERT INTO directors(director_name) VALUES('Yeon Sang-ho');
INSERT INTO directors(director_name) VALUES('Benny Chan');
INSERT INTO directors(director_name) VALUES('Sung Jin Ahn');
INSERT INTO directors(director_name) VALUES('Craig Gillespie');
INSERT INTO directors(director_name) VALUES('Alexander Witt');
INSERT INTO directors(director_name) VALUES('Alessandro Siani');
INSERT INTO directors(director_name) VALUES('Lana Wachowski');
INSERT INTO directors(director_name) VALUES('Lilly Wachowski');
INSERT INTO directors(director_name) VALUES('Richard Lester');

-- GENRE LINK
INSERT INTO moviegenres(movieID, genreID) VALUES(1, 4);
INSERT INTO moviegenres(movieID, genreID) VALUES(1, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(1, 14);
INSERT INTO moviegenres(movieID, genreID) VALUES(2, 4);
INSERT INTO moviegenres(movieID, genreID) VALUES(2, 14);
INSERT INTO moviegenres(movieID, genreID) VALUES(2, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(2, 8);
INSERT INTO moviegenres(movieID, genreID) VALUES(2, 12);
INSERT INTO moviegenres(movieID, genreID) VALUES(3, 3);
INSERT INTO moviegenres(movieID, genreID) VALUES(3, 8);
INSERT INTO moviegenres(movieID, genreID) VALUES(4, 15);
INSERT INTO moviegenres(movieID, genreID) VALUES(4, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(5, 19);
INSERT INTO moviegenres(movieID, genreID) VALUES(6, 4);
INSERT INTO moviegenres(movieID, genreID) VALUES(6, 14);
INSERT INTO moviegenres(movieID, genreID) VALUES(7, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(7, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(7, 13);
INSERT INTO moviegenres(movieID, genreID) VALUES(7, 17);
INSERT INTO moviegenres(movieID, genreID) VALUES(8, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(8, 2);
INSERT INTO moviegenres(movieID, genreID) VALUES(9, 5);
INSERT INTO moviegenres(movieID, genreID) VALUES(9, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(9, 13);
INSERT INTO moviegenres(movieID, genreID) VALUES(9, 17);
INSERT INTO moviegenres(movieID, genreID) VALUES(10, 5);
INSERT INTO moviegenres(movieID, genreID) VALUES(10, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(10, 11);
INSERT INTO moviegenres(movieID, genreID) VALUES(11, 5);
INSERT INTO moviegenres(movieID, genreID) VALUES(12, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(12, 2);
INSERT INTO moviegenres(movieID, genreID) VALUES(12, 15);
INSERT INTO moviegenres(movieID, genreID) VALUES(13, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(13, 17);
INSERT INTO moviegenres(movieID, genreID) VALUES(13, 5);
INSERT INTO moviegenres(movieID, genreID) VALUES(13, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(14, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(14, 2);
INSERT INTO moviegenres(movieID, genreID) VALUES(14, 3);
INSERT INTO moviegenres(movieID, genreID) VALUES(14, 15);
INSERT INTO moviegenres(movieID, genreID) VALUES(15, 7);
INSERT INTO moviegenres(movieID, genreID) VALUES(16, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(16, 11);
INSERT INTO moviegenres(movieID, genreID) VALUES(16, 15);
INSERT INTO moviegenres(movieID, genreID) VALUES(17, 14);
INSERT INTO moviegenres(movieID, genreID) VALUES(17, 4);
INSERT INTO moviegenres(movieID, genreID) VALUES(18, 4);
INSERT INTO moviegenres(movieID, genreID) VALUES(18, 14);
INSERT INTO moviegenres(movieID, genreID) VALUES(19, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(19, 15);
INSERT INTO moviegenres(movieID, genreID) VALUES(20, 1);
INSERT INTO moviegenres(movieID, genreID) VALUES(20, 2);
INSERT INTO moviegenres(movieID, genreID) VALUES(20, 15);

-- DIRECTOR LINK
INSERT INTO moviedirectors(movieID, directorID) VALUES(1, 1);
INSERT INTO moviedirectors(movieID, directorID) VALUES(2, 2);
INSERT INTO moviedirectors(movieID, directorID) VALUES(3, 3);
INSERT INTO moviedirectors(movieID, directorID) VALUES(4, 4);
INSERT INTO moviedirectors(movieID, directorID) VALUES(5, 5);
INSERT INTO moviedirectors(movieID, directorID) VALUES(6, 6);
INSERT INTO moviedirectors(movieID, directorID) VALUES(7, 7);
INSERT INTO moviedirectors(movieID, directorID) VALUES(8, 8);
INSERT INTO moviedirectors(movieID, directorID) VALUES(9, 9);
INSERT INTO moviedirectors(movieID, directorID) VALUES(10, 10);
INSERT INTO moviedirectors(movieID, directorID) VALUES(11, 11);
INSERT INTO moviedirectors(movieID, directorID) VALUES(12, 12);
INSERT INTO moviedirectors(movieID, directorID) VALUES(13, 13);
INSERT INTO moviedirectors(movieID, directorID) VALUES(14, 14);
INSERT INTO moviedirectors(movieID, directorID) VALUES(15, 15);
INSERT INTO moviedirectors(movieID, directorID) VALUES(16, 16);
INSERT INTO moviedirectors(movieID, directorID) VALUES(17, 17);
INSERT INTO moviedirectors(movieID, directorID) VALUES(18, 1);
INSERT INTO moviedirectors(movieID, directorID) VALUES(19, 18);
INSERT INTO moviedirectors(movieID, directorID) VALUES(19, 19);
INSERT INTO moviedirectors(movieID, directorID) VALUES(20, 7);
INSERT INTO moviedirectors(movieID, directorID) VALUES(20, 20);

-- SESSIONES
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(1, 1, '2024-06-01 14:00:00', '2024-06-01 15:49:00', 109);
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(5, 2, '2024-06-03 10:00:00', '2024-06-03 11:54:00', 114);
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(13, 2, '2024-06-28 18:00:00', '2024-06-28 19:03:00', 123);
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(16, 5, '2024-07-14 20:00:00', '2024-07-14 21:04:00', 64);
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(11, 4, '2024-07-22 15:00:00', '2024-07-22 17:09:00', 129);
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(8, 3, '2024-08-01 12:00:00', '2024-08-01 13:56:00', 116);
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(6, 1, '2024-08-07 19:00:00', '2024-08-07 21:05:00', 125);

-- TICKETS
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(1, 1, 10.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(1, 2, 10.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(1, 14, 10.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(2, 36, 8.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(2, 37, 8.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(2, 10, 8.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(2, 11, 8.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(2, 44, 14.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(3, 7, 50.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(3, 8, 50.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(4, 111, 5.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(4, 222, 5.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(4, 333, 5.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(4, 444, 5.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(5, 224, 100.0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(6, 77, 54.6);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(7, 7, 20.4);

-- ********************************* CHECKING INSERTS *********************************
INSERT INTO movies(title, duration, release_date) VALUES('abc', -120, '2024-01-01');
INSERT INTO rooms(room_name, seat_capacity) VALUES('123', 0);
INSERT INTO tickets(sessionID, seat_nr, price) VALUES(1, 1, -10.0);

-- duration trigger check
INSERT INTO sessions(movieID, roomID, start_date, end_date, duration) VALUES(1, 1, '2024-06-01 14:00:00', '2024-06-01 16:00:00', 100);
SELECT * FROM sessions;
DELETE FROM sessions WHERE sessionID = 10;

-- mov deletion trigger check
DELETE FROM movies WHERE movieID = 1;
-- ********************************* DROP EVERYTHING *********************************
DROP VIEW moviegenres_linked;
DROP VIEW moviedirectors_linked;
DROP MATERIALIZED VIEW ticket_sales;

DROP TRIGGER session_duration_trigger;
DROP TRIGGER prevent_movie_deletion_trigger;
DROP FUNCTION update_session_duration;
DROP FUNCTION prevent_movie_deletion;

DROP TABLE moviedirectors;
DROP TABLE moviegenres;
DROP TABLE directors;
DROP TABLE genres;
DROP TABLE tickets;
DROP TABLE sessions;
DROP TABLE rooms;
DROP TABLE movies;

DROP INDEX sessmovid_index;
DROP INDEX unq_seat_index;