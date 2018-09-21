// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"

// --------------------------------------------
class BasicCommandHandlerInvasion : Tracker {
	protected Metagame@ m_metagame;
	protected PenaltyManager@ m_penaltymanager;

	// 解tk花费的rp
	int JIETK_COST_RP = 1000;

	// 启用buy命令
	bool ENABLE_COMMAND_BUY = true;

	// 启用垃圾桶命令
	bool ENABLE_COMMAND_LJT = true;

	// 启用炮弹命令
	bool ENABLE_COMMAND_PD = true;

	// 启用help命令
	bool ENABLE_COMMAND_HELP = true;

    // 启用无敌命令，暂时没用
    bool ENABLE_COMMAND_WUDI = true;

    // 无敌每秒花费rp
    int WUDI_COST_PER_SECOND = 100;

	// --------------------------------------------
	BasicCommandHandlerInvasion(Metagame@ metagame, PenaltyManager@ penaltymanager) {
		@m_metagame = @metagame;
		@m_penaltymanager = @penaltymanager;
	}

	// 内购
	void command_buy(int buyIndex, string senderPos, int characterId, const XmlElement@ characterInfo) {
		int playerRp = int(characterInfo.getFloatAttribute("rp"));
        string command = "";
        int cost = 0;

        switch(buyIndex) {
        	case 1:
        		if (playerRp >= 2) {
                    addItemInPlayerBackpack(characterId, "medikit", "weapon", 2);
                    cost = 2;
                }
                break;
            case 2:
                if (playerRp >= 10) {
                    addItemInPlayerBackpack(characterId, "wrench", "weapon", 2);
                    cost = 10;
                }
                break;
            case 3:
                if (playerRp >= 150) {
                    addItemToPlayer(characterId, "vest3", "carry_item", 4, 1);
                    cost = 150;
                }
                break;
            case 4:
                if (playerRp >= 200) {
                    spawnInstanceAtPos(senderPos, "atv_base.vehicle", "vehicle", 2.0);
                    cost = 200;
                }
                break;
            case 5:
                if (playerRp >= 1000) {
                    spawnInstanceAtPos(senderPos, "mobile_armory.vehicle", "vehicle", 4.0);
                    cost = 1000;
                }
                break;
            case 666:
                if (playerRp >= 120000) {
                    spawnInstanceAtPos(senderPos, "tank2.vehicle", "vehicle", 4.0);
                    cost = 120000;
                }
                break;
            default:
            	break;
        }

        if (cost == 0) {
        	return;
        }

        command =
            "<command class='rp_reward' character_id='" + characterId + "'" +
            "   reward='-"+ cost +"'>" +
            "</command>";
        m_metagame.getComms().send(command);

        return;
	}

	// 垃圾桶
	void command_ljt(string senderPos, int characterId, const XmlElement@ characterInfo) {
		int playerRp = int(characterInfo.getFloatAttribute("rp"));
        string command = "";
        int cost = 200;

        if (playerRp >= 200) {
        	spawnInstanceAtPos(senderPos, "dumpster.vehicle", "vehicle", 0.0, 0.0, -1.5);
	        spawnInstanceAtPos(senderPos, "dumpster.vehicle", "vehicle", 0.0, 0.0, 1.5);
	        spawnInstanceAtPos(senderPos, "dumpster.vehicle", "vehicle", -2.9, 0.0, 0.0);
	        spawnInstanceAtPos(senderPos, "dumpster.vehicle", "vehicle", 2.9, 0.0, 0.0);
        } else {
        	return;
        }
        
        command =
            "<command class='rp_reward' character_id='" + characterId + "'" +
            "   reward='-"+ cost +"'>" +
            "</command>";
        m_metagame.getComms().send(command);

        return;
	}

