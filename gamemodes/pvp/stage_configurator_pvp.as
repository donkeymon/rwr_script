#include "faction_config.as"
#include "stage_configurator.as"
#include "stage_pvp.as"

class StageConfiguratorPvp : StageConfigurator {
    protected GameModePvp@ m_metagame;
    protected MapRotatorPvp@ m_mapRotator;

    StageConfiguratorPvp(GameModePvp@ metagame, MapRotatorPvp@ mapRotator) {
        @m_metagame = @metagame;
        @m_mapRotator = mapRotator;
        mapRotator.setConfigurator(this);
    }

    // ------------------------------------------------------------------------------------------------
    void setup() {
        setupFactionConfigs();

        setupStages();
    }

    // ------------------------------------------------------------------------------------------------
    const array<FactionConfig@>@ getAvailableFactionConfigs() const {
        array<FactionConfig@> availableFactionConfigs;

        availableFactionConfigs.push_back(FactionConfig(-1, "green.xml", "Greenbelts", "0.1 0.5 0", "green_boss.xml"));
        availableFactionConfigs.push_back(FactionConfig(-1, "grey.xml", "Graycollars", "0.5 0.5 0.5", "grey_boss.xml"));
        availableFactionConfigs.push_back(FactionConfig(-1, "brown.xml", "Brownpants", "0.5 0.25 0", "brown_boss.xml"));

        return availableFactionConfigs;
    }

    // --------------------------------------------
    const array<FactionConfig@>@ getFactionConfigs() const {
        return m_mapRotator.getFactionConfigs();
    }

    // ------------------------------------------------------------------------------------------------
    protected void setupFactionConfigs() {
        array<FactionConfig@> availableFactionConfigs = getAvailableFactionConfigs(); // copy for mutability

        const UserSettings@ settings = m_metagame.getUserSettings();
        // - the faction the player picks in lobby campaign menu needs to be inserted first in the faction configs list
        {
            _log("faction choice: " + settings.m_factionChoice, 1);
            FactionConfig@ userChosenFaction = availableFactionConfigs[settings.m_factionChoice];
            _log("player faction: " + userChosenFaction.m_file, 1);

            int index = int(getFactionConfigs().size()); // is 0
            userChosenFaction.m_index = index;
            m_mapRotator.addFactionConfig(userChosenFaction);

            availableFactionConfigs.erase(settings.m_factionChoice);
        }

        // - next add the rest of them, in random order
        while (availableFactionConfigs.size() > 0) {
            int index = int(getFactionConfigs().size());

            int availableIndex = rand(0, availableFactionConfigs.size() - 1);
            FactionConfig@ faction = availableFactionConfigs[availableIndex];

            _log("setting " + faction.m_name + " as index " + index, 1);

            faction.m_index = index;
            m_mapRotator.addFactionConfig(faction);

            availableFactionConfigs.erase(availableIndex);
        }

        // - finally add neutral
        {
            int index = getFactionConfigs().size();
            m_mapRotator.addFactionConfig(FactionConfig(index, "neutral.xml", "Neutral", "0 0 0"));
        }

        _log("total faction configs " + getFactionConfigs().size(), 1);
    }

    // ------------------------------------------------------------------------------------------------
    protected void addStage(Stage@ stage) {
        m_mapRotator.addStage(stage);
    }

    // ------------------------------------------------------------------------------------------------
    protected void setupStages() {
        addStage(setupStage_pvp_v2());
        addStage(setupStage_lab_def_koth());
    }

