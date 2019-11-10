-- =============================================================================
-- CUI Ingame Text - [English] by [eudaimonia]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("en_US", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Manage Citizens and Tiles"),

-- =============================================================================
-- City States Panel
("en_US", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Envoys Sent: {1_num}, Suzerain of: {2_num}"),

-- =============================================================================
-- Deal Panel
("en_US", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "L-Click Add, R-Click Subtract"),
("en_US", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "They already have"),
("en_US", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "We already have"),

-- =============================================================================
-- Diplomatic Banner
("en_US", "LOC_CUI_DB_CITY",                                                    "Cities: {1_num}"),
("en_US", "LOC_CUI_DB_RELIGION",                                                "Religion: {1_name}"),
("en_US", "LOC_CUI_DB_NONE",                                                    "None"),
("en_US", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Peace Deal is Available]"),
("en_US", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Peace Deal: {1_Remaining}[ICON_TURN]]"),
("en_US", "LOC_CUI_DB_RELATIONSHIP",                                            "Relationship: {1_Relationship}"),
("en_US", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "No Grievances"),
("en_US", "LOC_CUI_DB_GRIEVANCES",                                              "Grievances: {1_Grievances}"),
("en_US", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "They can offer:"),
("en_US", "LOC_CUI_DB_WE_CAN_OFFER",                                            "We can offer:"),
("en_US", "LOC_CUI_DB_GOLD",                                                    "Gold:"),
("en_US", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Gold and Diplomatic Favors:"),
("en_US", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Score and Yields:"),
("en_US", "LOC_CUI_DB_MARS_PROJECT",                                            "Mars Colony: {1_progress}  {2_progress}  {3_progress}"),
("en_US", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Exoplanet Expedition: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("en_US", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Visiting Tourists: {1_num} / {2_total}"),
("en_US", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Capitals Captured: {1_num}"),
("en_US", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Civilizations Converted: {1_num} / {2_total}"),
("en_US", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Diplomatic Victory Point: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("en_US", "LOC_CUI_EP_FILTER_ALL",                                              "All"),
("en_US", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "Show Cities"),

-- =============================================================================
-- Minimap Panel
("en_US", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Show Districts Icons"),
("en_US", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Show Wonders Icons"),
("en_US", "LOC_CUI_MP_AUTONAMING",                                              "Naming"),
("en_US", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Auto-naming pins"),
("en_US", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Show Improved Resource Icons"),
("en_US", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Toggle Improved Resource Icons"),
("en_US", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Show Unit Flags"),
("en_US", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Toggle Unit Flags"),
("en_US", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Show City Banners"),
("en_US", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Toggle City Banners"),
("en_US", "LOC_CUI_MO_SHOW_TRADERS",                                            "Show Traders"),
("en_US", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Toggle Trader Flags"),
("en_US", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Show Religion Units"),
("en_US", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Toggle Religion Flags"),

-- =============================================================================
-- Report Screen
("en_US", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Show City Details"),
("en_US", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Number of Buildings"),
("en_US", "LOC_CUI_RS_TOTALS",                                                  "Totals: {1_num}"),
("en_US", "LOC_CUI_RS_DEALS_OUTGOING",                                          "Outgoing"),
("en_US", "LOC_CUI_RS_DEALS_INCOMING",                                          "Incoming"),

-- =============================================================================
-- SpyInfo
("en_US", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} available"),
("en_US", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} capacity"),

-- =============================================================================
-- World Tracker
("en_US", "LOC_CUI_WT_REMINDER",                                                "Reminder"),
("en_US", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "The background color changes to green when the technology can be finished by getting an Eureka."),
("en_US", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "The background color changes to green when the civic can be finished by getting an Inspiration."),
("en_US", "LOC_CUI_WT_GOSSIP_LOG",                                              "Gossip Log"),
("en_US", "LOC_CUI_WT_COMBAT_LOG",                                              "Combat Log"),
("en_US", "LOC_CUI_WT_PERSIST",                                                 "Persist"),
("en_US", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "Do not clear the gossip log between turns."),
("en_US", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "Do not clear the combat log between turns."),

-- =============================================================================
-- Trade Panel
("en_US", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Sort by [ICON_Food]Food."),
("en_US", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Sort by [ICON_Production]Production."),
("en_US", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Sort by [ICON_Gold]Gold."),
("en_US", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Sort by [ICON_Science]Science."),
("en_US", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Sort by [ICON_Culture]Culture."),
("en_US", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Sort by [ICON_Faith]Faith."),
("en_US", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Sort by [ICON_Turn]Turns to complete route."),
("en_US", "LOC_CUI_TP_REPEAT",                                                  "Repeat"),
("en_US", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "To have this trader repeat this trade route indefinitely."),
("en_US", "LOC_CUI_TP_SELECT_A_CITY",                                           "Select a New Origin City."),

-- =============================================================================
-- Espionage Panel
("en_US", "LOC_CUI_EP_SHOW_CITYS",                                              "Show Cities"),
("en_US", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Gain ({1_GoldString}) Gold yields."),

-- =============================================================================
-- Production Panel
("en_US", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Use Queue By Default"),

-- =============================================================================
-- Great Works
("en_US", "LOC_CUI_GW_SORT_BY_CITY",                                            "Sort By City"),
("en_US", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Sort By Building"),
("en_US", "LOC_CUI_GW_THEMING_HELPER",                                          "Theming Helper"),
("en_US", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Pick three Great Works / Artifacts of the same color and different numbers to complete a theme."),

-- =============================================================================
-- Notes
("en_US", "LOC_CUI_NOTES",                                                      "Notes"),
("en_US", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Last edited at turn: {1_num} ]"),
("en_US", "LOC_CUI_NOTE_EMPTY",                                                 "Empty Note"),

-- =============================================================================
-- Screenshot
("en_US", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Enter Screenshot Mode[NEWLINE][NEWLINE]Screenshot Mode will hide most or all UI Elements, allows you to take clean screenshots.[NEWLINE][NEWLINE]Left-click hide all UI Elements[NEWLINE]Right-click hide all UI Elements except for City Banners[NEWLINE]Hold ALT to rotate the screen[NEWLINE]Press ESC to exit Screenshot Mode"),

-- =============================================================================
("en_US", "LOC_CUI_COLON", ": ");
-- EOF