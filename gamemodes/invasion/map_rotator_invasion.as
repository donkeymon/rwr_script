// internal
#include "tracker.as"
#include "map_info.as"
#include "log.as"
#include "announce_task.as"
#include "generic_call_task.as"
#include "time_announcer_task.as"

// generic trackers
#include "map_rotator.as"
#include "spawner.as"
#include "destroy_vehicle_to_capture_base.as"

// gamemode specific
#include "overtime.as"
#include "peaceful_last_base.as"
#include "stage_invasion.as"
#include "world.as"
#include "faction_config.as"
#include "stage_configurator.as"

// --------------------------------------------
class MapRotatorInvasion : MapRotator {
	protected GameModeInvasion@ m_metagame;
	protected array<Stage@> m_stages;
	protected int m_currentStageIndex;
	protected int m_nextStageIndex;
	protected array<int> m_stagesCompleted;
	protected bool m_loop;
	protected World@ m_world;
	protected array<FactionConfig@> m_factionConfigs;
	protected StageConfigurator@ m_configurator;

	// --------------------------------------------
	MapRotatorInvasion(GameModeInvasion@ metagame) {
		super();

		@m_metagame = metagame;

		m_currentStageIndex = 0;
		m_nextStageIndex = 0;
		m_loop = true;
	}

	// --------------------------------------------
	void setConfigurator(StageConfigurator@ configurator) {
		@m_configurator = @configurator;
	}

	// --------------------------------------------
	void setLoop(bool loop) {
		m_loop = loop;
	}

	// --------------------------------------------
	void init() {
		MapRotator::init();

		m_configurator.setup();

		m_nextStageIndex = m_currentStageIndex;
	}

	// --------------------------------------------
	const array<FactionConfig@>@ getFactionConfigs() {
		return m_factionConfigs;
	}

	// --------------------------------------------
	void addStage(Stage@ stage) {
		m_stages.insertLast(stage);
	}

	// --------------------------------------------
	void addFactionConfig(FactionConfig@ config) {
		m_factionConfigs.push_back(config);
	}

	// --------------------------------------------
	void setWorld(World@ world) {
		@m_world = @world;
	}

	// --------------------------------------------
	// --------------------------------------------
	// --------------------------------------------
	// --------------------------------------------
	// --------------------------------------------
	protected void handleFactionLoseEvent(const XmlElement@ event) {
		// if green lost a battle, start over
		int factionId = -1;

		const XmlElement@ loseCondition = event.getFirstElementByTagName("lose_condition");
		if (loseCondition !is null) {
			factionId = loseCondition.getIntAttribute("faction_id");
		} else {
			_log("WARNING, couldn't find lose_condition tag", -1);
		}

		if (factionId == 0) {
			// friendly faction lost, restart the map
			waitAndStart(10, false);		
		}
	}

	// -------------------------------------------------------
	protected void commitToMapChange(int index) {
		_log("commit_to_map_change, index=" + index, 1);

		// commit to this map change
		m_nextStageIndex = index;
		waitAndStartAtMapChangeCommit();	
	}

	// -------------------------------------------------------
	protected void waitAndStartAtMapChangeCommit() {
		waitAndStart(30, true);
	}

	// -------------------------------------------
	protected void waitAndStart(float time = 30, bool sayCountdown = true) {
		int previousStageIndex = m_currentStageIndex;

		// share some information with the server (and thus clients)
		int index = getNextStageIndex();
		string mapName = getMapName(index);

		_log("previous stage index " + previousStageIndex + ", next stage index " + index);
		if (previousStageIndex != index) {
			// show appropriate transport arrows in map now, if map is about to change
			if (m_world !is null) {
				m_world.setAdvance(m_stages[previousStageIndex].m_mapInfo.m_id, m_stages[index].m_mapInfo.m_id);

				// make next stage visible now, at latest
				m_stages[index].m_hidden = false;
				m_world.refresh(m_stages, m_stagesCompleted, previousStageIndex);
			}

			// announce map advance in dialog
			announceMapAdvance(index);
		} else {
			// same map
		}

		// wait a while, and let server announce a few things
		m_metagame.getTaskSequencer().add(TimeAnnouncerTask(m_metagame, time, sayCountdown));

		if (previousStageIndex != index) {
			// also save
			m_metagame.getTaskSequencer().add(Call(CALL(m_metagame.save)));

			// start new map
			m_metagame.getTaskSequencer().add(CallInt(CALL_INT(this.startMapEx), index));
		} else {
			// restart same map
			m_metagame.getTaskSequencer().add(Call(CALL(this.restartMap)));
		}
	}

