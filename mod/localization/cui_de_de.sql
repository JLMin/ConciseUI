-- =============================================================================
-- CUI Ingame Text - [Deutsch] von [Titule]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("de_DE", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Bürger und Kacheln verwalten"),

-- =============================================================================
-- City States Panel
("de_DE", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Gesandte: {1_num}, Suzerän von: {2_num}"),

-- =============================================================================
-- Deal Panel
("de_DE", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "L-Klick Hinzufügen, R-Click Abziehen"),
("de_DE", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "Das haben sie schon"),
("de_DE", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "Das haben wir schon"),

-- =============================================================================
-- Diplomatic Banner
("de_DE", "LOC_CUI_DB_CITY",                                                    "Städte: {1_num}"),
("de_DE", "LOC_CUI_DB_RELIGION",                                                "Religion: {1_name}"),
("de_DE", "LOC_CUI_DB_NONE",                                                    "Keine"),
("de_DE", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Friede ist möglich]"),
("de_DE", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Friede: {1_Remaining}[ICON_TURN]]"),
("de_DE", "LOC_CUI_DB_RELATIONSHIP",                                            "Beziehung: {1_Relationship}"),
("de_DE", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "keine Beschwerden"),
("de_DE", "LOC_CUI_DB_GRIEVANCES",                                              "beschwerden: {1_Grievances}"),
("de_DE", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "Sie können bieten:"),
("de_DE", "LOC_CUI_DB_WE_CAN_OFFER",                                            "Wir können bieten:"),
("de_DE", "LOC_CUI_DB_GOLD",                                                    "Gold:"),
("de_DE", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Gold und diplomatische Gefallen:"),
("de_DE", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Punkte und Erträge:"),
("de_DE", "LOC_CUI_DB_MARS_PROJECT",                                            "Marskolonie: {1_progress}  {2_progress}  {3_progress}"),
("de_DE", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Exoplanet Expedition: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("de_DE", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Besuch von Touristen: {1_num} / {2_total}"),
("de_DE", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Übernommene Hauptstädte: {1_num}"),
("de_DE", "LOC_CUI_DB_CIVS_CONVERTED",                                          "konvertierte Zivilisationen: {1_num} / {2_total}"),
("de_DE", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Diplomatiesiegespunkte: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("de_DE", "LOC_CUI_EP_FILTER_ALL",                                              "Alle"),
("de_DE", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "zeige Städte"),

-- =============================================================================
-- Minimap Panel
("de_DE", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Bezirksymbole anzeigen"),
("de_DE", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Weltwundersymbole anzeigen"),
("de_DE", "LOC_CUI_MP_AUTONAMING",                                              "Benennen"),
("de_DE", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Nadeln automatisch benennen"),
("de_DE", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "strategische Ressourcenysmbole anzeigen"),
("de_DE", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "strategische Ressourcenysmbole umschalten"),
("de_DE", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Einheitenflagge anzeigen"),
("de_DE", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Einheitenflagge umschalten"),
("de_DE", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Stadtbanner anzeigen"),
("de_DE", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Stadtbanner umschalten"),
("de_DE", "LOC_CUI_MO_SHOW_TRADERS",                                            "Handelsymbole anzeigen"),
("de_DE", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Handelsymbole umschalten"),
("de_DE", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Show Religion Units"),
("de_DE", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Toggle Religion Flags"),

-- =============================================================================
-- Report Screen
("de_DE", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Stadtdetails anzeigen"),
("de_DE", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Anzahl der Gebäude"),
("de_DE", "LOC_CUI_RS_TOTALS",                                                  "Gesamt: {1_num}"),
("de_DE", "LOC_CUI_RS_DEALS_OUTGOING",                                          "Eingehend"),
("de_DE", "LOC_CUI_RS_DEALS_INCOMING",                                          "Ausgehend"),

-- =============================================================================
-- SpyInfo
("de_DE", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Spion; other?Spione;} verfügbar"),
("de_DE", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Spion; other?Spione;} möglich"),

-- =============================================================================
-- World Tracker
("de_DE", "LOC_CUI_WT_REMINDER",                                                "Erinnern"),
("de_DE", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "Die Hintergrundfarbe wird grün wenn die Technologie mit einem Eureka vollständig erforscht werden kann."),
("de_DE", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "Die Hintergrundfarbe wird grün wenn die Ausrichtung surch eine Inspiration abgeschlossen werden kann."),
("de_DE", "LOC_CUI_WT_GOSSIP_LOG",                                              "Gerüchte"),
("de_DE", "LOC_CUI_WT_COMBAT_LOG",                                              "Kampfberichte"),
("de_DE", "LOC_CUI_WT_PERSIST",                                                 "Beibehalten"),
("de_DE", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "Leert das Gerüchteprotokoll nicht zwischen den Runden."),
("de_DE", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "Leert den Kampfbericht nicht zwischen den Runden."),

-- =============================================================================
-- Trade Panel
("de_DE", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Nach [ICON_Food]Nahrung sortieren."),
("de_DE", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Nach [ICON_Production]Produktion sortieren."),
("de_DE", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Nach [ICON_Gold]Gold sortieren."),
("de_DE", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Nach [ICON_Science]Wissenschaft sortieren."),
("de_DE", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Nach [ICON_Culture]Kultur sortieren."),
("de_DE", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Nach [ICON_Faith]Glauben sortieren."),
("de_DE", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Nach Anzahl der [ICON_Turn]Züge zum Vervollständigen der Route sortieren."),
("de_DE", "LOC_CUI_TP_REPEAT",                                                  "Wiederholen"),
("de_DE", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "Immer wieder wiederholen."),
("de_DE", "LOC_CUI_TP_SELECT_A_CITY",                                           "Eine neue Ausgangsstadt auswählen."),

-- =============================================================================
-- Espionage Panel
("de_DE", "LOC_CUI_EP_SHOW_CITYS",                                              "Städte anzeigen"),
("de_DE", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Erhalte ({1_GoldString}) Gold."),

-- =============================================================================
-- Production Panel
("de_DE", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Immer Bauliste verwenden"),

-- =============================================================================
-- Great Works
("de_DE", "LOC_CUI_GW_SORT_BY_CITY",                                            "Nach Stadt sortieren"),
("de_DE", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Nach Gebäude sortieren"),
("de_DE", "LOC_CUI_GW_THEMING_HELPER",                                          "Thema Hilfe"),
("de_DE", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Wähle drei Große Werke / Artefakte der gleichen Farbe und mit verschiedenen Nummern um ein Thema zu vervollständigen."),

-- =============================================================================
-- Notes
("de_DE", "LOC_CUI_NOTES",                                                      "Notizen"),
("de_DE", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ zuletzt bearbeitet in Zug: {1_num} ]"),
("de_DE", "LOC_CUI_NOTE_EMPTY",                                                 "Leere Notiz"),

-- =============================================================================
-- Screenshot
("de_DE", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Screenshot-Modus aufrufen[NEWLINE][NEWLINE]Im Screenshot-Modus werden die meisten UI-Elemente verborgen.[NEWLINE][NEWLINE]Linksklick verbirgt alle UI Elemente[NEWLINE]Rechtsklick verbirgt alle UI Elemente außer Stadtbanner[NEWLINE]Halte ALT gedrückt um den Bildschirm zu rotieren[NEWLINE]Drücke ESC um den Screenshot-Modus zu verlassen."),

-- =============================================================================
("de_DE", "LOC_CUI_COLON", ": ");
-- EOF
