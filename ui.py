import mysql.connector
import getpass

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'booksystem'
}

conn = mysql.connector.connect(**DB_CONFIG)
cursor = conn.cursor(dictionary=True)

def login():
    email = input("Email: ").strip()
    password = getpass.getpass("Password: ").strip()
    if not email or not password:
        print("❌ Email and password cannot be empty.")
        return None

    cursor.execute(
        "SELECT username, isAdmin FROM User WHERE email=%s AND password=%s",
        (email, password)
    )
    result = cursor.fetchone()
    if result:
        print(f"\n✅ Logged in as {result['username']} ({'Admin' if result['isAdmin'] else 'User'})")
        return result
    else:
        print("❌ Invalid credentials.")
        return None


def main_menu():
    while True:
        print("\n--- MAIN MENU ---")
        print("1. Login")
        print("0. Exit")
        choice = input("Select: ").strip()
        if choice == '1':
            user = login()
            if user:
                user_menu(user['username'], user['isAdmin'])
        elif choice == '0':
            break


def user_menu(username, is_admin):
    while True:
        print("\n--- USER MENU ---")
        print("1. View My Reviews")
        print("2. View Average Rating (Aggregate Query)")
        print("3. Books Marked as 'Read'")
        print("4. View Followers")
        print("5. View Following")
        print("6. Follow a User")  # 🆕 NEW FEATURE
        print("7. Write or Update Review")
        print("8. View Recommendations (Nested Query)")
        print("9. View To-Be-Read List")
        print("10. View My Library (Join Query)")
        if is_admin:
            print("11. Add Book (Admin)")
            print("12. Delete Book (Admin)")
            print("13. View All Users")
        print("0. Logout")

        choice = input("Select: ").strip()

        # 1️⃣ View Reviews
        if choice == '1':
            cursor.execute("SELECT isbn, rating, review, timestamp FROM Review WHERE username=%s", (username,))
            results = cursor.fetchall()
            if results:
                for r in results:
                    print(f"Book {r['isbn']} | Rating: {r['rating']} | {r['review']} | {r['timestamp']}")
            else:
                print("No reviews yet.")

        # 2️⃣ Aggregate: Average Rating
        elif choice == '2':
            cursor.execute("SELECT GetUserAvgRating(%s) AS avg", (username,))
            print("📊 Average Rating Given:", cursor.fetchone()['avg'])

        # 3️⃣ Books marked as 'Read' from Library
        elif choice == '3':
            cursor.execute("""
                SELECT B.title, B.author 
                FROM UserLibrary UL
                JOIN Book B ON UL.isbn = B.isbn
                WHERE UL.username=%s AND UL.status='Read'
            """, (username,))
            results = cursor.fetchall()
            if results:
                for b in results:
                    print(f"{b['title']} by {b['author']}")
            else:
                print("No books marked as Read.")

        # 4️⃣ Followers
        elif choice == '4':
            cursor.execute("SELECT follower FROM Follows WHERE following=%s", (username,))
            followers = [f['follower'] for f in cursor.fetchall()]
            print("Followers:", followers if followers else "No followers yet.")

        # 5️⃣ Following
        elif choice == '5':
            cursor.execute("SELECT following FROM Follows WHERE follower=%s", (username,))
            following = [f['following'] for f in cursor.fetchall()]
            print("Following:", following if following else "Not following anyone yet.")

        # 🆕 6️⃣ Follow Another User (Demonstrates Trigger)
        elif choice == '6':
            target_user = input("Enter the username you want to follow: ").strip()
            if not target_user:
                print("❌ Username cannot be empty.")
                continue
            try:
                cursor.execute("INSERT INTO Follows (follower, following) VALUES (%s, %s)", (username, target_user))
                conn.commit()
                print(f"✅ You are now following {target_user}!")
            except mysql.connector.Error as e:
                if "A user cannot follow themselves" in str(e):
                    print("❌ You cannot follow yourself. (Trigger Fired)")
                elif "Duplicate entry" in str(e):
                    print("⚠️ You already follow this user.")
                else:
                    print("⚠️ Error:", e)

        # 7️⃣ Write or Update Review
        elif choice == '7':
            isbn = input("Enter ISBN: ").strip()
            rating = input("Rating (1-5): ").strip()
            review = input("Review: ").strip()
            if not (isbn and rating and review):
                print("❌ ISBN, rating, and review cannot be empty.")
                continue

            try:
                cursor.execute("SELECT review_id FROM Review WHERE username=%s AND isbn=%s", (username, isbn))
                existing = cursor.fetchone()
                if existing:
                    cursor.execute("""
                        UPDATE Review 
                        SET rating=%s, review=%s, timestamp=NOW()
                        WHERE username=%s AND isbn=%s
                    """, (rating, review, username, isbn))
                    print("🔁 Review updated successfully.")
                else:
                    cursor.execute("""
                        INSERT INTO Review (username, isbn, rating, review, timestamp)
                        VALUES (%s, %s, %s, %s, NOW())
                    """, (username, isbn, rating, review))
                    print("✅ New review added.")
                conn.commit()
            except mysql.connector.Error as e:
                print("⚠️ Error:", e)

        # 8️⃣ Nested Query: Recommendations
        elif choice == '8':
            cursor.execute("""
                SELECT DISTINCT B.title FROM Book B
                JOIN Review R ON B.isbn = R.isbn
                JOIN Follows F ON F.following = R.username
                WHERE F.follower = %s AND R.rating >= 4
                AND NOT EXISTS (
                    SELECT 1 FROM UserLibrary UL
                    WHERE UL.username = %s AND UL.isbn = B.isbn AND UL.status = 'Read'
                )
            """, (username, username))
            recs = [r['title'] for r in cursor.fetchall()]
            print("📚 Recommended Books:", recs if recs else "No recommendations yet.")

        # 9️⃣ To-Be-Read Books
        elif choice == '9':
            cursor.execute("""
                SELECT B.title FROM UserLibrary UL
                JOIN Book B ON UL.isbn = B.isbn
                WHERE UL.username = %s AND UL.status = 'Want to Read'
            """, (username,))
            books = [b['title'] for b in cursor.fetchall()]
            print("📖 To-Be-Read List:", books if books else "No books in 'Want to Read' list.")

        # 🔟 Join Query: Library
        elif choice == '10':
            cursor.execute("""
                SELECT B.title, UL.status 
                FROM UserLibrary UL
                JOIN Book B ON UL.isbn = B.isbn
                WHERE UL.username = %s
            """, (username,))
            for row in cursor.fetchall():
                print(f"{row['title']} — {row['status']}")

        # 11️⃣ Admin: Add Book
        elif is_admin and choice == '11':
            isbn = input("ISBN: ").strip()
            title = input("Title: ").strip()
            author = input("Author: ").strip()
            pub = input("Pub Date (YYYY-MM-DD): ").strip()
            genres = input("Genres: ").strip()
            if not all([isbn, title, author, pub, genres]):
                print("❌ All fields are required.")
                continue
            cursor.execute("""
                INSERT IGNORE INTO Book (isbn, title, author, pub_date, genres, avg_rating)
                VALUES (%s, %s, %s, %s, %s, 0.00)
            """, (isbn, title, author, pub, genres))
            conn.commit()
            print("✅ Book added successfully.")

        # 12️⃣ Admin: Delete Book
        elif is_admin and choice == '12':
            isbn = input("ISBN to delete: ").strip()
            cursor.execute("DELETE FROM Book WHERE isbn=%s", (isbn,))
            conn.commit()
            print("✅ Book deleted (if existed).")

        # 13️⃣ Admin: View All Users
        elif is_admin and choice == '13':
            cursor.execute("SELECT username, email, isAdmin FROM User")
            for row in cursor.fetchall():
                print(row)

        elif choice == '0':
            break
        else:
            print("❌ Invalid choice. Try again.")


if __name__ == '__main__':
    try:
        main_menu()
    finally:
        cursor.close()
        conn.close()
