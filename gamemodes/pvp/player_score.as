#include "tracker.as"

class PlayerScore : Tracker {
    protected GameModePvp@ m_metagame;

    protected dictionary m_playerKill;

    protected dictionary m_playerDie;

    protected int m_faction_0_kill;
    protected int m_faction_1_kill;

    protected MapRotatorPvp@ m_mapRotator;

    // 总共杀50人赢
    int FACTION_WIN_SCORE = 50;

    PlayerScore(GameModePvp@ metagame) {
        @m_metagame = @metagame;

        m_faction_0_kill = 0;
        m_faction_1_kill = 0;
    }

    void setupMapRotator(MapRotatorPvp@ mapRotator) {
        @m_mapRotator = @mapRotator;
    }

    // protected void handleCharacterDieEvent(const XmlElement@ event) {

    // }

    void initPlayer(string playerName, int faction_id) {
        addPlayerKill(playerName, faction_id, 0);
        addPlayerDie(playerName, 0);
    }

    void addPlayerKill(string playerName, int faction_id, int num = 1) {
        if (m_playerKill.exists(playerName)) {
            int kill_num;
            m_playerKill.get(playerName, kill_num);
            kill_num += num;
            m_playerKill.set(playerName, kill_num);
        } else {
            m_playerKill.set(playerName, num);
        }

        if (faction_id == 0) {
            m_faction_0_kill += num;
        } else {
            m_faction_1_kill += num;
        }

        if (m_faction_0_kill == FACTION_WIN_SCORE) {
            // 0阵营赢
            m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
            m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");

            return;
        }

        if (m_faction_1_kill == FACTION_WIN_SCORE) {
            // 1阵营赢
            m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='0' />");
            m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='1' />");

            return;
        }
    }

    void addPlayerDie(string playerName, int num = 1) {
        if (m_playerDie.exists(playerName)) {
            int die_num;
            m_playerDie.get(playerName, die_num);
            die_num += num;
            m_playerDie.set(playerName, die_num);
        } else {
            m_playerDie.set(playerName, num);
        }
    }

    int getPlayerKill(string playerName) {
        if (m_playerKill.exists(playerName)) {
            int playerKill;
            m_playerKill.get(playerName, playerKill);
            return playerKill;
        } else {
            return 0;
        }
    }

    void resetPlayer(string playerName) {
        resetPlayerKill(playerName);
        resetPlayerDie(playerName);
    }

    void resetPlayerKill(string playerName) {
        if (m_playerKill.exists(playerName)) {
            m_playerKill.set(playerName, 0);
        }
    }

    void resetPlayerDie(string playerName) {
        if (m_playerDie.exists(playerName)) {
            m_playerDie.set(playerName, 0);
        }
    }

    int getPlayerDie(string playerName) {
        if (m_playerDie.exists(playerName)) {
            int playerDie;
            m_playerDie.get(playerName, playerDie);
            return playerDie;
        } else {
            return 0;
        }
    }

    string getFactionName(int factionId) {
        const array<FactionConfig@>@ factionConfigList = m_mapRotator.getFactionConfigs();
        for (uint i = 0; i < factionConfigList.length(); ++i) {
            if (factionId == factionConfigList[i].m_index) {
                return factionConfigList[i].m_name;
            }
        }

        return "";
    }

    string getScoreCondition() {
        _log(getFactionName(0) + " ( " + m_faction_0_kill + " ) -- " + getFactionName(1) + " ( " + m_faction_1_kill + " )");
        return getFactionName(0) + " ( " + m_faction_0_kill + " ) -- " + getFactionName(1) + " ( " + m_faction_1_kill + " )";
    }

    void resetAllScore() {
        m_playerKill.deleteAll();
        m_playerDie.deleteAll();
        m_faction_0_kill = 0;
        m_faction_1_kill = 0;
    }

    string getMvpName() {
        string mvpName;
        int max = 0;
        for (uint i = 0; i < m_playerKill.getKeys().length(); ++i) {
            string playerName = m_playerKill.getKeys()[i];
            int playerKill = 0;
            m_playerKill.get(playerName, playerKill);
            if (playerKill > max) {
                mvpName = playerName;
                max = playerKill;
            }
        }

        return mvpName;
    }

    void announceMvp() {
        string mvpName = getMvpName();
        int mvpKill = 0;
        m_playerKill.get(mvpName, mvpKill);
        sendFactionMessage(m_metagame, 0, "本场MVP：" + mvpName + "， 分数：" + mvpKill);
        sendFactionMessage(m_metagame, 1, "本场MVP：" + mvpName + "， 分数：" + mvpKill);
    }

    void announceScore() {
        _log("本场比赛结果   " + getFactionName(0) + " ( " + m_faction_0_kill + " ) -- " + getFactionName(1) + " ( " + m_faction_1_kill + " )");
        sendFactionMessage(m_metagame, 0, getFactionName(0) + " ( " + m_faction_0_kill + " ) -- " + getFactionName(1) + " ( " + m_faction_1_kill + " )");
        sendFactionMessage(m_metagame, 1, getFactionName(0) + " ( " + m_faction_0_kill + " ) -- " + getFactionName(1) + " ( " + m_faction_1_kill + " )");

        array<string> playerNames = m_playerKill.getKeys();
        if (playerNames.length() == 0) {
            return;
        }

        for (uint i = 0; i < playerNames.length() - 1; ++i) {
            for (uint j = 0; j < playerNames.length() - 1 - i; ++j) {
                int currentPlayerKill = 0;
                m_playerKill.get(playerNames[j], currentPlayerKill);
                int nextPlayerKill = 0;
                m_playerKill.get(playerNames[j + 1], nextPlayerKill);
                if (currentPlayerKill > nextPlayerKill) {
                    string tempName = playerNames[j + 1];
                    playerNames[j + 1] = playerNames[j];
                    playerNames[j] = tempName;
                }
            }
        }

        for (uint i = 0; i < playerNames.length(); ++i) {
            int playerKill = 0;
            m_playerKill.get(playerNames[i], playerKill);
            int playerDie = 0;
            m_playerDie.get(playerNames[i], playerDie);
            sendFactionMessage(m_metagame, 0, playerNames[i] + " 分数：" + playerKill + "， 死亡：" + playerDie);
            sendFactionMessage(m_metagame, 1, playerNames[i] + " 分数：" + playerKill + "， 死亡：" + playerDie);
        }
    }
}
