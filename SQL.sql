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

DELIMITER //
CREATE TRIGGER prevent_self_follow
BEFORE INSERT ON Follows
FOR EACH ROW
BEGIN
IF NEW.follower = NEW.following THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'A user cannot follow themselves.';
END IF;
END;
//

DELIMITER //
CREATE TRIGGER update_book_avg_rating
AFTER INSERT ON Review
FOR EACH ROW
BEGIN
UPDATE Book
SET avg_rating = (
SELECT ROUND(AVG(rating), 2)
FROM Review
WHERE isbn = NEW.isbn
)
WHERE isbn = NEW.isbn;
END;
//


DELIMITER //
CREATE PROCEDURE AddBook (
IN p_isbn VARCHAR(20),
IN p_title VARCHAR(200),
IN p_author VARCHAR(100),
IN p_pub_date DATE,
IN p_genres VARCHAR(200),
IN p_cover TEXT,
IN p_avg_rating DECIMAL(3,2)
)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
SELECT 'Error occurred. Book not added.' AS ErrorMessage;
ROLLBACK;
END;
START TRANSACTION;
INSERT INTO Book (isbn, title, author, pub_date, genres, cover, avg_rating)
VALUES (p_isbn, p_title, p_author, p_pub_date, p_genres, p_cover, p_avg_rating);
COMMIT;
END;
//
mysql> CALL AddBook(
    -> '9780140449266',
    -> 'The Iliad',
    -> 'Homer',
    -> '2003-11-29',
    -> 'Classic, Epic',
    -> 'https://example.com/iliad.jpg',
    -> 4.5
    -> );

SELECT * FROM Book WHERE isbn = '9780140449266';

DELIMITER //
CREATE PROCEDURE DeleteReviewAndUpdateRating (
IN p_username VARCHAR(50),
IN p_isbn VARCHAR(20)
)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
SELECT 'Error occurred while deleting review.' AS ErrorMessage;
ROLLBACK;
END;
START TRANSACTION;
DELETE FROM Review
WHERE username = p_username AND isbn = p_isbn;
UPDATE Book
SET avg_rating = (
SELECT IFNULL(ROUND(AVG(rating), 2), 0)
FROM Review
WHERE isbn = p_isbn
)
WHERE isbn = p_isbn;
COMMIT;
END;
//

CALL DeleteReviewAndUpdateRating('bob', '9780140449266');
SELECT title, avg_rating FROM Book WHERE isbn = '9780140449266';

DELIMITER //
CREATE FUNCTION GetUserAvgRating(p_username VARCHAR(50))
RETURNS DECIMAL(3,2)
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE avg_rating DECIMAL(3,2);

SELECT ROUND(AVG(rating), 2)
INTO avg_rating
FROM Review
WHERE username = p_username;

RETURN IFNULL(avg_rating, 0.0);
END;
//

DELIMITER //
CREATE FUNCTION GetBooksReadCount(p_username VARCHAR(50))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE book_count INT;
SELECT COUNT(*) INTO book_count
FROM UserLibrary
WHERE username = p_username AND status = 'read';
RETURN book_count;
END;
//
DELIMITER ;

#join
SELECT B.title, UL.status FROM UserLibrary UL
JOIN Book B ON UL.isbn = B.isbn
WHERE UL.username = 'alice';

#aggregate
DELIMITER ;
SELECT DISTINCT B.title
FROM Follows F
JOIN Review R ON F.following = R.username
JOIN Book B ON R.isbn = B.isbn
WHERE F.follower = 'alice'
AND R.rating >= 4
AND NOT EXISTS (
SELECT 1
FROM UserLibrary UL
WHERE UL.username = 'alice' AND UL.isbn = R.isbn AND UL.status = 'read'
);

#nested 
SELECT B.title, ROUND(AVG(R.rating), 2) AS avg_rating
FROM Book B
JOIN Review R ON B.isbn = R.isbn
GROUP BY B.title;
