// generated by atlas.exe
string getWorldPosition(string key) {
	dictionary positions = {
		{'map2', '269.101 461.328'},
		{'map4', '511.153 201.937'},
		{'map3', '740.537 429.07'},
		{'map1', '497.407 418.311'},
		{'map8', '330.926 616.358'},
		{'map6', '470.495 597.582'},
		{'map7', '645.051 551.191'},
		{'map5', '294.27 753.819'},
		{'map9', '780.731 664.215'},
		{'map10', '600.48 808.56'},
		{'map11', '242.787 228.112'},
		{'map12', '730.074 197.318'}
	};
	string p;
	positions.get(key, p);
	return p;
}

Marker getWorldMarker(string key) {
	dictionary rects = {
		{'map_point', '0.812474 0.651041 0.84914 0.687708'},
		{'cursor', '0.809166 0.751654 0.845935 0.791252'},
		{'advance', '0.903339 0.742068 0.954722 0.79675'},
		{'boss', '0.814 0.811667 0.847833 0.844833'}
	};
	dictionary sizes = {
		{'map_point', '64 64'},
		{'cursor', '64 64'},
		{'advance', '64 64'},
		{'boss', '64 64'}
	};
	Marker marker;
	rects.get(key, marker.m_rect);
	sizes.get(key, marker.m_size);
	return marker;
}
