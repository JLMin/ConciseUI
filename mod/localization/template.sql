-- =============================================================================
-- CUI Ingame Text - [YOUR_LANGUAGE] by [YOUR_NAME]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- Config
("xx_XX", "LOC_CUI_CONFIG_CATEGORY",                                            "Concise UI"),
("xx_XX", "LOC_CUI_CONFIG_PLACE_MAP_PIN",                                       "Add Map Tack"),
("xx_XX", "LOC_CUI_CONFIG_TOGGLE_IMPROVED",                                     "Toggle Improved Resource"),
("xx_XX", "LOC_CUI_CONFIG_TOGGLE_UNIT_FLAGS",                                   "Toggle Unit Flags"),
("xx_XX", "LOC_CUI_CONFIG_TOGGLE_TRADERS",                                      "Toggle Trader Icons"),
("xx_XX", "LOC_CUI_CONFIG_TOGGLE_RELIGIONS",                                    "Toggle Religion Icons"),
("xx_XX", "LOC_CUI_CONFIG_TOGGLE_CITY_BANNERS",                                 "Toggle City Banners"),
("xx_XX", "LOC_CUI_CONFIG_OPEN_UNIT_LIST",                                      "Open Unit List"),

-- =============================================================================
-- City Panel
("xx_XX", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Manage Citizens and Tiles"),

-- =============================================================================
-- City States Panel
("xx_XX", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Envoys Sent: {1_num}, Suzerain of: {2_num}"),

-- =============================================================================
-- Deal Panel
("xx_XX", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "L-Click Add, R-Click Subtract"),
("xx_XX", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "They already have"),
("xx_XX", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "We already have"),

-- =============================================================================
-- Diplomatic Banner
("xx_XX", "LOC_CUI_DB_CITY",                                                    "Cities: {1_num}"),
("xx_XX", "LOC_CUI_DB_RELIGION",                                                "Religion: {1_name}"),
("xx_XX", "LOC_CUI_DB_NONE",                                                    "None"),
("xx_XX", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Peace Deal is Available]"),
("xx_XX", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Peace Deal: {1_Remaining}[ICON_TURN]]"),
("xx_XX", "LOC_CUI_DB_RELATIONSHIP",                                            "Relationship: {1_Relationship}"),
("xx_XX", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "No Grievances"),
("xx_XX", "LOC_CUI_DB_GRIEVANCES",                                              "Grievances: {1_Grievances}"),
("xx_XX", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "They can offer:"),
("xx_XX", "LOC_CUI_DB_WE_CAN_OFFER",                                            "We can offer:"),
("xx_XX", "LOC_CUI_DB_GOLD",                                                    "Gold:"),
("xx_XX", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Gold and Diplomatic Favors:"),
("xx_XX", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Score and Yields:"),
("xx_XX", "LOC_CUI_DB_MARS_PROJECT",                                            "Mars Colony: {1_progress}  {2_progress}  {3_progress}"),
("xx_XX", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Exoplanet Expedition: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("xx_XX", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Visiting Tourists: {1_num} / {2_total}"),
("xx_XX", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Capitals Captured: {1_num}"),
("xx_XX", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Civilizations Converted: {1_num} / {2_total}"),
("xx_XX", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Diplomatic Victory Point: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("xx_XX", "LOC_CUI_EP_FILTER_ALL",                                              "All"),
("xx_XX", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "Show Cities"),

-- =============================================================================
-- Minimap Panel
("xx_XX", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Show Districts Icons"),
("xx_XX", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Show Wonders Icons"),
("xx_XX", "LOC_CUI_MP_AUTONAMING",                                              "Naming"),
("xx_XX", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Auto-naming pins"),
("xx_XX", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Show Improved Resource Icons"),
("xx_XX", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Toggle Improved Resource Icons"),
("xx_XX", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Show Unit Flags"),
("xx_XX", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Toggle Unit Flags"),
("xx_XX", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Show City Banners"),
("xx_XX", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Toggle City Banners"),
("xx_XX", "LOC_CUI_MO_SHOW_TRADERS",                                            "Show Traders"),
("xx_XX", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Toggle Trader Flags"),
("xx_XX", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Show Religion Units"),
("xx_XX", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Toggle Religion Flags"),

-- =============================================================================
-- Report Screen
("xx_XX", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Show City Details"),
("xx_XX", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Number of Buildings"),
("xx_XX", "LOC_CUI_RS_TOTALS",                                                  "Totals: {1_num}"),
("xx_XX", "LOC_CUI_RS_DEALS_OUTGOING",                                          "Outgoing"),
("xx_XX", "LOC_CUI_RS_DEALS_INCOMING",                                          "Incoming"),

-- =============================================================================
-- SpyInfo
("xx_XX", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} available"),
("xx_XX", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} capacity"),

-- =============================================================================
-- World Tracker
("xx_XX", "LOC_CUI_WT_REMINDER",                                                "Reminder"),
("xx_XX", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "The background color changes to green when the technology can be finished by getting an Eureka."),
("xx_XX", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "The background color changes to green when the civic can be finished by getting an Inspiration."),
("xx_XX", "LOC_CUI_WT_GOSSIP_LOG",                                              "Gossip Log"),
("xx_XX", "LOC_CUI_WT_COMBAT_LOG",                                              "Combat Log"),
("xx_XX", "LOC_CUI_WT_PERSIST",                                                 "Persist"),
("xx_XX", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "Do not clear the gossip log between turns."),
("xx_XX", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "Do not clear the combat log between turns."),

-- =============================================================================
-- Trade Panel
("xx_XX", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Sort by [ICON_Food]Food."),
("xx_XX", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Sort by [ICON_Production]Production."),
("xx_XX", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Sort by [ICON_Gold]Gold."),
("xx_XX", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Sort by [ICON_Science]Science."),
("xx_XX", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Sort by [ICON_Culture]Culture."),
("xx_XX", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Sort by [ICON_Faith]Faith."),
("xx_XX", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Sort by [ICON_Turn]Turns to complete route."),
("xx_XX", "LOC_CUI_TP_REPEAT",                                                  "Repeat"),
("xx_XX", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "To have this trader repeat this trade route indefinitely."),
("xx_XX", "LOC_CUI_TP_SELECT_A_CITY",                                           "Select a New Origin City."),

-- =============================================================================
-- Espionage Panel
("xx_XX", "LOC_CUI_EP_SHOW_CITYS",                                              "Show Cities"),
("xx_XX", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Gain ({1_GoldString}) Gold yields."),

-- =============================================================================
-- Production Panel
("xx_XX", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Use Queue By Default"),

-- =============================================================================
-- Great Works
("xx_XX", "LOC_CUI_GW_SORT_BY_CITY",                                            "Sort By City"),
("xx_XX", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Sort By Building"),
("xx_XX", "LOC_CUI_GW_THEMING_HELPER",                                          "Theming Helper"),
("xx_XX", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Pick three Great Works / Artifacts of the same color and different numbers to complete a theme."),

-- =============================================================================
-- Notes
("xx_XX", "LOC_CUI_NOTES",                                                      "Notes"),
("xx_XX", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Last edited at turn: {1_num} ]"),
("xx_XX", "LOC_CUI_NOTE_EMPTY",                                                 "Empty Note"),

-- =============================================================================
-- Screenshot
("xx_XX", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Enter Screenshot Mode[NEWLINE][NEWLINE]Screenshot Mode will hide most or all UI Elements, allows you to take clean screenshots.[NEWLINE][NEWLINE]Left-click hide all UI Elements[NEWLINE]Right-click hide all UI Elements except for City Banners[NEWLINE]Hold ALT to rotate the screen[NEWLINE]Press ESC to exit Screenshot Mode"),

-- =============================================================================
-- Civ Assistant
("xx_XX", "LOC_CUI_CA_SURPLUS_RESOUCES",                                        "Surplus Luxury"),
("xx_XX", "LOC_CUI_CA_SURPLUS_RESOUCES_OPT",                                    "Surplus Luxury"),

-- =============================================================================
("xx_XX", "LOC_CUI_COLON", ": ");
-- EOF