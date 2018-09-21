// declare include paths
#include "path://media/packages/vanilla/scripts"

#include "gamemode_campaign.as"

// --------------------------------------------
void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	UserSettings settings;
	settings.m_initialRp = 50;
	settings.fromXmlElement(inputSettings);

	_setupLog(inputSettings);
	//_setupLog("dev_verbose");

	settings.print();

	GameModeCampaign metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
