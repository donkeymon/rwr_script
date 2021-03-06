// internal
#include "task_sequencer.as"
#include "query_helpers.as"

// --------------------------------------------
class AnnounceTask : Task {
	protected Metagame@ m_metagame;
	protected int m_factionId;
	protected string m_key;
	protected dictionary m_a;
	protected float m_time;
	protected float m_priority;

	// announcements are considered high priority, with default 1.0 priority the message will be shown regardless of user setting for
	// commander muting or commander_ai reports setting
	// - especially useful for providing commander briefing at the start of the match, by making reports muted with 0.0 setting and using priority 1.0 here
	AnnounceTask(Metagame@ metagame, float time, int factionId, string key, dictionary@ a = dictionary(), float priority = 1.0) {
		@m_metagame = metagame;
		m_factionId = factionId;
		m_key = key;
		m_a = a;
		m_time = time;
		m_priority = priority;
	}

	// --------------------------------------------
	void start() {
		sendFactionMessageKey(m_metagame, m_factionId, m_key, m_a, m_priority);
	}

	// --------------------------------------------
	void update(float time) {
		m_time -= time;
	}

	// --------------------------------------------
	bool hasEnded() const {
		return m_time < 0.0f;
	}
}
