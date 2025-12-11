# DVWA Attack Surface Demo Guide

This guide outlines how to demonstrate three critical web application vulnerabilities on your local DVWA instance.

## ⚠️ Prerequisites
1. Ensure the app is running: `http://127.0.0.1:<PORT>`
2. Log in with default credentials:
   - **Username**: `admin`
   - **Password**: `password`
3. **CRITICAL**: Go to **DVWA Security** on the left menu, set the Security Level to **Low**, and click **Submit**.

---

## 1. SQL Injection (Login Bypass)
**Goal**: Log in as a user without knowing their password.

### Vulnerability Explanation
The application constructs a database query by directly concatenating user input without validation or parameterization. This allows an attacker to manipulate the SQL logic.

### Steps
1. Navigate to **SQL Injection** on the left menu.
2. In the **User ID** text box, enter the following payload:
   ```sql
   %' OR '1'='1
   ```
   *Alternative Payload (for raw login page)*: `admin' OR '1'='1' #`
3. Click **Submit**.

### verification
- **Expected Result**: You should see a list of ALL users in the database (admin, gordonb, etc.), not just one.
- **Why?**: The query becomes `SELECT * FROM users WHERE user_id = '%' OR '1'='1'`. Since `'1'='1'` is always true, the database returns every row.

---

## 2. Reflected XSS (Cross-Site Scripting)
**Goal**: Execute malicious JavaScript in the victim's browser.

### Vulnerability Explanation
The application takes user input and "reflects" it back to the page HTML without proper escaping or sanitization. The browser interprets the input as executable code (script) rather than text.

### Steps
1. Navigate to **XSS (Reflected)** on the left menu.
2. In the **What's your name?** text box, enter:
   ```html
   <script>alert('AccuKnox')</script>
   ```
3. Click **Submit**.

### Verification
- **Expected Result**: A browser alert popup appears with the text "AccuKnox".
- **Why?**: The server echoed `<script>alert...</script>` directly into the HTML response. The browser parsed the `<script>` tag and executed the JavaScript.

---

## 3. Command Injection
**Goal**: Execute arbitrary system commands on the server.

### Vulnerability Explanation
The application takes user input (intended for an IP address) and passes it directly to a system shell command (like `ping`) without validating that it is *only* an IP address.

### Steps
1. Navigate to **Command Injection** on the left menu.
2. In the **Enter an IP address** text box, enter:
   ```bash
   127.0.0.1 && dir
   ```
   *(Note: On Linux containers, use `127.0.0.1 && ls`)*
3. Click **Submit**.

### Verification
- **Expected Result**: You will see the ping output followed by the directory listing (`index.php`, `source.php`, etc.).
- **Why?**: The `&&` operator chains commands. The server executed `ping 127.0.0.1` AND THEN executed `dir` (or `ls`), returning the output of both.
