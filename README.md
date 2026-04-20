# 📚 Personal Library System

A robust book management and social library platform developed using **Python** and **MySQL**. This system allows users to track their reading progress, review books, and follow other users for community-driven recommendations.

---

## 📌 Overview

The **Personal Library System** is a command-line interface (CLI) application that manages a comprehensive database of books and users. It features an integrated social mechanism where followers' top-rated books are suggested as recommendations. The backend leverages advanced SQL features like **Triggers**, **Stored Procedures**, and **Functions** to maintain data integrity and handle complex business logic.

---

## ✨ Features

- **Authentication System**: Secure login for both standard Users and Administrators.
- **Library Management**: Track books as 'None', 'Want to Read', 'Currently Reading', or 'Read'.
- **Interactive Reviews**: Write, update, and view book reviews with numeric ratings (1-5).
- **Social Networking**: Follow other users to see their activity and influence your recommendations.
- **Smart Recommendations**: A nested SQL query system that suggests books based on high ratings (4+) from users you follow.
- **Aggregated Statistics**: View your average rating and total books read using user-defined SQL functions.
- **Admin Dashboard**: Specialized tools for administrators to add/delete books and manage the user base.
- **Data Integrity**: Automated average rating updates via SQL triggers and transactional procedures.

---

## 🏗️ Project Architecture

### Database Schema (MySQL)
- **User**: Stores user profiles, credentials, and admin status.
- **Book**: Catalog of books with metadata and automated average ratings.
- **UserLibrary**: Maps users to books with their specific reading status.
- **Review**: Stores user-generated ratings and text reviews.
- **Follows**: Manages the social graph between users.

### Advanced SQL Components
- **Triggers**: 
  - `prevent_self_follow`: Ensures users cannot follow themselves.
  - `update_book_avg_rating`: Automatically recalculates a book's average rating whenever a new review is added.
- **Stored Procedures**:
  - `AddBook`: Safely adds new books using transactions.
  - `DeleteReviewAndUpdateRating`: Removes a review and updates the book's rating in a single atomic action.
- **Functions**:
  - `GetUserAvgRating`: Calculates the mean rating given by a specific user.
  - `GetBooksReadCount`: Returns the total number of books a user has completed.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Python 3.x |
| **Database** | MySQL |
| **Library** | `mysql-connector-python` |

---

## 🚀 Setup & Installation

### 1. Database Configuration
1. Ensure you have **MySQL Server** installed and running.
2. Open your MySQL client (e.g., MySQL Workbench or CLI).
3. Execute the contents of the `SQL.sql` script to create the `booksystem` database, tables, and seed data:
   ```sql
   SOURCE path/to/SQL.sql;
   ```

### 2. Python Setup
1. Navigate to the project directory:
   ```bash
   cd Personal-Library-System-main
   ```
2. Install the required Python library:
   ```bash
   pip install -r requirements.txt
   ```

### 3. Application Configuration
Open `ui.py` and update the `DB_CONFIG` dictionary with your local MySQL credentials:
```python
DB_CONFIG = {
    'host': 'localhost',
    'user': 'your_mysql_username',
    'password': 'your_mysql_password',
    'database': 'booksystem'
}
```

---

## 🎮 How to Run

Launch the application using:
```bash
python ui.py
```

### Demo Credentials (from SQL seed)
| Email | Password | Role |
|---|---|---|
| `alice@example.com` | `alice123` | User |
| `bob@example.com` | `bob123` | User |

*(Note: To test Admin features, manually set the `isAdmin` flag to 1 for a user in the database.)*

---

