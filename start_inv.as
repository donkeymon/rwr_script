// declare include paths
#include "path://media/packages/vanilla/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
    XmlElement inputSettings(inputData);

    UserSettings settings;

    _setupLog("dev_verbose");  // 不会调试就删掉

    settings.m_fellowCapacityFactor = 1.10;  // 我军ai人数基数
    settings.m_enemyCapacityFactor = 1.30;  // 敌军ai人数基数
    settings.m_factionChoice = 0;           // 我军阵营
    settings.m_playerAiCompensationFactor = 1.1;  // 未知
    settings.m_enemyAiAccuracyFactor = 0.95;    // 敌军ai准度
    settings.m_fellowAiAccuracyFactor = 0.95;   // 我军ai准度
    settings.m_playerAiReduction = 1.0;         // 未知
    settings.m_teamKillPenaltyEnabled = true;   // 启用tk
    settings.m_completionVarianceEnabled = false;   // 未知
    settings.m_xpFactor = 1.0;      // xp倍数
    settings.m_rpFactor = 1.5;      // rp倍数
    settings.m_initialRp = 3000;    // 新人初始rp
    settings.m_teamKillsToStartPenalty = 5;   // 杀5个我军玩家后开始tk
    settings.m_teamKillPenaltyTime = 1800.0;   // tk时间1800秒
    settings.m_forgiveTeamKillTime = 900.0;    // 连续900秒后不杀我军玩家后重新计数

    array<string> overlays = {
            "media/packages/invasion"
    };
    settings.m_overlayPaths = overlays;

    // register_in_serverlist写0不在服务器列表中显示，写1显示
    // max_player 根据服务器带宽大小写，1M带宽最多4人
    // client_faction只写一个不能手动选阵营，写两个或三个可以手动选阵营  id = 0 , 1, 2
    settings.m_startServerCommand = """
	<command class='start_server'
		server_name='test - Invasion'
		server_port='1240'
		comment=''
		url=''
		register_in_serverlist='0'
		mode='COOP'
		persistency='forever'
		max_players='4'
		>
		<client_faction id='0' />
	</command>
	""";
    settings.print();   // 不会调试就删掉

    GameModeInvasion metagame(settings);

    metagame.init();
    metagame.run();
    metagame.uninit();

    _log("ending execution");  // 不会调试就删掉
}
