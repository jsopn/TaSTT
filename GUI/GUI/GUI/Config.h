#pragma once

#include "ryml.h"

#include <filesystem>

// Represents a disk-backed configuration. Knows how to save to disk
// (Serialize) and restore from disk (Deserialize).
class Config {
public:
	virtual ~Config() {}

	virtual bool Serialize(const std::filesystem::path& path) = 0;

	virtual bool Deserialize(const std::filesystem::path& path) = 0;

protected:
	virtual bool Serialize(const std::filesystem::path& path,
		const ryml::Tree* t);

	virtual bool Deserialize(const std::filesystem::path& path,
		ryml::Tree* t);
};

// Represents the configurable fields for the GUI. Used by both the
// Transcription panel and the Unity panel.
class AppConfig : public Config {
public:
	virtual ~AppConfig() {}

	AppConfig();

	bool Serialize(const std::filesystem::path& path) override;

	bool Deserialize(const std::filesystem::path& path) override;

	// The default path at which configs are serialized.
	static constexpr char kConfigPath[] = "Resources/app_config.yml";

	// Transcription-specific settings.
	std::string microphone;
	std::string language;
	std::string model;
	std::string button;
	std::string window_duration;

	bool enable_local_beep;
	bool use_cpu;
	bool use_builtin;

	// Unity and transcription shared settings.
	int chars_per_sync;
	int bytes_per_char;
	int rows;
	int cols;

	// Unity-specific settings.
	std::string assets_path;
	std::string fx_path;
	std::string params_path;
	std::string menu_path;
	bool clear_osc;
};