    protected Stage@ setupStage_pvp_v2() {
        Stage@ stage = createStage();
        stage.m_mapInfo.m_name = "PVP V2";
        stage.m_mapInfo.m_path = "media/packages/pvp_v2/maps/pvp1_v2";
        stage.m_mapInfo.m_id = "pvp1_v2";

        stage.addTracker(PeacefulLastBasePvp(m_metagame, 0));
        stage.addTracker(PeacefulLastBasePvp(m_metagame, 1));
        stage.m_maxSoldiers = 15 * 2;

        stage.m_soldierCapacityVariance = 1.0;

        {
            Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0));
            stage.m_factions.insertLast(f);
        }
        {
            Faction f(getFactionConfigs()[1], createFellowCommanderAiCommand(1));
            stage.m_factions.insertLast(f);
        }
        {
            // neutral
            Faction f(getFactionConfigs()[3], createCommanderAiCommand(3));
            f.m_capacityMultiplier = 0.0;
            stage.m_factions.insertLast(f);
        }

        {
            XmlElement command("command");
            command.setStringAttribute("class", "commander_ai");
            command.setIntAttribute("faction", 0);
            command.setFloatAttribute("base_defense", 1.0);
            command.setFloatAttribute("border_defense", 1.0);
            stage.m_extraCommands.insertLast(command);
        }

        {
            XmlElement command("command");
            command.setStringAttribute("class", "commander_ai");
            command.setIntAttribute("faction", 1);
            command.setFloatAttribute("base_defense", 1.0);
            command.setFloatAttribute("border_defense", 1.0);
            stage.m_extraCommands.insertLast(command);
        }

        // metadata
        stage.m_primaryObjective = "capture";

        return stage;
    }

    protected Stage@ setupStage_lab_def_koth() {
        Stage@ stage = createStage();
        stage.m_mapInfo.m_name = "LabDefKOTH";
        stage.m_mapInfo.m_path = "media/packages/pvp_v2/maps/def_lab_koth";
        stage.m_mapInfo.m_id = "def_lab_koth";

        stage.addTracker(PeacefulLastBasePvp(m_metagame, 0));
        stage.addTracker(PeacefulLastBasePvp(m_metagame, 1));
        stage.m_maxSoldiers = 12 * 9;

        stage.m_soldierCapacityVariance = 0.3;

        {
            Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0));
            f.m_overCapacity = 0;
            f.m_capacityOffset = 0; // handled in the vehicle files (0.95)
            f.m_capacityMultiplier = 1.0;
            f.m_bases = 1;
            stage.m_factions.insertLast(f);
        }
        {
            Faction f(getFactionConfigs()[1], createFellowCommanderAiCommand(1));
            f.m_overCapacity = 0;
            f.m_capacityOffset = 0; // handled in the vehicle files (0.95)
            f.m_capacityMultiplier = 1.0;
            f.m_bases = 1;
            stage.m_factions.insertLast(f); 
        }

        // metadata
        stage.m_primaryObjective = "capture";

        return stage;
    }

    // --------------------------------------------
    protected Stage@ createStage() const {
        return Stage(m_metagame.getUserSettings());
    }

    // --------------------------------------------
    array<XmlElement@>@ getFactionResourceConfigChangeCommands(float completionPercentage, Stage@ stage) {
        array<XmlElement@>@ commands = getFactionResourceChangeCommands(stage.m_factions.size());

        _log("completion percentage: " + completionPercentage);

        const UserSettings@ settings = m_metagame.getUserSettings();
        _log(" variance enabled: " + settings.m_completionVarianceEnabled);
        if (settings.m_completionVarianceEnabled) {
            array<XmlElement@>@ varianceCommands = getCompletionVarianceCommands(stage, completionPercentage);
            // append with command already gathered
            merge(commands, varianceCommands);
        }

        merge(commands, stage.m_extraCommands);

        return commands;
    }

    // --------------------------------------------
    protected array<XmlElement@>@ getFactionResourceChangeCommands(int factionCount) const {
        array<XmlElement@> commands;

        // invasion faction resources are nowadays based on resources declared for factions in the faction files 
        // + some minor changes for common and friendly
        for (int i = 0; i < factionCount; ++i) {
            commands.insertLast(getFactionResourceChangeCommand(i, getCommonFactionResourceChanges()));
        }

        // apply initial friendly faction resource modifications
        commands.insertLast(getFactionResourceChangeCommand(0, getFriendlyFactionResourceChanges()));

        return commands;
    }

    // --------------------------------------------
    protected array<ResourceChange@>@ getCommonFactionResourceChanges() const {
        array<ResourceChange@> list;
    
        list.push_back(ResourceChange(Resource("armored_truck.vehicle", "vehicle"), true));
        list.push_back(ResourceChange(Resource("mobile_armory.vehicle", "vehicle"), true));

        // disable certain weapons here; mainly because Dominance uses the same .resources files but we have further changes for Invasion here
        list.push_back(ResourceChange(Resource("l85a2.weapon", "weapon"), true));
        list.push_back(ResourceChange(Resource("famasg1.weapon", "weapon"), true));
        list.push_back(ResourceChange(Resource("sg552.weapon", "weapon"), true));
        list.push_back(ResourceChange(Resource("minig_resource.weapon", "weapon"), true));
        list.push_back(ResourceChange(Resource("tow_resource.weapon", "weapon"), true));
        list.push_back(ResourceChange(Resource("gl_resource.weapon", "weapon"), true));
        
        return list;
    }

    // --------------------------------------------
    protected array<ResourceChange@> getFriendlyFactionResourceChanges() const {
        array<ResourceChange@> list;

        // enable mobile spawn and armory trucks for player faction
        list.push_back(ResourceChange(Resource("armored_truck.vehicle", "vehicle"), true));
        list.push_back(ResourceChange(Resource("mobile_armory.vehicle", "vehicle"), true));

        // no m79 for friendlies
        list.push_back(ResourceChange(Resource("m79.weapon", "weapon"), false));

        // no suitcases/laptops carried by friendlies
        list.push_back(ResourceChange(Resource("suitcase.carry_item", "carry_item"), false));
        list.push_back(ResourceChange(Resource("laptop.carry_item", "carry_item"), false));

        // no cargo, prisons or aa
        list.push_back(ResourceChange(Resource("cargo_truck.vehicle", "vehicle"), false));
        list.push_back(ResourceChange(Resource("prison_door.vehicle", "vehicle"), false));
        list.push_back(ResourceChange(Resource("prison_bus.vehicle", "vehicle"), false));
        list.push_back(ResourceChange(Resource("aa_emplacement.vehicle", "vehicle"), false));

        return list;
    }

    // --------------------------------------------
    protected array<XmlElement@>@ getCompletionVarianceCommands(Stage@ stage, float completionPercentage) {
        // we want to have a sense of progression 
        // with the starting map vs other maps played before extra final maps

        array<XmlElement@> commands;

        if (stage.isFinalBattle()) {
            // don't use for final battles
            return commands;
        }

        if (completionPercentage < 0.08) {
            _log("below 10%");
            for (uint i = 0; i < stage.m_factions.size(); ++i) {
                // disable comms truck, cargo and radio tower on all factions, same for prisons
                array<string> keys = {
                    "radar_truck.vehicle", 
                    "cargo_truck.vehicle", 
                    "radar_tower.vehicle", 
                    "prison_bus.vehicle", 
                    "prison_door.vehicle", 
                    "aa_emplacement.vehicle",
                    "m113_tank_mortar.vehicle" };

                if (i == 0) {
                    // let friendlies have the tank, need it to make a successful tank call
                } else {
                    // disable tanks for enemy factions
                    keys.insertLast("tank.vehicle");
                    keys.insertLast("tank_1.vehicle");
                    keys.insertLast("tank_2.vehicle");
                }

                if (keys.size() > 0) {
                    XmlElement command("command"); 
                    command.setStringAttribute("class", "faction_resources"); 
                    command.setIntAttribute("faction_id", i);
                    addFactionResourceElements(command, "vehicle", keys, false);

                    commands.insertLast(command);
                }
            }
            // a bit odd that we change stage members here in a getter function, but just do it for now, it's just metadata
            stage.m_radioObjectivePresent = false;

        } else if (completionPercentage < 0.20) {
            _log("below 25%, above 10%");
            for (uint i = 0; i < stage.m_factions.size(); ++i) {
                array<string> keys;

                if (i == 0) {
                    // disable comms truck and radio tower on friendly faction only
                    keys.insertLast("radar_truck.vehicle");
                    keys.insertLast("radar_tower.vehicle");

                    // cargo & prisons are disabled anyway for friendly faction
                } else {
                }

                if (keys.size() > 0) {
                    XmlElement command("command"); 
                    command.setStringAttribute("class", "faction_resources"); 
                    command.setIntAttribute("faction_id", i);
                    addFactionResourceElements(command, "vehicle", keys, false);

                    commands.insertLast(command);
                }
            }
        }

        return commands;
    }
}