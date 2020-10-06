-- =============================================================================
-- CUI Ingame Text - [Deutsch] von [Titule]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("de_DE", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Bürger und Kacheln verwalten"),

-- =============================================================================
-- City States Panel
("de_DE", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Gesandte gesamt: {1_num}, Suzerän aktiv: {2_num}"),

-- =============================================================================
-- Deal Panel
("de_DE", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "L-Klick Hinzufügen, R-Klick Abziehen"),
("de_DE", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "Das hat dieser Anführer bereits"),
("de_DE", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "Das habt Ihr bereits"),
("de_DE", "LOC_CUI_DP_WE_HAVE_ONLY_ONE_TOOLTIP",                                "Ihr habt nur 1 Einheit davon"),

-- =============================================================================
-- Diplomatic Banner
("de_DE", "LOC_CUI_DB_CITY",                                                    "Städte: {1_num}"),
("de_DE", "LOC_CUI_DB_RELIGION",                                                "Religion: {1_name}"),
("de_DE", "LOC_CUI_DB_NONE",                                                    "Keine"),
("de_DE", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Friedensabkommen verfügbar]"),
("de_DE", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Friedensabkommen: {1_Remaining}[ICON_TURN]]"),
("de_DE", "LOC_CUI_DB_RELATIONSHIP",                                            "Beziehung: {1_Relationship}"),
("de_DE", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "Keine Missstände"),
("de_DE", "LOC_CUI_DB_GRIEVANCES",                                              "Missstände: {1_Grievances}"),
("de_DE", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "Ressourcen die dieser Anführer bietet:"),
("de_DE", "LOC_CUI_DB_WE_CAN_OFFER",                                            "Ressourcen die Ihr bieten könnt:"),
("de_DE", "LOC_CUI_DB_GOLD",                                                    "Gold:"),
("de_DE", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Gold und Diplomatische Gefallen:"),
("de_DE", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Punkte und Erträge:"),
("de_DE", "LOC_CUI_DB_MARS_PROJECT",                                            "Marskolonie: {1_progress}  {2_progress}  {3_progress}"),
("de_DE", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Exoplanet Expedition: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("de_DE", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Touristen: {1_num} / {2_total}"),
("de_DE", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Übernommene Hauptstädte: {1_num}"),
("de_DE", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Konvertierte Zivilisationen: {1_num} / {2_total}"),
("de_DE", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Diplomatiesiegespunkte: {1_num} / {2_total}"),

-- =============================================================================
-- Minimap Panel
("de_DE", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Bezirksymbole anzeigen"),
("de_DE", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Weltwundersymbole anzeigen"),
("de_DE", "LOC_CUI_MP_AUTONAMING",                                              "Benennen"),
("de_DE", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Nadeln automatisch benennen"),
("de_DE", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Strategische Ressourcensymbole"),
("de_DE", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Strategische Ressourcensymbole ein/aus"),
("de_DE", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Einheitenflaggen"),
("de_DE", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Einheitenflaggen ein/aus"),
("de_DE", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Städtebanner"),
("de_DE", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Städtebanner ein/aus"),
("de_DE", "LOC_CUI_MO_SHOW_TRADERS",                                            "Händler"),
("de_DE", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Händler ein/aus"),
("de_DE", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Religionseinheiten"),
("de_DE", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Religionseinheiten ein/aus"),

-- =============================================================================
-- SpyInfo
("de_DE", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Spion; other?Spione;} verfügbar"),
("de_DE", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Spion; other?Spione;} möglich"),

-- =============================================================================
-- World Tracker
("de_DE", "LOC_CUI_WT_GOSSIP_LOG",                                              "Gerüchte"),
("de_DE", "LOC_CUI_WT_COMBAT_LOG",                                              "Kampfberichte"),

-- =============================================================================
-- Production Panel
("de_DE", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Immer Bauliste verwenden"),

-- =============================================================================
-- Great Works
("de_DE", "LOC_CUI_GW_SORT_BY_CITY",                                            "Nach Stadt sortieren"),
("de_DE", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Nach Gebäude sortieren"),
("de_DE", "LOC_CUI_GW_THEMING_HELPER",                                          "Themamatisierungs Helfer"),
("de_DE", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Wähle drei Große Werke oder Artefakte der gleichen Farbe und verschiedenen Nummern, um ein Thema zu vervollständigen."),

-- =============================================================================
-- Notes
("de_DE", "LOC_CUI_NOTES",                                                      "Notizen"),
("de_DE", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Zug: {1_num} ]"),
("de_DE", "LOC_CUI_NOTE_EMPTY",                                                 "Leere Notiz"),

-- =============================================================================
-- Options
("de_DE", "LOC_CUI_OPTIONS_TAB_VICTORY",                                        "Siege"),
("de_DE", "LOC_CUI_OPTIONS_TAB_LOG",                                            "Aufzeichnungen"),
("de_DE", "LOC_CUI_OPTIONS_TAB_POPUP",                                          "Pop-ups"),
("de_DE", "LOC_CUI_OPTIONS_TAB_REMIND",                                         "Benachrichtigungen"),
--
("de_DE", "LOC_CUI_OPTIONS_DESC_VICTORY",                                       "Wählt den Sieg, den Ihr verfolgen möchtet."),
("de_DE", "LOC_CUI_OPTIONS_DESC_LOG",                                           "Wählt den Ort, an dem Eure Aufzeichnungen angezeigt werden sollen."),
("de_DE", "LOC_CUI_OPTIONS_DESC_POPUP",                                         "Wählt die Pop-ups, die Ihr aktivieren möchtet."),
("de_DE", "LOC_CUI_OPTIONS_DESC_REMIND",                                        "Wählt die Benachrichtigungen, die Ihr verwenden möchtet."),
("de_DE", "LOC_CUI_OPTIONS_DESC_SPEED",                                         "Wählt das Verhalten von Schnellkampf- und Schnellfortbewegungsobjekte."),
--
("de_DE", "LOC_CUI_OPTIONS_LOG_SHOW_NONE",                                      "Deaktivieren"),
("de_DE", "LOC_CUI_OPTIONS_LOG_DEFAULT",                                        "Standardposition"),
("de_DE", "LOC_CUI_OPTIONS_LOG_WORLDTRACKER",                                   "Fortschrittsanzeige"),
("de_DE", "LOC_CUI_OPTIONS_LOG_BOTH",                                           "Beide"),
--
("de_DE", "LOC_CUI_OPTIONS_POPUP_RESEARCH",                                     "Technologie oder Ausrichtung abgeschlossen"),
("de_DE", "LOC_CUI_OPTIONS_POPUP_AUDIO",                                        "Technologie oder Ausrichtung akustisches Signal"),
("de_DE", "LOC_CUI_OPTIONS_POPUP_ERA_SCORE",                                    "Zeitalterpunkte erhalten"),
("de_DE", "LOC_CUI_OPTIONS_POPUP_GREAT_WORK",                                   "Große Werke verfügbar"),
("de_DE", "LOC_CUI_OPTIONS_POPUP_RELIC",                                        "Relikte erhalten"),
--
("de_DE", "LOC_CUI_OPTIONS_REMIND_TECH",                                        "Technologie durch Heureka abgeschlossen"),
("de_DE", "LOC_CUI_OPTIONS_REMIND_CIVIC",                                       "Ausrichtung durch Inspiration abgeschlossen"),
("de_DE", "LOC_CUI_OPTIONS_REMIND_GOVERNMENT",                                  "Kostenlose Änderungen an der Regierung"),
("de_DE", "LOC_CUI_OPTIONS_REMIND_GOVERNOR",                                    "Gouverneur-Titel verfügbar"),
--
("de_DE", "LOC_CUI_OPTIONS_QUICK_COMBAT",                                       "Schnellkampf"),
("de_DE", "LOC_CUI_OPTIONS_QUICK_MOVEMENT",                                     "Schnellfortbewegung"),
("de_DE", "LOC_CUI_OPTIONS_SPEED_PLAYER_ONLY",                                  "Nur Spieler"),
("de_DE", "LOC_CUI_OPTIONS_SPEED_AI_ONLY",                                      "Nur KI"),

-- =============================================================================
-- Screenshot
("de_DE", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Screenshot-Modus aufrufen[NEWLINE][NEWLINE]Im Screenshot-Modus werden die meisten UI-Elemente verborgen.[NEWLINE][NEWLINE]Linksklick verbirgt alle UI Elemente[NEWLINE]Rechtsklick verbirgt alle UI Elemente außer Stadtbanner[NEWLINE]Halte ALT gedrückt, um die Ansicht zu drehen[NEWLINE]Drücke ESC um den Screenshot-Modus zu verlassen."),

-- =============================================================================
("de_DE", "LOC_CUI_COLON", ": ");
-- EOF
