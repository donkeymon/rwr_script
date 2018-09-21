#include "helpers.as"

// --------------------------------------------
class UserSettings {
	// true -> script is started in continue mode i.e. the script is expected to load its own saved state
	// false -> starting the game mode from scratch
	bool m_continue = false;

	string m_startServerCommand = "";

	// --------------------------------------------
	// comes in from game menu, or, defaults are used
	// --------------------------------------------
	string m_savegame = ""; // map rotator needs to feed this back to game
	string m_username = "SINGLE PLAYER";

	float m_fellowCapacityFactor = 1.05;
	float m_fellowAiAccuracyFactor = 0.94;
	float m_enemyCapacityFactor = 1.0;
	float m_enemyAiAccuracyFactor = 0.94;
	float m_xpFactor = 0.27;
	float m_rpFactor = 1.0;
	int m_factionChoice = 0;

	// --------------------------------------------
	// support for input from game menu doesn't exist for these, defaults are used
	// --------------------------------------------
	bool m_completionVarianceEnabled = true;
	bool m_friendlyFire = false;
	float m_initialXp = 0.0;
	float m_initialRp = 0.0;
	float m_maxRp = -1.0; // negative means not used
	// 1.0 -> 8 for most maps, less for others
	float m_playerAiCompensationFactor = 1.0;
	float m_playerAiReduction = 0;
	string m_baseCaptureSystem = "any"; // could be single for backdoor prevention, not really that useful in invasion
	// when a campaign becomes complete, the menu offers to restart it with different settings while preserving the player profile,
	// this is true when a new campaign is started that way
	bool m_continueAsNewCampaign;

	// dedicated servers only
	bool m_teamKillPenaltyEnabled = true;
	int m_teamKillsToStartPenalty = 5;
	float m_teamKillPenaltyTime = 1800.0;
	float m_forgiveTeamKillTime = 900.0;

	array<string> m_overlayPaths;

	// --------------------------------------------
	void fromXmlElement(const XmlElement@ settings) {
		if (settings.hasAttribute("continue")) {
			m_continue = settings.getBoolAttribute("continue");

		} else {
			// extract settings coming from game 
			// and store to provide them for other components, mostly

			m_savegame = settings.getStringAttribute("savegame");
			m_username = settings.getStringAttribute("username");
			m_factionChoice = settings.getIntAttribute("faction_choice");

			m_fellowCapacityFactor = settings.getFloatAttribute("fellow_capacity");
			m_fellowAiAccuracyFactor = settings.getFloatAttribute("fellow_ai_accuracy");
			m_enemyCapacityFactor = settings.getFloatAttribute("enemy_capacity");
			m_enemyAiAccuracyFactor = settings.getFloatAttribute("enemy_ai_accuracy");
			m_xpFactor = settings.getFloatAttribute("xp_factor");
			m_rpFactor = settings.getFloatAttribute("rp_factor");

			if (settings.hasAttribute("initial_xp")) {
				m_initialXp = settings.getFloatAttribute("initial_xp");
			}

			if (settings.hasAttribute("initial_rp")) {
				m_initialRp = settings.getFloatAttribute("initial_rp");
			}

			if (settings.hasAttribute("max_rp")) {
				m_maxRp = settings.getFloatAttribute("max_rp");
			}

			// Let's play -support
			if (settings.hasAttribute("headstart") && settings.getIntAttribute("headstart") != 0) {
				m_initialXp = 0.3;
				m_initialRp = 500;
			}

			if (settings.hasAttribute("continue_as_new_campaign") && settings.getIntAttribute("continue_as_new_campaign") != 0) {
				m_continueAsNewCampaign = true;
			}
		}
	}

	// --------------------------------------------
	XmlElement@ toXmlElement(string name) const {
		// NOTE, won't serialize continue keyword, it only works as input

		XmlElement settings(name);

		settings.setStringAttribute("savegame", m_savegame);
		settings.setStringAttribute("username", m_username);
		settings.setIntAttribute("faction_choice", m_factionChoice);

		settings.setFloatAttribute("fellow_capacity", m_fellowCapacityFactor);
		settings.setFloatAttribute("fellow_ai_accuracy", m_fellowAiAccuracyFactor);
		settings.setFloatAttribute("enemy_capacity", m_enemyCapacityFactor);
		settings.setFloatAttribute("enemy_ai_accuracy", m_enemyAiAccuracyFactor);
		settings.setFloatAttribute("xp_factor", m_xpFactor);
		settings.setFloatAttribute("rp_factor", m_rpFactor);

		settings.setFloatAttribute("initial_xp", m_initialXp);
		settings.setFloatAttribute("initial_rp", m_initialRp);

		settings.setFloatAttribute("max_rp", m_maxRp);

		return settings;
	}

	// --------------------------------------------
	void print() const {
		_log(" * using savegame name: " + m_savegame);
		_log(" * using username: " + m_username);
		_log(" * using faction choice: " + m_factionChoice);

		// we can use this to provide difficulty settings, user faction, etc
		_log(" * using fellow capacity: " + m_fellowCapacityFactor);
		_log(" * using fellow ai accuracy: " + m_fellowAiAccuracyFactor);
		_log(" * using enemy capacity: " + m_enemyCapacityFactor);
		_log(" * using enemy ai accuracy: " + m_enemyAiAccuracyFactor);
		_log(" * using xp factor: " + m_xpFactor);
		_log(" * using rp factor: " + m_rpFactor);

		_log(" * using initial xp: " + m_initialXp);
		_log(" * using initial rp: " + m_initialRp);

		_log(" * using max rp: " + m_maxRp);
	}

};
