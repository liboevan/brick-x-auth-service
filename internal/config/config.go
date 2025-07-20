package config

import (
	"encoding/json"
	"os"
)

type Config struct {
	Server ServerConfig `json:"server"`
	JWT    JWTConfig    `json:"jwt"`
}

type ServerConfig struct {
	Port int `json:"port"`
}

type JWTConfig struct {
	PrivateKeyPath string `json:"private_key_path"`
	PublicKeyPath  string `json:"public_key_path"`
	Expiration     int    `json:"expiration_hours"`
}

func Load() (*Config, error) {
	config := &Config{
		Server: ServerConfig{Port: 17101},
		JWT: JWTConfig{
			PrivateKeyPath: "/app/private.pem",
			PublicKeyPath:  "/app/public.pem",
			Expiration:     24,
		},
	}
	// 优先 /etc/brick-x-auth/config.json
	if _, err := os.Stat("/etc/brick-x-auth/config.json"); err == nil {
		file, err := os.Open("/etc/brick-x-auth/config.json")
		if err != nil {
			return nil, err
		}
		defer file.Close()
		if err := json.NewDecoder(file).Decode(config); err != nil {
			return nil, err
		}
		return config, nil
	}
	// fallback /app/configs/config.json
	if _, err := os.Stat("/app/configs/config.json"); err == nil {
		file, err := os.Open("/app/configs/config.json")
		if err != nil {
			return nil, err
		}
		defer file.Close()
		if err := json.NewDecoder(file).Decode(config); err != nil {
			return nil, err
		}
	}
	return config, nil
} 