	// --------------------------------------------
	protected void setStageCompleted(int index) {
		if (!isStageCompleted(index)) {
			m_stagesCompleted.insertLast(index);
		}
	}

	// --------------------------------------------
	protected bool isStageCompleted(int index) const {
		return m_stagesCompleted.find(index) >= 0;
	}

	// --------------------------------------------
	protected int getNumberOfCompletedStages() const {
		return m_stagesCompleted.size();
	}

	// --------------------------------------------
	protected bool isCampaignCompleted() const {
		return getNumberOfCompletedStages() == getStageCount();
	}

	// --------------------------------------------
	protected void resetStagesCompleted() {
		m_stagesCompleted.clear();
	}

	// --------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		// prepare for lost battle, grey won
		int factionId = 1;

		const XmlElement@ winCondition = event.getFirstElementByTagName("win_condition");
		if (winCondition !is null) {
			factionId = winCondition.getIntAttribute("faction_id");
		} else {
			_log("WARNING, couldn't find win_condition tag", -1);
		}

		_log("faction " + factionId + " won");

		if (factionId == 0) {
			bool campaignCompleted = false;
			// friendly faction won, advance to next map
			_log("advance", 1);

			// not real data to add about it, is there a "set" in php?
			setStageCompleted(m_currentStageIndex);

			if (m_world !is null) {
				// now, update world view, declare the area ours
				m_world.refresh(m_stages, m_stagesCompleted, m_currentStageIndex);
			}

			m_metagame.getTaskSequencer().add(Call(CALL(m_metagame.save)));

			campaignCompleted = isCampaignCompleted();
			if (campaignCompleted) {
				_log("campaign completed", 1);
				if (m_loop) {
					_log("looping -> resetting");
					resetStagesCompleted();
					campaignCompleted = false;

					// this feels mighty risky to do, let's see what happens;
					// we're requesting the metagame to call init again while already running,
					// this would be handy in order to really recreate the instances related to everything
					// so that we wouldn't have any leftover crap from the previous cycle
					// given how poorly we're doing any kind of tracker cleanup and restart stuff

					// works, but too soon; people want to celebrate in the last map too after beating it
					//$this->metagame->request_restart();

					// do the restart with task sequencer:
					// - do the regular map change countdown first
					// - save
					// - request restart

					m_metagame.getTaskSequencer().add(TimeAnnouncerTask(m_metagame, 30, true));
					m_metagame.getTaskSequencer().add(Call(CALL(m_metagame.requestRestart)));

					// we aren't even calling ready to advance here; everything will be lost anyway!

				} else {
					// campaign completed and not looping, game over, let user handle from here on
	
					// actually, it's ok to call ready to advance, adventure will set extraction points etc
					readyToAdvance();
				}
			} else {
				readyToAdvance();
			}

		} else {
			// no need to do anything here, we should've received faction_lost event as well 
			// and restarted the map because of that
		}
	}

	// --------------------------------------------
	protected void readyToAdvance() {
		// in invasion, pick first uncompleted stage
		// - normally just picks the next in order, but the admin might have warped around
		int index = 0;
		for (int i = 0; i < getStageCount(); ++i) {
			if (!isStageCompleted(i)) {
				index = i;
				break;
			}
		}
	
		commitToMapChange(index);
	}

	// --------------------------------------------
	protected int getStageCount() const override {
		return m_stages.size();
	}

	// --------------------------------------------
	protected string getMapName(int index) const override {
		return m_stages[index].m_mapInfo.m_name;
	}

	// --------------------------------------------
	protected const XmlElement@ getChangeMapCommand(int index) const override {
		return m_stages[index].getChangeMapCommand();
	}

	// --------------------------------------------
	protected const XmlElement@ getStartGameCommand(int index) const override {
		return m_stages[index].getStartGameCommand(m_metagame, getCompletionPercentage());
	}

	// --------------------------------------------
	protected int getNextStageIndex() const override {
		return m_nextStageIndex;
	}

	// --------------------------------------------
	float getCompletionPercentage() const {
		float number = float(getNumberOfCompletedStages());
		float count = float(getStageCount());
		return number / count;
	}

	// --------------------------------------------
	// --------------------------------------------
	// DIALOGUE
	// --------------------------------------------
	// --------------------------------------------
	// --------------------------------------------
	protected void announceMapStart() {
		// happens when a map has changed and the match starts

		// two main cases,
		// regular map
		// boss map
		if (!m_stages[m_currentStageIndex].isFinalBattle()) {
			// regular map

			// two main cases,
			// a hostile map
			// a completed map

			if (!isStageCompleted(m_currentStageIndex)) {
				// hostile

				// two more cases:
				// a new map, we've never been here before, practically means we just "captured" our first base when entering the map
				// a map, where we have been before

				// we don't have this info around, at the moment

				// so just map the case of owning just one base, covers most of situations and isn't entirely
				// wrong even in the case when player retreats and comes back
				Stage@ stage = m_stages[m_currentStageIndex];

				// assuming 0th faction is us
				// get starting base
				string baseName = "one of the bases";
				{
					const XmlElement@ base = getStartingBase(m_metagame, 0);
					if (base !is null) {
						baseName = base.getStringAttribute("name");
					}
				}
				
				dictionary a = {
					{"%map_name", stage.m_mapInfo.m_name}, 
					{"%base_name", baseName}, 
					{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
				};

				if (stage.m_factions[0].m_ownedBases.size() <= 1) {
					// first time here

					// commander says something
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 2.0, 0, "map start with 1 base, part 1", a));
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 4.0, 0, "map start with 1 base, part 2", a));
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "map start with 1 base, part 3", a));

					// capture map?
					if (stage.isCapture()) {
						m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 6.0, 0, "map start with 1 base, capture", a));

					} else if (stage.isKoth()) {
						// koth map?
						a["%target_base_name"] = stage.m_kothTargetBase;
						m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 6.0, 0, "map start with 1 base, koth", a));
					}

				} else {
					// doing a resume

					// commander says something
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "map start with more bases, part 1", a));
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "map start with more bases, part 2", a));
				}

				// side objectives?
				if (stage.hasSideObjectives()) {
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "side objectives", a));
				}

				// loot / cargo trucks?
				if (stage.hasLootObjective()) {
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "loot objective", a));
				}

				// radio tower / truck?
				if (stage.hasRadioObjective()) {
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "radio tower or truck objective", a));
				}

				// aa?
				if (hasAaObjective()) {
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "aa objective", a));
				}

				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 0.0, 0, "map start, ending", a));

			} else {
				// completed, assuming friendly for now
				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 0.0, 0, "map start with completed map"));
			}

		} else {
			// boss map
			if (!isStageCompleted(m_currentStageIndex)) {
				// not completed

				Stage@ stage = m_stages[m_currentStageIndex];
				string baseName = "one of the bases";
				{
					const XmlElement@ base = getStartingBase(m_metagame, 0);
					if (base !is null) {
						baseName = base.getStringAttribute("name");
					}
				}

				dictionary a = {
					{"%map_name", stage.m_mapInfo.m_name}, 
					{"%base_name", baseName},
					{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
				};

				// commander says something
				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 2.0, 0, stage.m_mapInfo.m_name+" start with 1 base, part 1", a));
				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" start with 1 base, part 2", a));
				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" start with 1 base, part 3", a));
				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" start with 1 base, part 4", a));
				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" start with 1 base, part 5", a));
			} else {
			}
		}

		// finally enable "in game commander" radio, battle and event reports
		m_metagame.getTaskSequencer().add(CallFloat(CALL_FLOAT(this.setCommanderAiReports), 1.0));
	}

	// --------------------------------------------
	protected bool hasAaObjective() const {
		bool result = false;

		// query enemy vehicles and check for aa_emplacement
		Stage@ stage = m_stages[m_currentStageIndex];

		for (uint j = 0; j < stage.m_factions.size(); ++j) {
			Faction@ f = stage.m_factions[j];
			if (f.m_config.m_index != 0 &&
				// skip neutral
				!f.isNeutral()) {

				array<const XmlElement@> list = getVehicles(m_metagame, j, "aa_emplacement.vehicle");
				for (uint i = 0; i < list.size() && !result; i++) {
					const XmlElement@ info = list[i];
					int id = info.getIntAttribute("id");
					if (id >= 0) {
						const XmlElement@ vehicle = getVehicleInfo(m_metagame, id);
						if (vehicle !is null && vehicle.getIntAttribute("id") >= 0) {
							// require being alive
							float health = vehicle.getFloatAttribute("health");
							_log("aa emplacement found, faction " + j + " = " + f.m_config.m_name + ", health=" + health, 2);
							if (health > 0.0) {
								result = true;
							}
						}
					}
				}

				if (result) {
					break;
				}
			}
		}

		return result;
	}

	// --------------------------------------------
	void setCommanderAiReports(float percentage) {
		// $percentage = 1.0 -> all are shown
		// $percentage = 0.0 -> none but 1.0 priority reports are shown
		string command = 
			"<command\n" + 
			"  class='commander_ai'" +
			"  faction='0'" +
			"  commander_radio_reports='" + percentage + "'>" +
			"</command>\n";
		m_metagame.getComms().send(command);
	}

	// --------------------------------------------
	protected void announceMapAdvance(int index) {
		// happens when a map is about to change, i.e. in adventure mode the player hits the hitbox
		// would it actually be better to have a second bigger hitbox?
		// - this chat could happen when player enters the bigger hitbox
		// - and actual map advance moment wouldn't do anymore chatting, being more immediate

		Stage@ stage = m_stages[index];

		array<string> enemyNames;
		// fill enemy names
		for (uint i = 0; i < stage.m_factions.size(); ++i) {
			Faction@ f = stage.m_factions[i];
			if (f.m_config.m_index != 0 &&
				// skip neutral
				!f.isNeutral()) {

				enemyNames.insertLast(f.m_config.m_name);
			}
		}
		string regionName = getMapName(index);

		// two main cases:
		// - regular map
		// - boss map

		if (!stage.isFinalBattle()) {
			// regular map

			// two main cases:
			// - the map has enemies
			// - the map has friendlies

			// commander says something
			if (enemyNames.size() > 0) {
				// if there are enemies, report it
				{
					dictionary a = {
						{"%map_name", regionName}, 
						{"%faction_name", enemyNames[0]}
					};
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "map advance, held by enemy", a));
				}

				if (enemyNames.size() > 1) {
					dictionary a = {
						{"%faction_name", enemyNames[1]}
					};
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 2.0, 0, "map advance, another enemy present", a));
				}

				if (stage.m_factions[0].m_ownedBases.size() <= 1) {
					// we haven't been there yet, basically
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 2.0, 0, "map advance, new map"));

				} else {
					// we already own some bases
					dictionary a = {
						{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
					};
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 1.0, 0, "map advance, been there before", a));
				}

			} else {
				// just friendlies in this map
				dictionary a = {
					{"%map_name", regionName},
					{"%faction_name", stage.m_factions[0].m_config.m_name}
				};
				m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 2.0, 0, "map advance, friendly map", a));
			}

		} else {
			// boss map
			// commander says something
			if (enemyNames.size() > 0) {

				if (stage.m_factions[0].m_ownedBases.size() <= 1) {
					// if there are enemies, report it
					dictionary a = {
						{"%map_name", regionName},
						{"%faction_name", enemyNames[0]}
					};
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, stage.m_mapInfo.m_name+" advance, held by enemy, part 1", a));
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" advance, held by enemy, part 2", a));
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" advance, held by enemy, part 3", a));
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" advance, held by enemy, part 4", a));
					m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, stage.m_mapInfo.m_name+" advance, held by enemy, part 5", a));
				}
				// don't report anything if going back.. going back and forth is there for convenience, but it doesn't make sense

			} else {
				// completed
			}

		}
	}

	// --------------------------------------------
    void startMapEx(int index) {
		startMap(index);
	}

	// --------------------------------------------
    void startMap(int index, bool beginOnly = false) {
		_log("start_map, index=" + index + ", begin_only=" + beginOnly);
		// in invasion, store the faction settings in gamemode
		// so that we can juggle with them when the match is on
		// and reset them back to defaults when needed
		Stage@ stage = m_stages[index];
		m_metagame.setFactions(stage.m_factions);
		m_metagame.setMapInfo(stage.m_mapInfo);

		//parent::start_map($index, $begin_only);
		// extra commands need to happen before the correct game is started
		// so that faction resource configs are in before mass spawning

		m_currentStageIndex = index;

		if (!beginOnly) {
			// change map 
			m_metagame.getComms().send(getChangeMapCommand(index));

			// TODO:
			// - this would probably be the best place to sync & clear; when the sync comes, the default game has started and sent all its starting events,
			//   which we want to clear
			// - can't risk it, things work without it too
			/*
			{
				$query_doc = new DOMDocument();
				$command = "<command class='make_query' id='sync_query_0'/>\n";
				$query_doc->loadXML($command);
				$doc = $this->metagame->comms->query($query_doc);
			}
			*/

			// as we change the map, we also need to set the faction resources
			// but only then -- otherwise we continue with whatever
			// was set in the match already

			{
				array<XmlElement@>@ commands = m_configurator.getFactionResourceConfigChangeCommands(getCompletionPercentage(), m_stages[index]);
				for (uint i = 0; i < commands.size(); ++i) {
					const XmlElement@ value = commands[i];
					m_metagame.getComms().send(value);
				}
			}
		}

		// if continuing a game, don't clear queue - we already have e.g. vehicle spawn events there as game loaded before the script,
		// we can't lose those, otherwise some trackers may fail to be notified of the events
		if (!beginOnly) {
			// not loading here
			// - as we just changed the map and the default match started,
			//   we gots plenty of events that no longer are valid, ignore them
			m_metagame.getComms().clearQueue();
		}

		m_metagame.preBeginMatch();

		if (!beginOnly) {
			// shut ingame commander radio before starting the match -- we'll do "high commander" briefing from the script, after that let in game commander report things
			setCommanderAiReports(0.0);
		
			// start game 
			const XmlElement@ startGameCommand = getStartGameCommand(index);
			m_metagame.getComms().send(startGameCommand);

			// wait here 
			// - make a query, the game will serve it as soon as it can (->marks that resources have been changed and the match has been started)
			// only then announce map start
			XmlElement@ query = XmlElement(makeQuery(m_metagame, array<dictionary> = {}));
			const XmlElement@ doc = m_metagame.getComms().query(query);

			m_metagame.resetTimer();
		}
		
		// initialize world view in game
		if (m_world !is null) {
			m_world.setup(m_factionConfigs, m_stages, m_stagesCompleted, index);
		}

		if (!beginOnly) {
			// --> now announce map start
			announceMapStart();
		}

		m_metagame.postBeginMatch();

		// create stage specific trackers:
		_log("trackers: " + stage.m_trackers.size(), 2);
		for (uint i = 0; i < stage.m_trackers.size(); ++i) {
			Tracker@ tracker = stage.m_trackers[i];
			m_metagame.addTracker(tracker);
			// additionally let the tracker change behavior based on if we are starting it in a brand new map and match or loading into match and continuing
			if (beginOnly) {
				tracker.gameContinuePreStart();
			}
		}
	}

	// --------------------------------------------
    void restartMap() {
		int index = m_currentStageIndex;
		_log("restart_map, index=" + index);

		m_metagame.setFactions(m_stages[index].m_factions);

		m_metagame.getComms().clearQueue();
		m_metagame.preBeginMatch();

		// start game 
		const XmlElement@ startGameCommand = getStartGameCommand(index);
		m_metagame.getComms().send(startGameCommand);

		m_metagame.postBeginMatch();

		for (uint i = 0; i < m_stages[index].m_trackers.size(); ++i) {
			Tracker@ tracker = m_stages[index].m_trackers[i];
			m_metagame.addTracker(tracker);
		}

	}

    // ----------------------------------------------------
	// debugging tools
    protected void handleChatEvent(const XmlElement@ event) {
		// player_id
		// player_name
		// message
		// global

		string message = event.getStringAttribute("message");
		// for the most part, chat events aren't commands, so check that first
		if (!startsWith(message, "/")) {
			return;
		}

		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");
		if (!m_metagame.getAdminManager().isAdmin(sender, senderId)) {
			return;
		}

        if (checkCommand(message, "warp")) {
			array<string> parameters = parseParameters(message, "warp");
			if (parameters.size() > 0) {
				int index = parseInt(parameters[0]);
				sendFactionMessage(m_metagame, 0, "warping to " + index);
				commitToMapChange(index);
			}
		} else if (checkCommand(message, "restart")) {
			restartMap();
		}
	}

	// --------------------------------------------
	void save(XmlElement@ root) {
		XmlElement@ parent = root;

		XmlElement subroot("map_rotator");
		saveImpl(subroot);
		
		parent.appendChild(subroot);
	}

	// --------------------------------------------
	protected void saveImpl(XmlElement@ subroot) {
		// save chosen faction configs
		for (uint i = 0; i < m_factionConfigs.size(); ++i) {
			FactionConfig@ faction = m_factionConfigs[i];
			XmlElement e("faction_config");
			e.setStringAttribute("file", faction.m_file);
			subroot.appendChild(e);
		}

		// save completed maps
		for (uint i = 0; i < m_stagesCompleted.size(); ++i) {
			int index = m_stagesCompleted[i];
			XmlElement e("map_completed");
			e.setIntAttribute("index", index);
			subroot.appendChild(e);
		}
	}

	// --------------------------------------------
	void load(const XmlElement@ root) {
		_log("loading map rotator", 1);
		resetStagesCompleted();

		const XmlElement@ subroot = root.getFirstElementByTagName("map_rotator");
		if (subroot !is null) {
			{
				// copy available configs array to work as a base list
				const array<FactionConfig@>@ factions = m_configurator.getAvailableFactionConfigs();

				// re-setup faction configs now
				array<const XmlElement@> list = subroot.getElementsByTagName("faction_config");
				for (uint i = 0; i < list.size(); ++i) {
					const XmlElement@ e = list[i];
					string file = e.getStringAttribute("file");

					// find the config object that corresponds to given file
					FactionConfig@ targetFaction;
					for (uint j = 0; j < factions.size(); ++j) {
						FactionConfig@ faction = factions[j];
						if (faction.m_file == file) {
							// this is the one
							@targetFaction = @faction;
							break;
						}
					}
					if (targetFaction !is null) {
						// reorder the current faction configs array
						FactionConfig@ faction = m_factionConfigs[i];
						// retain the old object, we already have stages pointing at it
						faction.replaceData(targetFaction);
						faction.m_index = i;
						
					} else {
						if (file != "neutral.xml") {
							_log("warning, config not found for " + file, -1);
						}
					}
				}
			}

			{
				array<const XmlElement@> list = subroot.getElementsByTagName("map_completed");
				for (uint i = 0; i < list.size(); ++i) {
					const XmlElement@ e = list[i];
					int index = e.getIntAttribute("index");
					_log("index=" + index, 1);
					setStageCompleted(index);
				}
			}
		} else {
			_log("WARNING, map_rotator not found", -1);
		}
	}
}
