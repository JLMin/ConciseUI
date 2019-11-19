-- =============================================================================
-- CUI Ingame Text - [Korean] by [firefanda]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("ko_KR", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "시민 및 타일 관리"),

-- =============================================================================
-- City States Panel
("ko_KR", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "보낸 사절단: {1_num}명, 종주국: {2_num}"),

-- =============================================================================
-- Deal Panel
("ko_KR", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "좌클릭으로 증가, 우클릭으로 감소"),
("ko_KR", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "상대방이 이 물품을 이미 가지고 있습니다."),
("ko_KR", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "우리는 이 물품을 이미 가지고 있습니다."),

-- =============================================================================
-- Diplomatic Banner
("ko_KR", "LOC_CUI_DB_CITY",                                                    "도시: {1_num}"),
("ko_KR", "LOC_CUI_DB_RELIGION",                                                "종교: {1_name}"),
("ko_KR", "LOC_CUI_DB_NONE",                                                    "없음"),
("ko_KR", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[평화협상 가능]"),
("ko_KR", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[평화협상 까지 {1_Remaining}[ICON_TURN]턴 남음]"),
("ko_KR", "LOC_CUI_DB_RELATIONSHIP",                                            "관계: {1_Relationship}"),
("ko_KR", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "적대감 없음"),
("ko_KR", "LOC_CUI_DB_GRIEVANCES",                                              "적대감: {1_Grievances}"),
("ko_KR", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "거래요구 가능:"),
("ko_KR", "LOC_CUI_DB_WE_CAN_OFFER",                                            "거래제안 가능:"),
("ko_KR", "LOC_CUI_DB_GOLD",                                                    "금:"),
("ko_KR", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "금과 외교적 환심:"),
("ko_KR", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "점수 및 생산량:"),
("ko_KR", "LOC_CUI_DB_MARS_PROJECT",                                            "화성 이주지: {1_progress}  {2_progress}  {3_progress}"),
("ko_KR", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "외계 행성 탐험대: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("ko_KR", "LOC_CUI_DB_VISITING_TOURISTS",                                       "관광객 방문: {1_num} / {2_total}"),
("ko_KR", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "점령한 수도: {1_num}"),
("ko_KR", "LOC_CUI_DB_CIVS_CONVERTED",                                          "개종된 도시: {1_num} / {2_total}"),
("ko_KR", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "외교 승리 점수: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("ko_KR", "LOC_CUI_EP_FILTER_ALL",                                              "전체"),
("ko_KR", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "도시 목록"),

-- =============================================================================
-- Minimap Panel
("ko_KR", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "특수지구 아이콘 표시"),
("ko_KR", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "불가사의 아이콘 표시"),
("ko_KR", "LOC_CUI_MP_AUTONAMING",                                              "이름"),
("ko_KR", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "자동 이름 명명"),
("ko_KR", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "개선된 자원 아이콘 보기"),
("ko_KR", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "개선된 자원 아이콘 전환"),
("ko_KR", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "유닛 아이콘 보기"),
("ko_KR", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "유닛 아이콘 전환"),
("ko_KR", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "도시 배너 보기"),
("ko_KR", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "도시 배너 전환"),
("ko_KR", "LOC_CUI_MO_SHOW_TRADERS",                                            "상인 아이콘 보기"),
("ko_KR", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "상인 아이콘 보기"),
("ko_KR", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "종교 유닛 보기"),
("ko_KR", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "종교 아이콘 전환"),

-- =============================================================================
-- Report Screen
("ko_KR", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "도시 상세정보 보기"),
("ko_KR", "LOC_CUI_RS_BUILDING_NUMBER",                                         "지어진 건물"),
("ko_KR", "LOC_CUI_RS_TOTALS",                                                  "전체: {1_num}"),
("ko_KR", "LOC_CUI_RS_DEALS_OUTGOING",                                          "수출"),
("ko_KR", "LOC_CUI_RS_DEALS_INCOMING",                                          "수입"),

-- =============================================================================
-- SpyInfo
("ko_KR", "LOC_CUI_SI_SPY_AVAILABLE",                                           "현재 활동 중인 [ICON_Unit]스파이: {1_num}"),
("ko_KR", "LOC_CUI_SI_SPY_CAPACITY",                                            "활동 가능한 [ICON_Unit]스파이: {1_num}"),

-- =============================================================================
-- World Tracker
("ko_KR", "LOC_CUI_WT_REMINDER",                                                "조언"),
("ko_KR", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "유레카를 통해 기술을 완료하면 배경색이 녹색으로 변경됩니다."),
("ko_KR", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "영감을 얻어 사회 정책을 완료하면 배경색이 녹색으로 변경됩니다."),
("ko_KR", "LOC_CUI_WT_GOSSIP_LOG",                                              "가십 로그"),
("ko_KR", "LOC_CUI_WT_COMBAT_LOG",                                              "전투 로그"),
("ko_KR", "LOC_CUI_WT_PERSIST",                                                 "지속"),
("ko_KR", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "지나간 턴의 가십로그를 유지합니다."),
("ko_KR", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "지나간 컨의 가십로그를 유지합니다."),

-- =============================================================================
-- Trade Panel
("ko_KR", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "[ICON_Food]식량 순 정렬"),
("ko_KR", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "[ICON_Production]생산 순 정렬"),
("ko_KR", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "[ICON_Gold]금액 순 정렬"),
("ko_KR", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "[ICON_Science]과학 순 정렬"),
("ko_KR", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "[ICON_Culture]문화 순 정렬"),
("ko_KR", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "[ICON_Faith]신앙 순 정렬"),
("ko_KR", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "[ICON_Turn]교역로가 완성되는 시간 순 정렬"),
("ko_KR", "LOC_CUI_TP_REPEAT",                                                  "반복"),
("ko_KR", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "이 상인이 이 교역로를 반복합니다."),
("ko_KR", "LOC_CUI_TP_SELECT_A_CITY",                                           "이동할 도시를 선택해주세요."),

-- =============================================================================
-- Espionage Panel
("ko_KR", "LOC_CUI_EP_SHOW_CITYS",                                              "도시 보기"),
("ko_KR", "LOC_CUI_EP_SIPHON_FUNDS",                                            "금({1_GoldString})을 얻습니다."),

-- =============================================================================
-- Production Panel
("ko_KR", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "큐를 기본설정으로 사용"),

-- =============================================================================
-- Great Works
("ko_KR", "LOC_CUI_GW_SORT_BY_CITY",                                            "도시 순 정렬"),
("ko_KR", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "건물 순 정렬"),
("ko_KR", "LOC_CUI_GW_THEMING_HELPER",                                          "테마 도우미"),
("ko_KR", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "같은 색과 숫자가 다른 세가지의 걸작을 배치하여 테마를 완성하세요."),

-- =============================================================================
-- Notes
("ko_KR", "LOC_CUI_NOTES",                                                      "노트"),
("ko_KR", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ {1_num}턴에 수정됨 ]"),
("ko_KR", "LOC_CUI_NOTE_EMPTY",                                                 "비어있는 노트"),

-- =============================================================================
-- Options
("ko_KR", "LOC_CUI_OPTIONS_TAB_VICTORY",                                        "승리"),
("ko_KR", "LOC_CUI_OPTIONS_TAB_LOG",                                            "로그"),
("ko_KR", "LOC_CUI_OPTIONS_TAB_POPUP",                                          "팝업"),
("ko_KR", "LOC_CUI_OPTIONS_TAB_REMIND",                                         "리마인드"),
--
("ko_KR", "LOC_CUI_OPTIONS_DESC_VICTORY",                                       "추적할 승리 유형을 선택해주세요."),
("ko_KR", "LOC_CUI_OPTIONS_DESC_LOG",                                           "표시할 로그를 선택해주세요."),
("ko_KR", "LOC_CUI_OPTIONS_DESC_POPUP",                                         "표시할 팝업을 선택해주세요."),
("ko_KR", "LOC_CUI_OPTIONS_DESC_REMIND",                                        "상기가 필요한 내용을 선택해주세요."),
("ko_KR", "LOC_CUI_OPTIONS_DESC_SPEED",                                         "빠른전투 혹은 빠른 이동 대상을 선택해주세요."),
--
("ko_KR", "LOC_CUI_OPTIONS_LOG_SHOW_NONE",                                      "비활성화"),
("ko_KR", "LOC_CUI_OPTIONS_LOG_DEFAULT",                                        "기본 위치"),
("ko_KR", "LOC_CUI_OPTIONS_LOG_WORLDTRACKER",                                   "월드 트래커"),
("ko_KR", "LOC_CUI_OPTIONS_LOG_BOTH",                                           "모두"),
--
("ko_KR", "LOC_CUI_OPTIONS_POPUP_RESEARCH",                                     "기술/사회정책 완료"),
("ko_KR", "LOC_CUI_OPTIONS_POPUP_AUDIO",                                        "기술/사회정책 음성"),
("ko_KR", "LOC_CUI_OPTIONS_POPUP_ERA_SCORE",                                    "시대 점수 획득"),
("ko_KR", "LOC_CUI_OPTIONS_POPUP_GREAT_WORK",                                   "걸작 생성"),
("ko_KR", "LOC_CUI_OPTIONS_POPUP_RELIC",                                        "성유물 획득"),
--
("ko_KR", "LOC_CUI_OPTIONS_REMIND_TECH",                                        "유레카로 기술연구 완료"),
("ko_KR", "LOC_CUI_OPTIONS_REMIND_CIVIC",                                       "영감으로 사회정책연구 완료"),
("ko_KR", "LOC_CUI_OPTIONS_REMIND_GOVERNMENT",                                  "무료 정부 변경"),
("ko_KR", "LOC_CUI_OPTIONS_REMIND_GOVERNOR",                                    "총독 타이틀 획득"),
--
("ko_KR", "LOC_CUI_OPTIONS_QUICK_COMBAT",                                       "빠른 전투"),
("ko_KR", "LOC_CUI_OPTIONS_QUICK_MOVEMENT",                                     "빠른 이동"),
("ko_KR", "LOC_CUI_OPTIONS_SPEED_PLAYER_ONLY",                                  "플레이어 만"),
("ko_KR", "LOC_CUI_OPTIONS_SPEED_AI_ONLY",                                      "AI 만"),

-- =============================================================================
-- Screenshot
("ko_KR", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "스크린샷 모드 실행[NEWLINE][NEWLINE]스크린샷 모드는 대부분의 UI 요서를 숨겨 깔끔한 스크린샷을 찍을 수 있습니다.[NEWLINE][NEWLINE]왼클릭으로 모든 UI 숨기기[NEWLINE][NEWLINE]우클릭으로 도시 배너를 제외한 모든 UI 숨기기[NEWLINE]Alt키로 화면 회전[NEWLINE]ESC키로 스크린샷 모드를 종료하세요."),

-- =============================================================================
("ko_KR", "LOC_CUI_COLON", ": ");
-- EOF