	// 炮弹
	void command_pd(int pdIndex, int characterId, const XmlElement@ characterInfo) {
        int playerRp = int(characterInfo.getFloatAttribute("rp"));
        string command = "";
        int cost = 30;

        if (playerRp > 30) {
        	switch(pdIndex)
	        {
	            case 0: addItemToPlayer(characterId, "claymore", "projectile", 4, 3); break;
	            case 1: addItemToPlayer(characterId, "artillery_shell", "projectile", 4, 3); break;
	            case 2: addItemToPlayer(characterId, "javelin", "projectile", 4, 3); break;
	            case 3: addItemToPlayer(characterId, "xm25", "projectile", 4, 3); break;
	            case 4: addItemToPlayer(characterId, "mgl_flasher", "projectile", 4, 3); break;
	            case 5: addItemToPlayer(characterId, "mortar_shell_heavy", "projectile", 4, 3); break;
	            case 6: addItemToPlayer(characterId, "rocket2", "projectile", 4, 3); break;
	            case 7: addItemToPlayer(characterId, "naval_mine", "projectile", 4, 3); break;
	            case 8: addItemToPlayer(characterId, "m2_carlgustav_rocket", "projectile", 4, 3); break;
	            case 9: addItemToPlayer(characterId, "m72_law_rocket", "projectile", 4, 3); break;
	            case 10: addItemToPlayer(characterId, "m202", "projectile", 4, 3); break;
	            default: break;
	        }
        } else {
        	return;
        }

        command =
            "<command class='rp_reward' character_id='" + characterId + "'" +
            "   reward='-"+ cost +"'>" +
            "</command>";
        m_metagame.getComms().send(command);

        return;
    }

	// help
	void command_help(int helpIndex, string senderPos, int characterId, const XmlElement@ characterInfo) {
        int playerRp = int(characterInfo.getFloatAttribute("rp"));
        string command = "";
        int cost = 0;

        switch(helpIndex)
        {
            case 1:
                if (playerRp > 400) {
                    spawnInstanceAtPos(senderPos, "default", "soldier", 3.0, 0.0, 3.0);
                    spawnInstanceAtPos(senderPos, "default", "soldier", 3.0, 0.0, -3.0);
                    spawnInstanceAtPos(senderPos, "default", "soldier", -3.0, 0.0, 3.0);
                    spawnInstanceAtPos(senderPos, "default", "soldier", -3.0, 0.0, -3.0);
                    cost = 400;
                }
                break;
            case 2:
                if (playerRp > 50) {
                    spawnInstanceAtPos(senderPos, "medic", "soldier", 2.0, 0.0, 0.0);
                    cost = 50;
                }
                break;
            case 3:
                if (playerRp > 1000) {
                    spawnInstanceAtPos(senderPos, "eod", "soldier", 2.0, 0.0, 0.0);
                    spawnInstanceAtPos(senderPos, "eod", "soldier", -2.0, 0.0, 0.0);
                    cost = 1000;
                }
                break;
            case 4:
                if (playerRp > 4000) {
                    spawnInstanceAtPos(senderPos, "miniboss", "soldier", 2.0, 0.0, 0.0);
                    spawnInstanceAtPos(senderPos, "miniboss", "soldier", -2.0, 0.0, 0.0);
                    cost = 4000;
                }
                break;
            case 5:
                if (playerRp > 6000) {
                    spawnInstanceAtPos(senderPos, "miniboss_female", "soldier", 2.0, 0.0, 0.0);
                    spawnInstanceAtPos(senderPos, "miniboss_female", "soldier", -2.0, 0.0, 0.0);
                    cost = 6000;
                }
                break;
            default: break;
        }

        command =
            "<command class='rp_reward' character_id='" + characterId + "'" +
            "   reward='-"+ cost +"'>" +
            "</command>";
        m_metagame.getComms().send(command);
    }

    // 无敌
    void command_wudi(int wudi_time, int senderId, int characterId, const XmlElement@ characterInfo) {
        if (wudi_time < 1) {
            return;
        }

        int playerRp = int(characterInfo.getFloatAttribute("rp"));
        string command = "";
        int cost = wudi_time * WUDI_COST_PER_SECOND;

        command =
            "<command class='rp_reward' character_id='" + characterId + "'" +
            "   reward='-"+ cost +"'>" +
            "</command>";
        m_metagame.getComms().send(command);

        sendPrivateMessage(m_metagame, senderId, "start after 3 seconds！！！！！！！");
        sleep(1);
        for (int i = 2; i >= 1; --i) {
            sendPrivateMessage(m_metagame, senderId, formatInt(i));
            sleep(1);
        }
        sendPrivateMessage(m_metagame, senderId, "Fuck them !!!!!!!!!!!!!!!!!!");
        // TODO set wudi

        sleep(wudi_time);

        sendPrivateMessage(m_metagame, senderId, "wudi buff stopped");
        // TODO unset wudi
    }

