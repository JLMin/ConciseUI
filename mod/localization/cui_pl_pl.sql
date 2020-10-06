-- =============================================================================
-- CUI Ingame Text - [YOUR_LANGUAGE] by [YOUR_NAME]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("pl_PL", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Zarządzaj polami i obywatelami"),

-- =============================================================================
-- City States Panel
("pl_PL", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Wysłani Emisariusze: {1_num}, Suzeren: {2_num}"),

-- =============================================================================
-- Deal Panel
("pl_PL", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "LPM - Dodaj, PPM - Odejmij"),
("pl_PL", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "Posiadają już"),
("pl_PL", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "Już posiadamy"),
("pl_PL", "LOC_CUI_DP_WE_HAVE_ONLY_ONE_TOOLTIP",                                "Mamy tylko jedną sztukę"),

-- =============================================================================
-- Diplomatic Banner
("pl_PL", "LOC_CUI_DB_CITY",                                                    "Ilość miast: {1_num}"),
("pl_PL", "LOC_CUI_DB_RELIGION",                                                "Religia: {1_name}"),
("pl_PL", "LOC_CUI_DB_NONE",                                                    "Brak"),
("pl_PL", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Możliwe zawarcie pokoju]"),
("pl_PL", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Pokój za: {1_Remaining}[ICON_TURN]]"),
("pl_PL", "LOC_CUI_DB_RELATIONSHIP",                                            "Stosunki: {1_Relationship}"),
("pl_PL", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "Brak uraz"),
("pl_PL", "LOC_CUI_DB_GRIEVANCES",                                              "Urazy: {1_Grievances}"),
("pl_PL", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "Oferują:"),
("pl_PL", "LOC_CUI_DB_WE_CAN_OFFER",                                            "Możemy zaoferować:"),
("pl_PL", "LOC_CUI_DB_GOLD",                                                    "Złoto:"),
("pl_PL", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Złoto i Względy Dyplomatyczne:"),
("pl_PL", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Wynik i Przychody:"),
("pl_PL", "LOC_CUI_DB_MARS_PROJECT",                                            "Kolonia Marsjańska: {1_progress}  {2_progress}  {3_progress}"),
("pl_PL", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Ekspedycja Egzoplanetarna: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("pl_PL", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Turyści: {1_num} / {2_total}"),
("pl_PL", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Zdobytych stolic: {1_num}"),
("pl_PL", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Nawrócone Cywilizacje: {1_num} / {2_total}"),
("pl_PL", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Punkty Zwycięstwa Dyplomatycznego: {1_num} / {2_total}"),

-- =============================================================================
-- Minimap Panel
("pl_PL", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Pokaż Ikony Dystryktów"),
("pl_PL", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Pokaż Ikony Cudów"),
("pl_PL", "LOC_CUI_MP_AUTONAMING",                                              "Nazwy"),
("pl_PL", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Automatyczny tekst dla znaczników"),
("pl_PL", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Pokaż ikony ulepszonych zasobów"),
("pl_PL", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Włącz/wyłącz ikony ulepszonych zasobów"),
("pl_PL", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Pokaż ikony jednostek"),
("pl_PL", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Włącz/wyłącz ikony jednostek"),
("pl_PL", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Pokaż Sztandary Miast"),
("pl_PL", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Włącz/wyłącz sztandary miast"),
("pl_PL", "LOC_CUI_MO_SHOW_TRADERS",                                            "Pokaż ikony kupców"),
("pl_PL", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Włącz/wyłącz ikony kupców"),
("pl_PL", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Pokaż ikony jednostek religijnych"),
("pl_PL", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Włącz/wyłącz ikony jednostek religijnych"),

-- =============================================================================
-- SpyInfo
("pl_PL", "LOC_CUI_SI_SPY_AVAILABLE",                                           "Użycie: {1_num} [ICON_Unit] {1_num : plural 1?Szpieg; other?Szpiegów;}"),
("pl_PL", "LOC_CUI_SI_SPY_CAPACITY",                                            "Limit: {1_num} [ICON_Unit] {1_num : plural 1?Szpieg; other?Szpiegów;}"),

-- =============================================================================
-- World Tracker
("pl_PL", "LOC_CUI_WT_GOSSIP_LOG",                                              "Dziennik Plotek:"),
("pl_PL", "LOC_CUI_WT_COMBAT_LOG",                                              "Dziennik Bitew:"),

-- =============================================================================
-- Production Panel
("pl_PL", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Zawsze pokazuj kolejkę budowy"),

-- =============================================================================
-- Great Works
("pl_PL", "LOC_CUI_GW_SORT_BY_CITY",                                            "Sortuj po mieście"),
("pl_PL", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Sortuj po typie budynku"),
("pl_PL", "LOC_CUI_GW_THEMING_HELPER",                                          "Asystent Tematyczny"),
("pl_PL", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Wybierz trzy Wielkie Dzieła / Artefakty tego samego koloru i różnym numerem aby uzyskać premię tematyczną."),

-- =============================================================================
-- Notes
("pl_PL", "LOC_CUI_NOTES",                                                      "Notatki"),
("pl_PL", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Tura: {1_num} ]"),
("pl_PL", "LOC_CUI_NOTE_EMPTY",                                                 "Pusta notatka"),

-- =============================================================================
-- Options
("pl_PL", "LOC_CUI_OPTIONS_TAB_VICTORY",                                        "Zwycięstwa"),
("pl_PL", "LOC_CUI_OPTIONS_TAB_LOG",                                            "Dzienniki"),
("pl_PL", "LOC_CUI_OPTIONS_TAB_POPUP",                                          "Okienka"),
("pl_PL", "LOC_CUI_OPTIONS_TAB_REMIND",                                         "Przypomnienia"),
--
("pl_PL", "LOC_CUI_OPTIONS_DESC_VICTORY",                                       "Wybierz typ zwycięstwa który chcesz śledzić:"),
("pl_PL", "LOC_CUI_OPTIONS_DESC_LOG",                                           "Wybierz gdzie dzienniki będą wyświetlane:"),
("pl_PL", "LOC_CUI_OPTIONS_DESC_POPUP",                                         "Wybierz które wyskakujące okienka mają się pojawiać:"),
("pl_PL", "LOC_CUI_OPTIONS_DESC_REMIND",                                        "Wybierz przypomnienia które chcesz włączyć:"),
("pl_PL", "LOC_CUI_OPTIONS_DESC_SPEED",                                         "Wybierz opcje szybkiego ruchu i walki:"),
--
("pl_PL", "LOC_CUI_OPTIONS_LOG_SHOW_NONE",                                      "Wyłącz"),
("pl_PL", "LOC_CUI_OPTIONS_LOG_DEFAULT",                                        "Domyślna Pozycja"),
("pl_PL", "LOC_CUI_OPTIONS_LOG_WORLDTRACKER",                                   "Panel Postępów"),
("pl_PL", "LOC_CUI_OPTIONS_LOG_BOTH",                                           "Oba"),
--
("pl_PL", "LOC_CUI_OPTIONS_POPUP_RESEARCH",                                     "Ukończenie Technologii/Idei:"),
("pl_PL", "LOC_CUI_OPTIONS_POPUP_AUDIO",                                        "Dźwięk Technologii/Idei:"),
("pl_PL", "LOC_CUI_OPTIONS_POPUP_ERA_SCORE",                                    "Historyczne Wydarzenia:"),
("pl_PL", "LOC_CUI_OPTIONS_POPUP_GREAT_WORK",                                   "Stworzenie Wielkiego Dzieła:"),
("pl_PL", "LOC_CUI_OPTIONS_POPUP_RELIC",                                        "Stworzenie Reliktu:"),
--
("pl_PL", "LOC_CUI_OPTIONS_REMIND_TECH",                                        "Ukończenie technologii przez eurekę:"),
("pl_PL", "LOC_CUI_OPTIONS_REMIND_CIVIC",                                       "Ukończenie idei przez eurekę:"),
("pl_PL", "LOC_CUI_OPTIONS_REMIND_GOVERNMENT",                                  "Darmowa zmiana ustroju:"),
("pl_PL", "LOC_CUI_OPTIONS_REMIND_GOVERNOR",                                    "Nowy tytuł Gubernatora dostępny:"),
--
("pl_PL", "LOC_CUI_OPTIONS_QUICK_COMBAT",                                       "Szybka walka:"),
("pl_PL", "LOC_CUI_OPTIONS_QUICK_MOVEMENT",                                     "Szybki ruch:"),
("pl_PL", "LOC_CUI_OPTIONS_SPEED_PLAYER_ONLY",                                  "Tylko gracz"),
("pl_PL", "LOC_CUI_OPTIONS_SPEED_AI_ONLY",                                      "Tylko AI"),

-- =============================================================================
-- Screenshot
("pl_PL", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Wejdź w tryb fotograficzny[NEWLINE][NEWLINE]Tryb fotograficzny ukryje wszystkie elementy UI i pozwoli zrobić czyste zdjęcie ekranu.[NEWLINE][NEWLINE]Lewy przycisk myszy ukryje wszystkie elementy UI[NEWLINE]Prawy przycisk myszy ukryje wszystkie elementy UI poza banerami miast[NEWLINE]Przytrzymaj ALT aby obracać ekranem[NEWLINE]Kliknij ESC aby wyjść z trybu fotograficznego"),

-- =============================================================================
("pl_PL", "LOC_CUI_COLON", ": ");
-- EOF
