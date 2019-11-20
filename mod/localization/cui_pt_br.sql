-- =============================================================================
-- CUI Ingame Text - [YOUR_LANGUAGE] by [YOUR_NAME]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("pl_BR", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Manage Citizens and Tiles"),

-- =============================================================================
-- City States Panel
("pl_BR", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Envoys Sent: {1_num}, Suzerain of: {2_num}"),

-- =============================================================================
-- Deal Panel
("pl_BR", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "L-Click Add, R-Click Subtract"),
("pl_BR", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "They already have"),
("pl_BR", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "We already have"),
("pl_BR", "LOC_CUI_DP_WE_HAVE_ONLY_ONE_TOOLTIP",                                "We only have one"),

-- =============================================================================
-- Diplomatic Banner
("pl_BR", "LOC_CUI_DB_CITY",                                                    "Cities: {1_num}"),
("pl_BR", "LOC_CUI_DB_RELIGION",                                                "Religion: {1_name}"),
("pl_BR", "LOC_CUI_DB_NONE",                                                    "None"),
("pl_BR", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Peace Deal is Available]"),
("pl_BR", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Peace Deal: {1_Remaining}[ICON_TURN]]"),
("pl_BR", "LOC_CUI_DB_RELATIONSHIP",                                            "Relationship: {1_Relationship}"),
("pl_BR", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "No Grievances"),
("pl_BR", "LOC_CUI_DB_GRIEVANCES",                                              "Grievances: {1_Grievances}"),
("pl_BR", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "They can offer:"),
("pl_BR", "LOC_CUI_DB_WE_CAN_OFFER",                                            "We can offer:"),
("pl_BR", "LOC_CUI_DB_GOLD",                                                    "Gold:"),
("pl_BR", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Gold and Diplomatic Favors:"),
("pl_BR", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Score and Yields:"),
("pl_BR", "LOC_CUI_DB_MARS_PROJECT",                                            "Mars Colony: {1_progress}  {2_progress}  {3_progress}"),
("pl_BR", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Exoplanet Expedition: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("pl_BR", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Visiting Tourists: {1_num} / {2_total}"),
("pl_BR", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Capitals Captured: {1_num}"),
("pl_BR", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Civilizations Converted: {1_num} / {2_total}"),
("pl_BR", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Diplomatic Victory Point: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("pl_BR", "LOC_CUI_EP_FILTER_ALL",                                              "All"),
("pl_BR", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "Show Cities"),

-- =============================================================================
-- Minimap Panel
("pl_BR", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Show Districts Icons"),
("pl_BR", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Show Wonders Icons"),
("pl_BR", "LOC_CUI_MP_AUTONAMING",                                              "Naming"),
("pl_BR", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Auto-naming pins"),
("pl_BR", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Show Improved Resource Icons"),
("pl_BR", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Toggle Improved Resource Icons"),
("pl_BR", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Show Unit Flags"),
("pl_BR", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Toggle Unit Flags"),
("pl_BR", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Show City Banners"),
("pl_BR", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Toggle City Banners"),
("pl_BR", "LOC_CUI_MO_SHOW_TRADERS",                                            "Show Traders"),
("pl_BR", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Toggle Trader Flags"),
("pl_BR", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Show Religion Units"),
("pl_BR", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Toggle Religion Flags"),

-- =============================================================================
-- Report Screen
("pl_BR", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Show City Details"),
("pl_BR", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Number of Buildings"),
("pl_BR", "LOC_CUI_RS_TOTALS",                                                  "Totals: {1_num}"),
("pl_BR", "LOC_CUI_RS_DEALS_OUTGOING",                                          "Outgoing"),
("pl_BR", "LOC_CUI_RS_DEALS_INCOMING",                                          "Incoming"),

-- =============================================================================
-- SpyInfo
("pl_BR", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} available"),
("pl_BR", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} capacity"),

-- =============================================================================
-- World Tracker
("pl_BR", "LOC_CUI_WT_REMINDER",                                                "Reminder"),
("pl_BR", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "The background color changes to green when the technology can be finished by getting an Eureka."),
("pl_BR", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "The background color changes to green when the civic can be finished by getting an Inspiration."),
("pl_BR", "LOC_CUI_WT_GOSSIP_LOG",                                              "Gossip Log"),
("pl_BR", "LOC_CUI_WT_COMBAT_LOG",                                              "Combat Log"),
("pl_BR", "LOC_CUI_WT_PERSIST",                                                 "Persist"),
("pl_BR", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "Do not clear the gossip log between turns."),
("pl_BR", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "Do not clear the combat log between turns."),

-- =============================================================================
-- Trade Panel
("pl_BR", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Sort by [ICON_Food]Food."),
("pl_BR", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Sort by [ICON_Production]Production."),
("pl_BR", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Sort by [ICON_Gold]Gold."),
("pl_BR", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Sort by [ICON_Science]Science."),
("pl_BR", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Sort by [ICON_Culture]Culture."),
("pl_BR", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Sort by [ICON_Faith]Faith."),
("pl_BR", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Sort by [ICON_Turn]Turns to complete route."),
("pl_BR", "LOC_CUI_TP_REPEAT",                                                  "Repeat"),
("pl_BR", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "To have this trader repeat this trade route indefinitely."),
("pl_BR", "LOC_CUI_TP_SELECT_A_CITY",                                           "Select a New Origin City."),

-- =============================================================================
-- Espionage Panel
("pl_BR", "LOC_CUI_EP_SHOW_CITYS",                                              "Show Cities"),
("pl_BR", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Gain ({1_GoldString}) Gold yields."),

-- =============================================================================
-- Production Panel
("pl_BR", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Use Queue By Default"),

-- =============================================================================
-- Great Works
("pl_BR", "LOC_CUI_GW_SORT_BY_CITY",                                            "Sort By City"),
("pl_BR", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Sort By Building"),
("pl_BR", "LOC_CUI_GW_THEMING_HELPER",                                          "Theming Helper"),
("pl_BR", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Pick three Great Works / Artifacts of the same color and different numbers to complete a theme."),

-- =============================================================================
-- Notes
("pl_BR", "LOC_CUI_NOTES",                                                      "Notes"),
("pl_BR", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Turn: {1_num} ]"),
("pl_BR", "LOC_CUI_NOTE_EMPTY",                                                 "Empty Note"),

-- =============================================================================
-- Options
("pl_BR", "LOC_CUI_OPTIONS_TAB_VICTORY",                                        "Victories"),
("pl_BR", "LOC_CUI_OPTIONS_TAB_LOG",                                            "Logs"),
("pl_BR", "LOC_CUI_OPTIONS_TAB_POPUP",                                          "Popups"),
("pl_BR", "LOC_CUI_OPTIONS_TAB_REMIND",                                         "Remind"),
--
("pl_BR", "LOC_CUI_OPTIONS_DESC_VICTORY",                                       "Please select the victory you want to track."),
("pl_BR", "LOC_CUI_OPTIONS_DESC_LOG",                                           "Please select where the logs will be displayed."),
("pl_BR", "LOC_CUI_OPTIONS_DESC_POPUP",                                         "Please select the popups you want to enable."),
("pl_BR", "LOC_CUI_OPTIONS_DESC_REMIND",                                        "Please select the reminders you want to use."),
("pl_BR", "LOC_CUI_OPTIONS_DESC_SPEED",                                         "Please select quick combat & movement objects."),
--
("pl_BR", "LOC_CUI_OPTIONS_LOG_SHOW_NONE",                                      "Disable"),
("pl_BR", "LOC_CUI_OPTIONS_LOG_DEFAULT",                                        "Default position"),
("pl_BR", "LOC_CUI_OPTIONS_LOG_WORLDTRACKER",                                   "World Tracker"),
("pl_BR", "LOC_CUI_OPTIONS_LOG_BOTH",                                           "Both"),
--
("pl_BR", "LOC_CUI_OPTIONS_POPUP_RESEARCH",                                     "Tech/Civic complete"),
("pl_BR", "LOC_CUI_OPTIONS_POPUP_AUDIO",                                        "Tech/Civic audio"),
("pl_BR", "LOC_CUI_OPTIONS_POPUP_ERA_SCORE",                                    "Gain era score"),
("pl_BR", "LOC_CUI_OPTIONS_POPUP_GREAT_WORK",                                   "Create great works"),
("pl_BR", "LOC_CUI_OPTIONS_POPUP_RELIC",                                        "Get relics"),
--
("pl_BR", "LOC_CUI_OPTIONS_REMIND_TECH",                                        "Tech complete by eureka"),
("pl_BR", "LOC_CUI_OPTIONS_REMIND_CIVIC",                                       "Civic complete by inspire"),
("pl_BR", "LOC_CUI_OPTIONS_REMIND_GOVERNMENT",                                  "Free government chance"),
("pl_BR", "LOC_CUI_OPTIONS_REMIND_GOVERNOR",                                    "Governor titles available"),
--
("pl_BR", "LOC_CUI_OPTIONS_QUICK_COMBAT",                                       "Quick Combat"),
("pl_BR", "LOC_CUI_OPTIONS_QUICK_MOVEMENT",                                     "Quick Movement"),
("pl_BR", "LOC_CUI_OPTIONS_SPEED_PLAYER_ONLY",                                  "Player Only"),
("pl_BR", "LOC_CUI_OPTIONS_SPEED_AI_ONLY",                                      "AI Only"),

-- =============================================================================
-- Screenshot
("pl_BR", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Enter Screenshot Mode[NEWLINE][NEWLINE]Screenshot Mode will hide most or all UI Elements, allows you to take clean screenshots.[NEWLINE][NEWLINE]Left-click hide all UI Elements[NEWLINE]Right-click hide all UI Elements except for City Banners[NEWLINE]Hold ALT to rotate the screen[NEWLINE]Press ESC to exit Screenshot Mode"),

-- =============================================================================
("pl_BR", "LOC_CUI_COLON", ": ");
-- EOF