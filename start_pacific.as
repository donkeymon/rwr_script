#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/pacific/scripts"

#include "my_gamemode.as"

// --------------------------------------------
void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	UserSettings settings;

    _setupLog("dev_verbose");

	settings.m_factionChoice = 0;
    settings.m_playerAiCompensationFactor = 1.1;
    settings.m_enemyAiAccuracyFactor = 0.97;
    settings.m_fellowAiAccuracyFactor = 0.97;
    settings.m_playerAiReduction = 1.0;
    settings.m_teamKillPenaltyEnabled = true;
	settings.m_initialRp = 8000;
    settings.m_initialXp = 0.3;
    settings.m_xpFactor = 1.5;
    settings.m_rpFactor = 1.5;

    array<string> overlays = {
            "media/packages/pacific_invasion"
    };
    settings.m_overlayPaths = overlays;

    settings.m_startServerCommand = """
<command class='start_server'
	server_name='DKM - Pacific'
	server_port='1241'
	comment='Coop campaign'
	url=''
	register_in_serverlist='1'
	mode='COOP'
	persistency='forever'
	max_players='24'>
	<client_faction id='0' />
</command>
""";

	settings.print();

	MyGameMode metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