    // 有没有被tk
    bool is_tk(string senderSid) {
        if (m_penaltymanager.m_persistentTrackedPlayers.exists(senderSid)) {
            PenalizedPlayer@ pPlayer;
            @pPlayer = m_penaltymanager.m_persistentTrackedPlayers.get(senderSid);
            if (pPlayer !is null && pPlayer.m_penaltyTimer >= 0) {
                return true;
            }
        }

        return false;
    }

    // 解tk
    void command_jietk(string senderSid, const XmlElement@ senderInfo, string sender, int senderId, const XmlElement@ characterInfo, int characterId) {
        if (m_penaltymanager.m_persistentTrackedPlayers.exists(senderSid)) {
            PenalizedPlayer@ pPlayer;
            @pPlayer = m_penaltymanager.m_persistentTrackedPlayers.get(senderSid);
            if (pPlayer !is null && pPlayer.m_penaltyTimer >= 0 && pPlayer.m_penaltyTimer <= 1800) {
                int playerRp = int(characterInfo.getFloatAttribute("rp"));
                if (playerRp >= JIETK_COST_RP) {
                    string hash = senderInfo.getStringAttribute("profile_hash");
                    string ip = senderInfo.getStringAttribute("ip");
                    string sid = senderInfo.getStringAttribute("sid");
                    @pPlayer = PenalizedPlayer(sender, hash, ip, sid, senderId);

                    m_penaltymanager.endPenalty(pPlayer);
                    string command = "<command class='rp_reward'   character_id='" + characterId + "'" +
                                  "   reward='-" + JIETK_COST_RP + "'>" +
                                  "</command>";
                    m_metagame.getComms().send(command);
                }
            }
        }
        return;
    }

    // 获取玩家列表  admin专用
    void command_players(int senderId) {
    	string player_name = "";
    	int player_id = -1;

    	array<const XmlElement@> playerList = getPlayers(m_metagame);
    	for (uint i = 0; i < playerList.size(); ++i) {
    		player_name = playerList[i].getStringAttribute("name");
    		player_id = playerList[i].getIntAttribute("player_id");
    		sendPrivateMessage(m_metagame, senderId, "player_name: " + player_name + " , player_id: " + formatInt(player_id));
    	}

    	return;
    }

    // 踢出玩家 admin专用
    void command_kick(int player_id) {
    	if (player_id > 0) {
    		string command = "<command class='kick_player' player_id='" + player_id + "' />";
			m_metagame.getComms().send(command);
    	}
    	
    	return;
    }

    // tk admin专用
    void command_tk(int playerId, int senderId, int time = 1800) {
        const XmlElement@ tkPlayer = getPlayerInfo(m_metagame, playerId);
        if (tkPlayer is null) {
            sendPrivateMessage(m_metagame, senderId, "没有此玩家!!!!!!!!!!!!!");
            return;
        }

        string hash = tkPlayer.getStringAttribute("profile_hash");
        string ip = tkPlayer.getStringAttribute("ip");
        string sid = tkPlayer.getStringAttribute("sid");
        array<const XmlElement@> playerList = getPlayers(m_metagame);
        string playerName = "";
        for (uint i = 0; i < playerList.size(); ++i) {
            if (playerId == playerList[i].getIntAttribute("player_id")) {
                playerName = playerList[i].getStringAttribute("name");
            }
        }

        if (playerName == "") {
            sendPrivateMessage(m_metagame, senderId, "没有此玩家!!!!!!!!!!!!!");
            return;
        }

        PenalizedPlayer@ pPlayer = PenalizedPlayer(playerName, hash, ip, sid, playerId);
        pPlayer.m_penaltyTimer = time;

        m_penaltymanager.startPenalty(pPlayer);
        m_penaltymanager.m_trackedPlayers.add(pPlayer);
        m_penaltymanager.m_persistentTrackedPlayers.add(pPlayer);
        sendPrivateMessage(m_metagame, senderId, playerName + " 被TK " + time + " 秒！");
    }

