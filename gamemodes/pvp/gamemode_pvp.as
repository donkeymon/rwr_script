#include "gamemode.as"
#include "map_info.as"
#include "log.as"

#include "user_settings.as"
#include "map_rotator_pvp.as"
#include "stage_configurator_pvp.as"

#include "basic_command_handler_pvp.as"
#include "penalty_manager_pvp.as"
#include "autosaver.as"

#include "player_score.as"

class GameModePvp : GameMode {
    protected MapRotatorPvp@ m_mapRotator;
    protected PenaltyManagerPvp@ m_penaltyManager;

    protected array<Faction@> m_factions;

    protected UserSettings@ m_userSettings;

    protected PlayerScore@ m_playerScore;

    string m_gameMapPath = "";

    GameModePvp(UserSettings@ settings) {
        super(settings.m_startServerCommand);

        @m_userSettings = @settings;
    }

    void init() {
        GameMode::init();

        @m_playerScore = PlayerScore(this);

        setupMapRotator();
        setupPenaltyManager();

        m_mapRotator.init();
        m_mapRotator.startRotation();
    }

    void uninit() {
        GameMode::uninit();
    }

    protected void setupMapRotator() {
        @m_mapRotator = MapRotatorPvp(this, m_playerScore);
        StageConfiguratorPvp configurator(this, m_mapRotator);
    }

    protected void setupPenaltyManager() {
        if (getUserSettings().m_teamKillPenaltyEnabled) {
            @m_penaltyManager = PenaltyManagerPvp(this,
                m_playerScore,
                m_userSettings.m_teamKillsToStartPenalty, 
                m_userSettings.m_teamKillPenaltyTime, 
                m_userSettings.m_forgiveTeamKillTime);
        }
    }

    const UserSettings@ getUserSettings() const {
        return m_userSettings;
    }

    // MapRotator calls here when a battle is about to be started
    void preBeginMatch() {

        // all trackers are cleared when match is about to begin
        GameMode::preBeginMatch();

        // map rotator needs to be added before match starts
        // - adventure mode needs to listen for player spawning which happens right when match starts
        // - usually it's good to add trackers only after match has started
        addTracker(m_mapRotator);

        setupMinibosses();
    }

    // MapRotator calls here when a battle has started
    void postBeginMatch() {
        GameMode::postBeginMatch();

        // query for basic match data -- we mostly need the savegame location
        updateGeneralInfo();

        if (m_penaltyManager !is null) {
            addTracker(m_penaltyManager);
        }

        addTracker(AutoSaver(this));

        addTracker(BasicCommandHandlerPvp(this, m_penaltyManager, m_playerScore));
    }

    protected void updateGeneralInfo() {
        const XmlElement@ general = getGeneralInfo(this);
        if (general !is null) {
            m_gameMapPath = general.getStringAttribute("map");
        }
    }

    protected void setupMinibosses() {
        {
            // disable minibosses in friendly faction 
            // to prevent harvesting rares from minibosses
            XmlElement command("command");
            command.setStringAttribute("class", "faction");
            command.setIntAttribute("faction_id", 0);
            command.setStringAttribute("soldier_group_name", "miniboss");
            command.setFloatAttribute("spawn_score", 0.0f);
            getComms().send(command);

            command.setStringAttribute("soldier_group_name", "miniboss_female");
            getComms().send(command);
        }

        for (uint i = 1; i < m_factions.size(); ++i) {
            const FactionConfig@ config = m_factions[i].m_config;
            // increase minibosses in enemy factions slightly
            // 0.005 -> 0.007 (0.004 male, 0.003 female)
            bool femaleExists = true;
            if (config.m_file == "brown.xml") {
                femaleExists = false;
            }

            XmlElement command("command");
            command.setStringAttribute("class", "faction");
            command.setIntAttribute("faction_id", i);
            command.setStringAttribute("soldier_group_name", "miniboss");
            command.setFloatAttribute("spawn_score", femaleExists ? 0.004f : 0.007f);
            getComms().send(command);

            if (femaleExists) {
                command.setStringAttribute("soldier_group_name", "miniboss_female");
                command.setFloatAttribute("spawn_score", 0.003f);
                getComms().send(command);
            }
        }
    }

    // map rotator is the one that actually defines which factions are in the game and which default values are used,
    // it will feed us the faction data
    void setFactions(const array<Faction@>@ factions) {
        m_factions = factions;
    }

    // map rotator lets us know some specific map related information
    // we need for handling position mapping 
    void setMapInfo(const MapInfo@ info) {
        m_mapInfo = info;
    }

    // trackers may need to alter things about faction settings and be able to reset them back to defaults,
    // we'll provide the data from here
    const array<Faction@>@ getFactions() const {
        return m_factions;
    }

    uint getFactionCount() const {
        return m_factions.size();
    }

    const array<FactionConfig@>@ getFactionConfigs() const {
        // in invasion, map rotator decides faction configs
        return m_mapRotator.getFactionConfigs();
    }

    string getMapId() const {
        return m_mapInfo.m_path;
    }

    // --------------------------------------------
    float determineFinalFactionCapacityMultiplier(const Faction@ f, uint key) const {
        float completionPercentage = m_mapRotator.getCompletionPercentage();

        float multiplier = 1.0f;
        if (key == 0) {
            // friendly faction
            multiplier = m_userSettings.m_fellowCapacityFactor * f.m_capacityMultiplier;

            if (m_userSettings.m_completionVarianceEnabled) {
                // drain friendly faction power the farther the game goes;
                // player will gain power and will become more effective, so this works as an attempt to counter that a bit
                _log("completion: " + completionPercentage);
                if (completionPercentage > 0.8f) {
                    multiplier *= 0.9f;
                } else if (completionPercentage > 0.6f) {
                    multiplier *= 0.93f;
                } else if (completionPercentage > 0.4f) {
                    multiplier *= 0.97f;
                }
            }

        } else {
            // enemy
            multiplier = m_userSettings.m_enemyCapacityFactor * f.m_capacityMultiplier;

            if (m_userSettings.m_completionVarianceEnabled) {
                // first map: reduce enemies a bit, let it flow easier
                if (completionPercentage < 0.09f) {
                    multiplier *= 0.97f;
                }
            }
        }           

        return multiplier;
    }
}