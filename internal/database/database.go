package database

import (
	"database/sql"
	"encoding/json"
	_ "github.com/mattn/go-sqlite3"
)

type Database struct {
	DB *sql.DB
}

type User struct {
	Username     string
	PasswordHash string
	Role         string
}

type Role struct {
	Name        string
	Permissions []string
}

type Permission struct {
	Name string
}

func NewDatabase(dbPath string) (*Database, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, err
	}
	return &Database{DB: db}, nil
}

// User CRUD
func (d *Database) GetUsers() ([]User, error) {
	rows, err := d.DB.Query("SELECT username, password_hash, role FROM users")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var users []User
	for rows.Next() {
		var u User
		if err := rows.Scan(&u.Username, &u.PasswordHash, &u.Role); err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, nil
}

func (d *Database) GetUser(username string) (*User, error) {
	row := d.DB.QueryRow("SELECT username, password_hash, role FROM users WHERE username = ?", username)
	var u User
	if err := row.Scan(&u.Username, &u.PasswordHash, &u.Role); err != nil {
		return nil, err
	}
	return &u, nil
}

func (d *Database) CreateUser(username, passwordHash, role string) error {
	_, err := d.DB.Exec("INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)", username, passwordHash, role)
	return err
}

func (d *Database) UpdateUser(username string, passwordHash *string, role *string) error {
	if passwordHash != nil && role != nil {
		_, err := d.DB.Exec("UPDATE users SET password_hash = ?, role = ? WHERE username = ?", *passwordHash, *role, username)
		return err
	} else if passwordHash != nil {
		_, err := d.DB.Exec("UPDATE users SET password_hash = ? WHERE username = ?", *passwordHash, username)
		return err
	} else if role != nil {
		_, err := d.DB.Exec("UPDATE users SET role = ? WHERE username = ?", *role, username)
		return err
	}
	return nil
}

func (d *Database) DeleteUser(username string) error {
	_, err := d.DB.Exec("DELETE FROM users WHERE username = ?", username)
	return err
}

// Role CRUD
func (d *Database) GetRoles() ([]Role, error) {
	rows, err := d.DB.Query("SELECT name, permissions_json FROM roles")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var roles []Role
	for rows.Next() {
		var r Role
		var permsJson string
		if err := rows.Scan(&r.Name, &permsJson); err != nil {
			return nil, err
		}
		if err := json.Unmarshal([]byte(permsJson), &r.Permissions); err != nil {
			return nil, err
		}
		roles = append(roles, r)
	}
	return roles, nil
}

func (d *Database) GetRole(name string) (*Role, error) {
	row := d.DB.QueryRow("SELECT name, permissions_json FROM roles WHERE name = ?", name)
	var r Role
	var permsJson string
	if err := row.Scan(&r.Name, &permsJson); err != nil {
		return nil, err
	}
	if err := json.Unmarshal([]byte(permsJson), &r.Permissions); err != nil {
		return nil, err
	}
	return &r, nil
}

func (d *Database) CreateRole(name string, permissions []string) error {
	permsJson, err := json.Marshal(permissions)
	if err != nil {
		return err
	}
	_, err = d.DB.Exec("INSERT INTO roles (name, permissions_json) VALUES (?, ?)", name, string(permsJson))
	return err
}

func (d *Database) UpdateRole(name string, permissions []string) error {
	permsJson, err := json.Marshal(permissions)
	if err != nil {
		return err
	}
	_, err = d.DB.Exec("UPDATE roles SET permissions_json = ? WHERE name = ?", string(permsJson), name)
	return err
}

func (d *Database) DeleteRole(name string) error {
	_, err := d.DB.Exec("DELETE FROM roles WHERE name = ?", name)
	return err
}

// Permission CRUD
func (d *Database) GetPermissions() ([]string, error) {
	rows, err := d.DB.Query("SELECT name FROM permissions")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var perms []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, err
		}
		perms = append(perms, name)
	}
	return perms, nil
}

func (d *Database) SetPermissions(perms []string) error {
	_, err := d.DB.Exec("DELETE FROM permissions")
	if err != nil {
		return err
	}
	for _, p := range perms {
		_, err := d.DB.Exec("INSERT INTO permissions (name) VALUES (?)", p)
		if err != nil {
			return err
		}
	}
	return nil
} 