    // 解tk admin专用
    void command_jietk_admin(int playerId, int senderId) {
        const XmlElement@ tkPlayer = getPlayerInfo(m_metagame, playerId);
        if (tkPlayer is null) {
            sendPrivateMessage(m_metagame, senderId, "没有此玩家!!!!!!!!!!!!!");
            return;
        }

        string hash = tkPlayer.getStringAttribute("profile_hash");
        string ip = tkPlayer.getStringAttribute("ip");
        string sid = tkPlayer.getStringAttribute("sid");
        array<const XmlElement@> playerList = getPlayers(m_metagame);
        string playerName = "";
        for (uint i = 0; i < playerList.size(); ++i) {
            if (playerId == playerList[i].getIntAttribute("player_id")) {
                playerName = playerList[i].getStringAttribute("name");
            }
        }

        if (playerName == "") {
            sendPrivateMessage(m_metagame, senderId, "没有此玩家!!!!!!!!!!!!!");
            return;
        }

        if (m_penaltymanager.m_persistentTrackedPlayers.exists(sid)) {
            PenalizedPlayer@ pPlayer;
            @pPlayer = m_penaltymanager.m_persistentTrackedPlayers.get(sid);
            if (pPlayer !is null && pPlayer.m_penaltyTimer >= 0) {
                pPlayer.m_penaltyTimer = -1.0;

                m_penaltymanager.endPenalty(pPlayer);
                sendPrivateMessage(m_metagame, 0, playerName + " 被解除TK！");
            }
        }
    }

	// ----------------------------------------------------
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
		const XmlElement@ senderInfo = getPlayerInfo(m_metagame, senderId);
		int characterId = senderInfo.getIntAttribute("character_id");
		const XmlElement@ characterInfo = getCharacterInfo(m_metagame, characterId);
		string senderPos = characterInfo.getStringAttribute("position");
		string senderSid = senderInfo.getStringAttribute("sid");
		array<string> command_arr = message.split(" ");

		// admin only from here on
		if (!m_metagame.getAdminManager().isAdmin(sender, senderId)) {
			if (checkCommand(message, "jietk")) {
                command_jietk(senderSid, senderInfo, sender, senderId, characterInfo, characterId);
            }

            //如果已被tk，不能用命令
            if (is_tk(senderSid)) {
                sendPrivateMessage(m_metagame, senderId, "you are a team killer !");
                return;
            }

            if (checkCommand(message, "buy ") && ENABLE_COMMAND_BUY == true) {
            	// /buy 1
            	command_buy(parseInt(command_arr[1]), senderPos, characterId, characterInfo);
			} else if (checkCommand(message, "ljt ") && ENABLE_COMMAND_LJT == true) {
				// /ljt
				command_ljt(senderPos, characterId, characterInfo);
			} else if (checkCommand(message, "pd ") && ENABLE_COMMAND_PD == true) {
				// /pd 1
				command_pd(parseInt(command_arr[1]), characterId, characterInfo);
			} else if (checkCommand(message, "help ") && ENABLE_COMMAND_HELP == true) {
				// /help 1
				command_help(parseInt(command_arr[1]), senderPos, characterId, characterInfo);
			}

			return;
		}

