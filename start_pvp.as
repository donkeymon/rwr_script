#include "path://media/packages/vanilla/scripts"

#include "gamemode_pvp.as"

void main(dictionary@ inputData) {

    UserSettings settings;

    settings.m_fellowCapacityFactor = 1.10;  // 我军ai人数基数
    settings.m_enemyCapacityFactor = 1.10;  // 敌军ai人数基数
    settings.m_playerAiCompensationFactor = 1.1;  // 未知
    settings.m_enemyAiAccuracyFactor = 0.95;    // 敌军ai准度
    settings.m_fellowAiAccuracyFactor = 0.95;   // 我军ai准度
    settings.m_playerAiReduction = 1.0;         // 未知
    settings.m_teamKillPenaltyEnabled = true;   // 启用tk
    settings.m_completionVarianceEnabled = false;   // 未知
    settings.m_xpFactor = 1.0;      // xp倍数
    settings.m_rpFactor = 1.5;      // rp倍数
    settings.m_initialRp = 5000;    // 新人初始rp
    settings.m_teamKillsToStartPenalty = 5;   // 杀5个自家玩家后开始tk
    settings.m_teamKillPenaltyTime = 300.0;   // tk时间300秒
    settings.m_forgiveTeamKillTime = 900.0;    // 连续900秒后不杀自家玩家后重新计数

    settings.m_startServerCommand = """
    <command class='start_server'
        server_name='test - PVP'
        server_port='1240'
        comment=''
        url=''
        register_in_serverlist='0'
        mode='PVP'
        persistency='forever'
        max_players='4'
        >
        <client_faction id='0' />
        <client_faction id='1' />
    </command>
    """;

    GameModePvp metagame(settings);
    
    metagame.init();
    metagame.run();
    metagame.uninit();
}
