-- =============================================================================
-- CUI Ingame Text - [Russian] by [iMiAMi]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("ru_RU", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Управление жителями и клетками"),

-- =============================================================================
-- City States Panel
("ru_RU", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Отправлено послов: {1_num}, Сюзерен в: {2_num}"),

-- =============================================================================
-- Deal Panel
("ru_RU", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "ЛКМ добавить, ПКМ убавить"),
("ru_RU", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "Уже имеют"),
("ru_RU", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "Уже имеем"),
("ru_RU", "LOC_CUI_DP_WE_HAVE_ONLY_ONE_TOOLTIP",                                "Имеем только одну единицу"),

-- =============================================================================
-- Diplomatic Banner
("ru_RU", "LOC_CUI_DB_CITY",                                                    "Города: {1_num}"),
("ru_RU", "LOC_CUI_DB_RELIGION",                                                "Религия: {1_name}"),
("ru_RU", "LOC_CUI_DB_NONE",                                                    "Нет"),
("ru_RU", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Доступен мирный договор]"),
("ru_RU", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Мирный договор: {1_Remaining}[ICON_TURN]]"),
("ru_RU", "LOC_CUI_DB_RELATIONSHIP",                                            "Отношения: {1_Relationship}"),
("ru_RU", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "Нет претензий"),
("ru_RU", "LOC_CUI_DB_GRIEVANCES",                                              "Претензии: {1_Grievances}"),
("ru_RU", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "Могут предложить:"),
("ru_RU", "LOC_CUI_DB_WE_CAN_OFFER",                                            "Можем предложить:"),
("ru_RU", "LOC_CUI_DB_GOLD",                                                    "Золото:"),
("ru_RU", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Золото и мировое влияние:"),
("ru_RU", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Счет и доходы:"),
("ru_RU", "LOC_CUI_DB_MARS_PROJECT",                                            "Марсианская колония: {1_progress}  {2_progress}  {3_progress}"),
("ru_RU", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Межпланетная экспедиция: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("ru_RU", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Привлечено туристов: {1_num} / {2_total}"),
("ru_RU", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Захвачено столиц: {1_num}"),
("ru_RU", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Цивилизаций преобразовано: {1_num} / {2_total}"),
("ru_RU", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Очки дипломатической победы: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("ru_RU", "LOC_CUI_EP_FILTER_ALL",                                              "Все"),
("ru_RU", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "Показать города"),

-- =============================================================================
-- Minimap Panel
("ru_RU", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Показать значки районов"),
("ru_RU", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Показать значки чудес света"),
("ru_RU", "LOC_CUI_MP_AUTONAMING",                                              "Наименования"),
("ru_RU", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Автонаименование меток"),
("ru_RU", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Показать значки на улучшеных ресурсах"),
("ru_RU", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Вкл./выкл. значки на улучшенных ресурсах"),
("ru_RU", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Показать значки юнитов"),
("ru_RU", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Вкл./выкл. значки юнитов"),
("ru_RU", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Показать баннеры городов"),
("ru_RU", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Вкл./выкл. баннеры городов"),
("ru_RU", "LOC_CUI_MO_SHOW_TRADERS",                                            "Показать значки торговцев"),
("ru_RU", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Вкл./выкл. значки торговцев"),
("ru_RU", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Показать значки религиозных юнитов"),
("ru_RU", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Вкл./выкл значки религиозных юнитов"),

-- =============================================================================
-- Report Screen
("ru_RU", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Показать детали города"),
("ru_RU", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Число зданий"),
("ru_RU", "LOC_CUI_RS_TOTALS",                                                  "Всего: {1_num}"),
("ru_RU", "LOC_CUI_RS_DEALS_OUTGOING",                                          "Исходящие"),
("ru_RU", "LOC_CUI_RS_DEALS_INCOMING",                                          "Входящие"),

-- =============================================================================
-- SpyInfo
("ru_RU", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} доступно"),
("ru_RU", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Spy; other?Spies;} всего"),

-- =============================================================================
-- World Tracker
("ru_RU", "LOC_CUI_WT_REMINDER",                                                "Напоминание"),
("ru_RU", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "Фоновый цвет изменяется на зеленый, если технология может быть завершена озарением."),
("ru_RU", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "Фоновый цвет изменяется на зеленый, если социальный институт может быть завершен вдохновением."),
("ru_RU", "LOC_CUI_WT_GOSSIP_LOG",                                              "Журнал слухов"),
("ru_RU", "LOC_CUI_WT_COMBAT_LOG",                                              "Журнал сражений"),
("ru_RU", "LOC_CUI_WT_PERSIST",                                                 "Очистка"),
("ru_RU", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "Не очищать журнал слухов между ходами."),
("ru_RU", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "Не очищать журнал сражений между ходами."),

-- =============================================================================
-- Trade Panel
("ru_RU", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Сортировать по [ICON_Food]пище."),
("ru_RU", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Сортировать по [ICON_Production]производству."),
("ru_RU", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Сортировать по [ICON_Gold]золоту."),
("ru_RU", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Сортировать по [ICON_Science]науке."),
("ru_RU", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Сортировать по [ICON_Culture]культуре."),
("ru_RU", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Сортировать по [ICON_Faith]религии."),
("ru_RU", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Сортировать по [ICON_Turn]ходам до завершения."),
("ru_RU", "LOC_CUI_TP_REPEAT",                                                  "Повторить"),
("ru_RU", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "Повторять постоянно."),
("ru_RU", "LOC_CUI_TP_SELECT_A_CITY",                                           "Выбрать новый исходящий город."),

-- =============================================================================
-- Espionage Panel
("ru_RU", "LOC_CUI_EP_SHOW_CITYS",                                              "Показать города"),
("ru_RU", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Получить ({1_GoldString}) доходность."),

-- =============================================================================
-- Production Panel
("ru_RU", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Использовать очередь по-умолчанию"),

-- =============================================================================
-- Great Works
("ru_RU", "LOC_CUI_GW_SORT_BY_CITY",                                            "Сортировать по городам"),
("ru_RU", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Сортировать по зданиям"),
("ru_RU", "LOC_CUI_GW_THEMING_HELPER",                                          "Тематический помощник"),
("ru_RU", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Для создания тематического музея соберите в нем три великие работы или артефакта одного цвета, но с различными номерами."),

-- =============================================================================
-- Notes
("ru_RU", "LOC_CUI_NOTES",                                                      "Заметки"),
("ru_RU", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Ходов: {1_num} ]"),
("ru_RU", "LOC_CUI_NOTE_EMPTY",                                                 "Пусто"),

-- =============================================================================
-- Options
("ru_RU", "LOC_CUI_OPTIONS_TAB_VICTORY",                                        "Победы"),
("ru_RU", "LOC_CUI_OPTIONS_TAB_LOG",                                            "Журналы"),
("ru_RU", "LOC_CUI_OPTIONS_TAB_POPUP",                                          "Сообщения"),
("ru_RU", "LOC_CUI_OPTIONS_TAB_REMIND",                                         "Напоминания"),
--
("ru_RU", "LOC_CUI_OPTIONS_DESC_VICTORY",                                       "Выберите виды победы для отслеживания."),
("ru_RU", "LOC_CUI_OPTIONS_DESC_LOG",                                           "Выберите отображаемые журналы."),
("ru_RU", "LOC_CUI_OPTIONS_DESC_POPUP",                                         "Выберите активные сообщения."),
("ru_RU", "LOC_CUI_OPTIONS_DESC_REMIND",                                        "Выберите используемые напоминания."),
("ru_RU", "LOC_CUI_OPTIONS_DESC_SPEED",                                         "Выберите объекты быстрых передвижений и сражений."),
--
("ru_RU", "LOC_CUI_OPTIONS_LOG_SHOW_NONE",                                      "Выключено"),
("ru_RU", "LOC_CUI_OPTIONS_LOG_DEFAULT",                                        "Позиция по-умолчанию"),
("ru_RU", "LOC_CUI_OPTIONS_LOG_WORLDTRACKER",                                   "Трэкер"),
("ru_RU", "LOC_CUI_OPTIONS_LOG_BOTH",                                           "Оба"),
--
("ru_RU", "LOC_CUI_OPTIONS_POPUP_RESEARCH",                                     "Технология/ соц.институт завершены"),
("ru_RU", "LOC_CUI_OPTIONS_POPUP_AUDIO",                                        "Технология/ соц.институт звуки"),
("ru_RU", "LOC_CUI_OPTIONS_POPUP_ERA_SCORE",                                    "Получение очков счета эпохи"),
("ru_RU", "LOC_CUI_OPTIONS_POPUP_GREAT_WORK",                                   "Создание великого труда"),
("ru_RU", "LOC_CUI_OPTIONS_POPUP_RELIC",                                        "Получение реликвии"),
--
("ru_RU", "LOC_CUI_OPTIONS_REMIND_TECH",                                        "Технология завершится озарением"),
("ru_RU", "LOC_CUI_OPTIONS_REMIND_CIVIC",                                       "Соц.институт завершится вдохновением"),
("ru_RU", "LOC_CUI_OPTIONS_REMIND_GOVERNMENT",                                  "Возможность смены политического курса"),
("ru_RU", "LOC_CUI_OPTIONS_REMIND_GOVERNOR",                                    "Свободное повышение губернатора"),
--
("ru_RU", "LOC_CUI_OPTIONS_QUICK_COMBAT",                                       "Быстрые сражения"),
("ru_RU", "LOC_CUI_OPTIONS_QUICK_MOVEMENT",                                     "Быстрые перемещения"),
("ru_RU", "LOC_CUI_OPTIONS_SPEED_PLAYER_ONLY",                                  "Только игрока"),
("ru_RU", "LOC_CUI_OPTIONS_SPEED_AI_ONLY",                                      "Только ИИ"),

-- =============================================================================
-- Screenshot
("ru_RU", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Включить режим снимков экрана[NEWLINE][NEWLINE]Режим снимков экрана скрывает большинство элементов пользовательского интерфейса, позволяя делать чистые снимки.[NEWLINE][NEWLINE]ЛКМ скрывает все элементы интерфейса[NEWLINE]ПКМ скрывает все кроме баннеров городов[NEWLINE]Удерживайте ALT для вращения экрана[NEWLINE]ESC - для выхода из режима снимков"),

-- =============================================================================
("ru_RU", "LOC_CUI_COLON", ": ");
-- EOF