        // 管理员命令
        if (checkCommand(message, "buy ")) {
            // /buy 1
            command_buy(parseInt(command_arr[1]), senderPos, characterId, characterInfo);
        } else if (checkCommand(message, "wudi ")) {
            // /wudi 10
            command_wudi(parseInt(command_arr[1]), senderId, characterId, characterInfo);
        } else if (checkCommand(message, "ljt")) {
            // /ljt
            command_ljt(senderPos, characterId, characterInfo);
        } else if (checkCommand(message, "pd ")) {
            // /pd 1
            command_pd(parseInt(command_arr[1]), characterId, characterInfo);
        } else if (checkCommand(message, "help ")) {
            // /help 1
            command_help(parseInt(command_arr[1]), senderPos, characterId, characterInfo);
        } else if (checkCommand(message, "players")) {
			command_players(senderId);
		} else if (checkCommand(message, "w ")) {
            // /w aks74u 10
            int num = 1;
            if (command_arr.length() == 3) {
                num = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                num = 1;
            } else if (command_arr.length() == 1) {
                return;
            }
            spawnInstanceAtPos(senderPos, command_arr[1] + ".weapon", "weapon", 0.8, 0.0, 0.0, 0, num);
        } else if (checkCommand(message, "i ")) {
            // /i laptop 10
            int num = 1;
            if (command_arr.length() == 3) {
                num = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                num = 1;
            } else if (command_arr.length() == 1) {
                return;
            }
            spawnInstanceAtPos(senderPos, command_arr[1] + ".carry_item", "carry_item", 0.8, 0.0, 0.0, 0, num);
        } else if (checkCommand(message, "v ")) {
            int num = 1;
            if (command_arr.length() == 3) {
                num = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                num = 1;
            } else if (command_arr.length() == 1) {
                return;
            }
            spawnInstanceAtPos(senderPos, command_arr[1] + ".vehicle", "vehicle", 4.0, 0.0, 0.0, num);
        } else if (checkCommand(message, "ai ")) {
            // /ai 0 10
            int num = 1;
            if (command_arr.length() == 3) {
                num = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                num = 1;
            } else if (command_arr.length() == 1) {
                return;
            }
            spawnInstanceAtPos(senderPos, "default", "soldier", 2.0, 0.0, 0.0, parseInt(command_arr[1]), num);
        } else if (checkCommand(message, "eod ")) {
            int num = 1;
            if (command_arr.length() == 3) {
                num = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                num = 1;
            } else if (command_arr.length() == 1) {
                return;
            }
            spawnInstanceAtPos(senderPos, "eod", "soldier", 2.0, 0.0, 0.0, parseInt(command_arr[1]), num);
        } else if (checkCommand(message, "mb ")) {
            int num = 1;
            if (command_arr.length() == 3) {
                num = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                num = 1;
            } else if (command_arr.length() == 1) {
                return;
            }
            spawnInstanceAtPos(senderPos, "miniboss", "soldier", 2.0, 0.0, 0.0, parseInt(command_arr[1]), num);
        } else if (checkCommand(message, "fmb ")) {
            int num = 1;
            if (command_arr.length() == 3) {
                num = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                num = 1;
            } else if (command_arr.length() == 1) {
                return;
            }
            spawnInstanceAtPos(senderPos, "miniboss_female", "soldier", 2.0, 0.0, 0.0, parseInt(command_arr[1]), num);
        } else if (checkCommand(message, "jietk ")) {
            // /jietk 1
            command_jietk_admin(parseInt(command_arr[1]), senderId);
        } else if (checkCommand(message, "tk ")) {
            // /tk 1 3600
            int time = 3600;
            if (command_arr.length() == 3) {
                time = parseInt(command_arr[2]);
            } else if (command_arr.length() == 2) {
                time = 3600;
            } else if (command_arr.length() == 1) {
                return;
            }
            command_tk(parseInt(command_arr[1]), senderId, time);
        }

