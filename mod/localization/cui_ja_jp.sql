-- =============================================================================
-- CUI Ingame Text - [Japanese] by [J4A] 2/17/2019
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("ja_JP", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "市民とタイルを管理"),

-- =============================================================================
-- City States Panel
("ja_JP", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "代表団: {1_num} / 宗主国: {2_num}"),

-- =============================================================================
-- Deal Panel
("ja_JP", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "左クリックで追加 / 右クリックで撤回"),
("ja_JP", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "相手が所有している"),
("ja_JP", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "自分が所有している"),
("ja_JP", "LOC_CUI_DP_WE_HAVE_ONLY_ONE_TOOLTIP",                                "1つしか所有していない"),

-- =============================================================================
-- Diplomatic Banner
("ja_JP", "LOC_CUI_DB_CITY",                                                    "都市: {1_num}"),
("ja_JP", "LOC_CUI_DB_RELIGION",                                                "宗教を創始: {1_name}"),
("ja_JP", "LOC_CUI_DB_NONE",                                                    "なし"),
("ja_JP", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[和平可能]"),
("ja_JP", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[和平可能: {1_Remaining}[ICON_TURN]]"),
("ja_JP", "LOC_CUI_DB_RELATIONSHIP",                                            "関係: {1_Relationship}"),
("ja_JP", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "不平はありません"),
("ja_JP", "LOC_CUI_DB_GRIEVANCES",                                              "不平: {1_Grievances}"),
("ja_JP", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "相手が提供できる品目: "),
("ja_JP", "LOC_CUI_DB_WE_CAN_OFFER",                                            "自分が提供できる品目: "),
("ja_JP", "LOC_CUI_DB_GOLD",                                                    "ゴールド: "),
("ja_JP", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "ゴールドと外交的支持: "),
("ja_JP", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "スコアと産出量: "),
("ja_JP", "LOC_CUI_DB_MARS_PROJECT",                                            "科学勝利: {1_progress}  {2_progress}  {3_progress}"),
("ja_JP", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "科学勝利: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("ja_JP", "LOC_CUI_DB_VISITING_TOURISTS",                                       "文化勝利: {1_num} / {2_total}"),
("ja_JP", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "制覇勝利: {1_num}"),
("ja_JP", "LOC_CUI_DB_CIVS_CONVERTED",                                          "宗教勝利: {1_num} / {2_total}"),
("ja_JP", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "外交勝利: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("ja_JP", "LOC_CUI_EP_FILTER_ALL",                                              "すべて"),
("ja_JP", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "都市を表示"),

-- =============================================================================
-- Minimap Panel
("ja_JP", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "区域のアイコンを表示"),
("ja_JP", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "遺産のアイコンを表示"),
("ja_JP", "LOC_CUI_MP_AUTONAMING",                                              "命名"),
("ja_JP", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "ピンの名前を自動で追加する"),
("ja_JP", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "改善済み資源のアイコンを表示"),
("ja_JP", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "改善済み資源アイコンの切り替え"),
("ja_JP", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "ユニットアイコンを表示"),
("ja_JP", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "ユニットアイコンの切り替え"),
("ja_JP", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "都市バナーを表示"),
("ja_JP", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "都市バナーの切り替え"),
("ja_JP", "LOC_CUI_MO_SHOW_TRADERS",                                            "交易商アイコンを表示"),
("ja_JP", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "交易商アイコンの切り替え"),
("ja_JP", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "宗教ユニットを表示"),
("ja_JP", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "宗教表示の切り替え"),

-- =============================================================================
-- Report Screen
("ja_JP", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "都市の詳細を表示"),
("ja_JP", "LOC_CUI_RS_BUILDING_NUMBER",                                         "建造物の数"),
("ja_JP", "LOC_CUI_RS_TOTALS",                                                  "合計: {1_num}"),
("ja_JP", "LOC_CUI_RS_DEALS_OUTGOING",                                          "支出"),
("ja_JP", "LOC_CUI_RS_DEALS_INCOMING",                                          "収入"),

-- =============================================================================
-- Top Panel
("ja_JP", "LOC_CUI_SI_SPY_AVAILABLE",                                           "[ICON_Unit]スパイ待機中: {1_num}"),
("ja_JP", "LOC_CUI_SI_SPY_CAPACITY",                                            "[ICON_Unit]スパイ保有枠: {1_num}"),

-- =============================================================================
-- World Tracker
("ja_JP", "LOC_CUI_WT_REMINDER",                                                "リマインダー"),
("ja_JP", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "ブーストで研究が完了するタイミングになったら背景が緑になる"),
("ja_JP", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "ブーストで研究が完了するタイミングになったら背景が緑になる"),
("ja_JP", "LOC_CUI_WT_GOSSIP_LOG",                                              "ゴシップログ"),
("ja_JP", "LOC_CUI_WT_COMBAT_LOG",                                              "戦闘ログ"),
("ja_JP", "LOC_CUI_WT_PERSIST",                                                 "ログを保存"),
("ja_JP", "LOC_CUI_WT_PERSIST_TOOLTIP",                                         "ターン間でゴシップログを消去しないでください。"),
("ja_JP", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "ターン間の戦闘ログをクリアしないでください。"),

-- =============================================================================
-- Trade Panel
("ja_JP", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "[ICON_Food]食料で並べ替え"),
("ja_JP", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "[ICON_Production]生産力で並べ替え"),
("ja_JP", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "[ICON_Gold]ゴールドで並べ替え"),
("ja_JP", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "[ICON_Science]科学力で並べ替え"),
("ja_JP", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "[ICON_Culture]文化力で並べ替え"),
("ja_JP", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "[ICON_Faith]信仰力で並べ替え"),
("ja_JP", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "[ICON_Turn]残りターンで並べ替え"),
("ja_JP", "LOC_CUI_TP_REPEAT",                                                  "繰り返す"),
("ja_JP", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "交易路を繰り返す。デフォルトでは、前回と同じ交易路を選択する。"),
("ja_JP", "LOC_CUI_TP_SELECT_A_CITY",                                           "出発する都市を選択する。"),

-- =============================================================================
-- Espionage Panel
("ja_JP", "LOC_CUI_EP_SHOW_CITYS",                                              "都市を表示"),
("ja_JP", "LOC_CUI_EP_SIPHON_FUNDS",                                            "ゴールドを獲得する ({1_GoldString})"),

-- =============================================================================
-- Production Panel
("ja_JP", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "デフォルトで生産キューを使用"),

-- =============================================================================
-- Great Works
("ja_JP", "LOC_CUI_GW_SORT_BY_CITY",                                            "都市で並べ替え"),
("ja_JP", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "建造物で並べ替え"),
("ja_JP", "LOC_CUI_GW_THEMING_HELPER",                                          "テーマ化のヒント"),
("ja_JP", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "傑作を3つ選択 / 同じ色の遺物と異なる数字でテーマ化達成"),

-- =============================================================================
-- Notes
("ja_JP", "LOC_CUI_NOTES",                                                      "ノート"),
("ja_JP", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ ターン: {1_num} ]"),
("ja_JP", "LOC_CUI_NOTE_EMPTY",                                                 "空白"),

-- =============================================================================
-- Options
("ja_JP", "LOC_CUI_OPTIONS_TAB_VICTORY",                                        "勝利"),
("ja_JP", "LOC_CUI_OPTIONS_TAB_LOG",                                            "ログ"),
("ja_JP", "LOC_CUI_OPTIONS_TAB_POPUP",                                          "ポップアップ"),
("ja_JP", "LOC_CUI_OPTIONS_TAB_REMIND",                                         "リマインド"),
--
("ja_JP", "LOC_CUI_OPTIONS_DESC_VICTORY",                                       "確認したい勝利条件を選択"),
("ja_JP", "LOC_CUI_OPTIONS_DESC_LOG",                                           "表示したいログを選択"),
("ja_JP", "LOC_CUI_OPTIONS_DESC_POPUP",                                         "有効にしたいポップアップを選択"),
("ja_JP", "LOC_CUI_OPTIONS_DESC_REMIND",                                        "利用したいリマインダーを選択"),
("ja_JP", "LOC_CUI_OPTIONS_DESC_SPEED",                                         "クイック戦闘・移動の対象を選択"),
--
("ja_JP", "LOC_CUI_OPTIONS_LOG_SHOW_NONE",                                      "無効"),
("ja_JP", "LOC_CUI_OPTIONS_LOG_DEFAULT",                                        "デフォルト"),
("ja_JP", "LOC_CUI_OPTIONS_LOG_WORLDTRACKER",                                   "ワールドトラッカー"),
("ja_JP", "LOC_CUI_OPTIONS_LOG_BOTH",                                           "両方"),
--
("ja_JP", "LOC_CUI_OPTIONS_POPUP_RESEARCH",                                     "技術/社会制度の取得"),
("ja_JP", "LOC_CUI_OPTIONS_POPUP_AUDIO",                                        "技術/社会制度の音声"),
("ja_JP", "LOC_CUI_OPTIONS_POPUP_ERA_SCORE",                                    "時代スコアの獲得"),
("ja_JP", "LOC_CUI_OPTIONS_POPUP_GREAT_WORK",                                   "傑作の誕生"),
("ja_JP", "LOC_CUI_OPTIONS_POPUP_RELIC",                                        "遺物の獲得"),
--
("ja_JP", "LOC_CUI_OPTIONS_REMIND_TECH",                                        "ひらめきで技術取得"),
("ja_JP", "LOC_CUI_OPTIONS_REMIND_CIVIC",                                       "天啓で社会制度取得"),
("ja_JP", "LOC_CUI_OPTIONS_REMIND_GOVERNMENT",                                  "政府が変更可能"),
("ja_JP", "LOC_CUI_OPTIONS_REMIND_GOVERNOR",                                    "総督の称号が利用可能"),
--
("ja_JP", "LOC_CUI_OPTIONS_QUICK_COMBAT",                                       "クイック戦闘"),
("ja_JP", "LOC_CUI_OPTIONS_QUICK_MOVEMENT",                                     "クイック移動"),
("ja_JP", "LOC_CUI_OPTIONS_SPEED_PLAYER_ONLY",                                  "プレイヤーのみ"),
("ja_JP", "LOC_CUI_OPTIONS_SPEED_AI_ONLY",                                      "AIのみ"),

-- =============================================================================
-- Screenshot
("ja_JP", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "スクリーンショットモードに切り替え[NEWLINE][NEWLINE]ユーザーインターフェースの全部あるいは大半を隠す。[NEWLINE]障害物がないスクリーンショットの撮影に最適。[NEWLINE]このモードの間は回転したカメラの向きが固定される。[NEWLINE][NEWLINE]左クリック：ユーザーインターフェースを全て隠す。[NEWLINE]右クリック：都市バナー以外のユーザーインターフェースを隠す。[NEWLINE]ESC キー：スクリーンショットモードを終了する。"),

-- =============================================================================
("ja_JP", "LOC_CUI_COLON", ": ");
-- EOF