CREATE DATABASE booksystem;
USE booksystem;

CREATE TABLE User (
    username VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    isAdmin BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (username)
);

CREATE TABLE Book (
    isbn VARCHAR(20) NOT NULL,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100) NOT NULL,
    pub_date DATE NOT NULL,
    genres VARCHAR(200) NOT NULL,
    avg_rating DECIMAL(3,2) NOT NULL DEFAULT 0.00 CHECK (avg_rating >= 0.00 AND avg_rating <= 5.00),
    cover VARCHAR(500) DEFAULT NULL,
    PRIMARY KEY (isbn)
);

CREATE TABLE UserLibrary (
    username VARCHAR(50) NOT NULL,
    isbn VARCHAR(20) NOT NULL,
    status ENUM('None', 'Want to Read', 'Currently Reading', 'Read') NOT NULL DEFAULT 'None',
    PRIMARY KEY (username, isbn),
    FOREIGN KEY (username) REFERENCES User(username)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (isbn) REFERENCES Book(isbn)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Review (
    review_id INT AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    isbn VARCHAR(20) NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id),
    FOREIGN KEY (username) REFERENCES User(username)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (isbn) REFERENCES Book(isbn)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Follows (
    follower VARCHAR(50) NOT NULL,
    following VARCHAR(50) NOT NULL,
    PRIMARY KEY (follower, following),
    FOREIGN KEY (follower) REFERENCES User(username)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (following) REFERENCES User(username)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER prevent_self_follow
BEFORE INSERT ON Follows
FOR EACH ROW
BEGIN
    IF NEW.follower = NEW.following THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A user cannot follow themselves';
    END IF;
END;
//
DELIMITER ;

INSERT INTO User (username, name, email, password) VALUES
('alice', 'Alice Johnson', 'alice@example.com', 'alice123'),
('bob', 'Bob Smith', 'bob@example.com', 'bob123'),
('charlie', 'Charlie Brown', 'charlie@example.com', 'charlie123'),
('diana', 'Diana Prince', 'diana@example.com', 'diana123'),
('edward', 'Edward Elric', 'edward@example.com', 'edward123');

INSERT INTO Book (isbn, title, author, pub_date, genres, avg_rating, cover) VALUES
('9781250854513', 'The Atlas Six', 'Olivie Blake', '2022-03-01', 'Fantasy, Dark Academia', 4.2, 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1714503138i/50520939.jpg'),
('9781984806758', 'People We Meet on Vacation', 'Emily Henry', '2021-05-11', 'Romance, Contemporary', 4.0, 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1748450140i/54985743.jpg'),
('9781534457690', 'These Violent Delights', 'Chloe Gong', '2020-11-17', 'Fantasy, Historical, Romance', 4.1, 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1580958058i/50892212.jpg'),
('9781649374042', 'Fourth Wing', 'Rebecca Yarros', '2023-05-02', 'Fantasy, Romance', 4.6, 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1701980900i/61431922.jpg'),
('9780063021426', 'Babel', 'R.F. Kuang', '2022-08-23', 'Fantasy, Historical, Dark Academia', 4.4, 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1677361825i/57945316.jpg');

INSERT INTO UserLibrary (username, isbn, status) VALUES
('alice', '9781250854513', 'Currently Reading'),
('alice', '9781984806758', 'Want to Read'),
('bob', '9781534457690', 'Read'),
('charlie', '9781649374042', 'Currently Reading'),
('diana', '9780063021426', 'Want to Read'),
('edward', '9781250854513', 'Read'),
('bob', '9781649374042', 'Want to Read'),
('charlie', '9781984806758', 'Read'),
('diana', '9781534457690', 'Currently Reading'),
('edward', '9780063021426', 'Currently Reading');

INSERT INTO Review (review_id, username, isbn, rating, review) VALUES
(1, 'alice', '9781250854513', 5, 'Loved the atmosphere and characters!'),
(2, 'bob', '9781534457690', 4, 'Unique twist on Romeo and Juliet.'),
(3, 'charlie', '9781984806758', 3, 'Lighthearted but predictable.'),
(4, 'diana', '9780063021426', 5, 'Masterpiece of dark academia.'),
(5, 'edward', '9781649374042', 5, 'So gripping I couldn’t put it down.');


INSERT INTO Follows (follower, following) VALUES
('alice', 'bob'),
('bob', 'charlie'),
('charlie', 'diana'),
('diana', 'edward'),
('edward', 'alice');