        else if (checkCommand(message, "test2")) {
			// it's a silent server command, check which one
			string command = "<command class='set_marker' faction_id='0' position='512 0 512' color='0 0 1' atlas_index='0' text='hello!' />";
			m_metagame.getComms().send(command);
		} else if (checkCommand(message, "test")) {
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "test yourself!"}};
			m_metagame.getComms().send(XmlElement(dict));

		} else if (checkCommand(message, "defend")) {
			// make ai defend only, both sides
			for (int i = 0; i < 2; ++i) {
				string command =
					"<command class='commander_ai'" +
					"	faction='" + i + "'" +
					"	base_defense='1.0'" +
					"	border_defense='0.0'>" +
					"</command>";
				m_metagame.getComms().send(command);
			}
			sendPrivateMessage(m_metagame, senderId, "defensive ai set");

		} else if (checkCommand(message, "0_attack")) {
			// make ai defend only, both sides
			string command =
				"<command class='commander_ai'" +
				"	faction='0'" +
				"	base_defense='0.0'" +
				"	border_defense='0.0'>" +
				"</command>";
			m_metagame.getComms().send(command);
			sendPrivateMessage(m_metagame, senderId, "attack green ai set");

		} else if (checkCommand(message, "0_win")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");
		} else if (checkCommand(message, "1_win")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='0' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='1' />");
		} else if (checkCommand(message, "1_lose")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
		} else if (checkCommand(message, "1_own")) {
			int factionId = 1;
			array<const XmlElement@> bases = getBases(m_metagame);
			for (uint i = 0; i < bases.size(); ++i) {
				const XmlElement@ base = bases[i];
				if (base.getIntAttribute("owner_id") != factionId) {
					XmlElement command("command");
					command.setStringAttribute("class", "update_base");
					command.setIntAttribute("base_id", base.getIntAttribute("id"));
					command.setIntAttribute("owner_id", factionId);
					m_metagame.getComms().send(command);
				}
			}
		} else if (checkCommand(message, "kick ")) {
			// /kick 1
			command_kick(parseInt(command_arr[1]));
			//handleKick(message, senderId);
		} else if (checkCommand(message, "whereami")) {
			_log("whereami received", 1);
			if (characterInfo !is null) {
				@characterInfo = getCharacterInfo(m_metagame, characterId);
				if (characterInfo !is null) {
					string posStr = characterInfo.getStringAttribute("position");
					Vector3 pos = stringToVector3(posStr);
					string region = m_metagame.getRegion(pos);

					string text = posStr + ", " + region;

					sendPrivateMessage(m_metagame, senderId, text);
				} else {
					_log("character info not ok", 1);
				}
			} else {
				_log("player info not ok", 1);
			}
		} else  if(checkCommand(message, "kill_aa")) {
			for (uint f = 1; f < 3; ++f) {
				array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, "aa_emplacement.vehicle");
				
				for (uint i = 0; i < vehicles.size(); ++i) {
					const XmlElement@ vehicle = vehicles[i];
					int id = vehicle.getIntAttribute("id");
					destroyVehicle(m_metagame, id);
				}
			}
		} else  if(checkCommand(message, "promote")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info !is null) {
				int id = info.getIntAttribute("character_id");
				string command =
					"<command class='xp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='0.4'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
			} else {
				_log("player info is null");
			}
		} else if (checkCommand(message, "rp")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info !is null) {
				int id = info.getIntAttribute("character_id");
				string command =
					"<command class='rp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='5000'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
			}
		} else if (checkCommand(message, "_create_vehicle")) {
			spawnInstanceNearPlayer(senderId, "special_cargo_vehicle1.vehicle", "vehicle");
		} else if (checkCommand(message, "_jeep")) {
			spawnInstanceNearPlayer(senderId, "jeep.vehicle", "vehicle");
		} else  if(checkCommand(message, "_suitcase")) {
			// .. create suitcase near local player
			spawnInstanceNearPlayer(senderId, "suitcase.carry_item", "carry_item");
		} else  if(checkCommand(message, "_laptop")) {
			// .. create laptop near local player
			spawnInstanceNearPlayer(senderId, "laptop.carry_item", "carry_item");      
		} else if (checkCommand(message, "_dgl")) {
			spawnInstanceNearPlayer(senderId, "gl_resource.weapon", "weapon");
		} else if (checkCommand(message, "_m72")) {
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
		} else if (checkCommand(message, "_g36")) {
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
		} else if (checkCommand(message, "_cargo")) {
			spawnInstanceNearPlayer(senderId, "cargo_truck.vehicle", "vehicle", 1);
		} else if (checkCommand(message, "_tank")) {
			spawnInstanceNearPlayer(senderId, "tank.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "_1")) {
			spawnInstanceNearPlayer(senderId, "tow.vehicle", "vehicle", 1);
		} else if (checkCommand(message, "_2")) {
			spawnInstanceNearPlayer(senderId, "teddy.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "_3")) {
			spawnInstanceNearPlayer(senderId, "suitcase.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "friend")) {
			spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
		} else if (checkCommand(message, "foe")) {
			spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
		} else if (checkCommand(message, "_gb1")) {
			spawnInstanceNearPlayer(senderId, "gift_box_1.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "_gb2")) {
			spawnInstanceNearPlayer(senderId, "gift_box_2.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "_gb3")) {
			spawnInstanceNearPlayer(senderId, "gift_box_3.carry_item", "carry_item", 0);        
		} else if (checkCommand(message, "_quad")) {
			spawnInstanceNearPlayer(senderId, "atv_armory.vehicle", "vehicle", 0);        
		} else if (checkCommand(message, "_m29")) {
			spawnInstanceNearPlayer(senderId, "model_29.weapon", "weapon", 0);        
		} else  if(checkCommand(message, "kill_rt")) {
			destroyAllEnemyVehicles("radar_tower.vehicle");
		} else  if(checkCommand(message, "kill_rj")) {
			destroyAllEnemyVehicles("radio_jammer.vehicle");
		} else  if(checkCommand(message, "mustela")) {
			spawnInstanceNearPlayer(senderId, "wiesel_tow.vehicle", "vehicle", 0);        
		}
	}

	// --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}

	// --------------------------------------------
	void handleKick(string message, int senderId) {
		//sendPrivateMessage(m_metagame, senderId, "kicking!");

		// get name given as parameter
		string name = message.substr(string("kick ").length() + 1);

		// assuming player name 
		// ask for player list from the server
		array<const XmlElement@> playerList = getPlayers(m_metagame);
		_log("* "  + playerList.size() + " players found");
		
		// go through the player list and match for the given name
		int playerId = -1;
		for (uint i = 0; i < playerList.size(); ++i) {
			const XmlElement@ player = playerList[i];
			string name2 = player.getStringAttribute("name");
			// case insensitive
			if (name2.toLowerCase() == name.toLowerCase()) {
				// found it
				playerId = player.getIntAttribute("player_id");
				break;
			}
		}

		if (playerId >= 0) {
			// ok player id, now kick
			notify(m_metagame, "kicking player", dictionary = {{"%player_name", name}}, "misc");
			string command = "<command class='kick_player' player_id='" + playerId + "' />";
			m_metagame.getComms().send(command);
		} else {
			_log("* couldn't find a match for " + name);
			sendPrivateMessage(m_metagame, senderId, "kick missed!");
		}
	}

	// ----------------------------------------------------
	protected void spawnInstanceNearPlayer(int senderId, string key, string type, int factionId = 0) {
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		if (playerInfo !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				Vector3 pos = stringToVector3(characterInfo.getStringAttribute("position"));
				pos.m_values[0] += 5.0;
				string c = "<command class='create_instance' instance_class='" + type + "' instance_key='" + key + "' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
				m_metagame.getComms().send(c);
			}
		}
	}

	// ----------------------------------------------------
	protected void destroyAllEnemyVehicles(string key) {
		for (uint f = 1; f < 3; ++f) {
			array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, key);
			
			for (uint i = 0; i < vehicles.size(); ++i) {
				const XmlElement@ vehicle = vehicles[i];
				int id = vehicle.getIntAttribute("id");
				destroyVehicle(m_metagame, id);
			}
		}
	}

    //在某坐标放置物品
    protected void spawnInstanceAtPos(string toPos, string key, string type, float x = 0.0, float z = 0.0, float y = 0.0, int factionId = 0, int num = 1) {
        if (num < 1) {
            return;
        }

        Vector3 pos = stringToVector3(toPos);
        pos.m_values[0] += x;
        pos.m_values[1] += z;
        pos.m_values[2] += y;
        string c = "";

        for (int i = 1; i <= num; ++i) {
            c = "<command class='create_instance' instance_class='" + type + "' instance_key='" + key + "' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
            m_metagame.getComms().send(c);
        }
    }

    //给玩家背包里添加物品
    protected void addItemInPlayerBackpack(int characterId, string name, string type, int num = 1) {
        if (num < 1) {
            return;
        }

        string c = "<command class='update_inventory' character_id='" + characterId + "' container_type_class='backpack'>";
        for (int i = 1; i <= num; ++i) {
            c += "<item class='" + type + "' key='" + name + "." + type + "' />";
        }
        c += "</command>";

        m_metagame.getComms().send(c);
    }

    //给玩家物品
    protected void addItemToPlayer(int characterId, string name, string type, int containerType, int num = 1) {
        if (num < 1) {
            return;
        }

        string c = "<command class='update_inventory' character_id='" + characterId + "' container_type_id='" + containerType + "'>";
        for (int i = 1; i <= num; ++i) {
            c += "<item class='" + type + "' key='" + name + "." + type + "' />";
        }
        c += "</command>";

        m_metagame.getComms().send(c);
    }
}