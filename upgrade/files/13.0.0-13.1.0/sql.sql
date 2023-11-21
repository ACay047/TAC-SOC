
SET @sStorageEngine = (SELECT `value` FROM `sys_options` WHERE `name` = 'sys_storage_default');

-- --------------------------- 13.1.0-B1

ALTER TABLE `sys_menu_items` CHANGE `icon` `icon` TEXT NOT NULL; -- should be in 13.0.0-A1

CREATE TABLE IF NOT EXISTS `sys_iframely_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `data` text DEFAULT NULL,
  `added` int(11) DEFAULT NULL,
  `theme` varchar(10) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- OPTIONS

UPDATE `sys_options` SET `value` = 'beta' WHERE `name` = 'sys_upgrade_channel' AND `value` = 'stable';


SET @iCategoryHidden = (SELECT `id` FROM `sys_options_categories` WHERE `name` = 'hidden');

INSERT IGNORE INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_params`, `check_error`, `order`) VALUES
(@iCategoryHidden, 'sys_css_icons_default', '_adm_stg_cpt_option_sys_css_icons_default', 'icons.css', 'digit', '', '', '', '', 182),
(@iCategoryHidden, 'sys_viewport_meta_tag', '_adm_stg_cpt_option_sys_viewport_meta_tag', 'width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0', 'digit', '', '', '', '', 250);


SET @iCategorySiteSettings = (SELECT `id` FROM `sys_options_categories` WHERE `name` = 'site_settings');

INSERT IGNORE INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_error`, `order`) VALUES
(@iCategorySiteSettings, 'sys_live_search_limit', '_adm_stg_cpt_option_sys_live_search_limit', '5', 'digit', '', '', '', 22);


SET @iTypeId = (SELECT `id` FROM `sys_options_types` WHERE `name` = 'system');

DELETE FROM `sys_options_categories` WHERE `name` = 'sockets';
INSERT INTO `sys_options_categories`(`type_id`, `name`, `caption`, `hidden`, `order`) VALUES (@iTypeId, 'sockets', '_adm_stg_cpt_category_sockets', 0, 22);
SET @iCategoryId = LAST_INSERT_ID();

DELETE FROM `sys_options` WHERE `name` IN ('sys_sockets_type', 'sys_sockets_url', 'sys_sockets_app_id', 'sys_sockets_key', 'sys_sockets_secret');
INSERT INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_error`, `order`) VALUES
(@iCategoryId, 'sys_sockets_type', '_adm_stg_cpt_option_sys_sockets_type', 'sys_soketi', 'select', 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:33:"get_options_sockets_field_default";s:5:"class";s:13:"TemplServices";}', '', '', 1),
(@iCategoryId, 'sys_sockets_url', '_adm_stg_cpt_option_sys_sockets_url', '', 'digit', '', '', '', 2),
(@iCategoryId, 'sys_sockets_app_id', '_adm_stg_cpt_option_sys_sockets_app_id', '', 'digit', '', '', '', 3),
(@iCategoryId, 'sys_sockets_key', '_adm_stg_cpt_option_sys_sockets_key', '', 'digit', '', '', '', 4),
(@iCategoryId, 'sys_sockets_secret', '_adm_stg_cpt_option_sys_sockets_secret', '', 'digit', '', '', '', 5);


UPDATE `sys_options` SET `value` = '' WHERE `name` = 'sys_api_menu_top' AND `value` = 'sys_site';

SET @iCategoryApiLayout = (SELECT `id` FROM `sys_options_categories` WHERE `name` = 'api_layout');

INSERT IGNORE INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_error`, `order`) VALUES
(@iCategoryApiLayout, 'sys_api_search_sections', '_adm_stg_cpt_option_sys_api_search_sections', 'bx_posts,bx_persons,bx_groups', 'digit', '', '', '', 20),
(@iCategoryApiLayout, 'sys_api_extended_units', '_adm_stg_cpt_option_sys_api_extended_units', '', 'checkbox', '', '', '', 30);


-- RECOMENDATIONS

CREATE TABLE IF NOT EXISTS `sys_objects_recommendation` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) NOT NULL default '',
  `module` varchar(64) NOT NULL default '',
  `connection` varchar(64) NOT NULL default '',
  `content_info` varchar(64) NOT NULL default '',
  `countable` tinyint(4) NOT NULL DEFAULT '1',
  `active` tinyint(4) NOT NULL DEFAULT '1',
  `class_name` varchar(32) NOT NULL default '',
  `class_file` varchar(256) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
);

CREATE TABLE IF NOT EXISTS `sys_recommendation_criteria` (
  `id` int(11) NOT NULL auto_increment,
  `object_id` int(11) NOT NULL default '0',
  `name` varchar(64) NOT NULL default '',
  `source_type` enum ('sql', 'service') NOT NULL,
  `source` text NOT NULL,
  `params` text NOT NULL,
  `weight` float NOT NULL default '0',
  `active` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `criterion` (`object_id`, `name`)
);

TRUNCATE TABLE `sys_objects_recommendation`;
INSERT INTO `sys_objects_recommendation` (`name`, `module`, `connection`, `content_info`, `countable`, `active`, `class_name`, `class_file`) VALUES
('sys_friends', 'system', 'sys_profiles_friends', '', 1, 1, 'BxTemplRecommendationProfile', '');
SET @iRecFriends = LAST_INSERT_ID();

TRUNCATE TABLE `sys_recommendation_criteria`;
INSERT INTO `sys_recommendation_criteria` (`object_id`, `name`, `source_type`, `source`, `params`, `weight`, `active`) VALUES
(@iRecFriends, 'mutual_friends', 'sql', 'SELECT `tff`.`initiator` AS `id`, SUM({points}) AS `value` FROM `sys_profiles_conn_friends` AS `tf` INNER JOIN `sys_profiles_conn_friends` AS `tff` ON `tf`.`content`=`tff`.`content` AND `tff`.`initiator`<>{profile_id} AND `tff`.`initiator` NOT IN (SELECT `content` FROM `sys_profiles_conn_friends` WHERE `initiator`={profile_id} AND `mutual`=''1'') AND `tff`.`mutual`=''1'' WHERE `tf`.`initiator`={profile_id} AND `tf`.`mutual`=''1'' GROUP BY `id`', 'a:1:{s:6:"points";i:2;}', 0.5, 1),
(@iRecFriends, 'shared_context', 'sql', 'SELECT `tm`.`initiator`AS `id`, SUM({points}) AS `value` FROM `{connection}` AS `tg` INNER JOIN `{connection}` AS `tm` ON `tg`.`content`=`tm`.`content` AND `tm`.`initiator`<>{profile_id} AND `tm`.`initiator` NOT IN (SELECT `content` FROM `sys_profiles_conn_friends` WHERE `initiator`={profile_id} AND `mutual`=''1'') AND `tm`.`mutual`=''1'' WHERE `tg`.`initiator`={profile_id} AND `tg`.`mutual`=''1'' GROUP BY `id`', 'a:2:{s:6:"points";i:1;s:10:"connection";s:14:"bx_groups_fans";}', 0.25, 1),
(@iRecFriends, 'shared_location', 'sql', '', '', 0.25, 0);

INSERT INTO `sys_objects_recommendation` (`name`, `module`, `connection`, `content_info`, `countable`, `active`, `class_name`, `class_file`) VALUES
('sys_subscriptions', 'system', 'sys_profiles_subscriptions', '', 1, 1, 'BxTemplRecommendationProfile', '');
SET @iRecSubscriptions = LAST_INSERT_ID();

INSERT INTO `sys_recommendation_criteria` (`object_id`, `name`, `source_type`, `source`, `params`, `weight`, `active`) VALUES
(@iRecSubscriptions, 'mutual_subscriptions', 'sql', 'SELECT `tff`.`content` AS `id`, SUM({points}) AS `value` FROM `sys_profiles_conn_subscriptions` AS `tf` INNER JOIN `sys_profiles_conn_subscriptions` AS `tff` ON `tf`.`content`=`tff`.`initiator` AND `tff`.`content`<>{profile_id} AND `tff`.`content` NOT IN (SELECT `content` FROM `sys_profiles_conn_subscriptions` WHERE `initiator`={profile_id}) WHERE `tf`.`initiator`={profile_id} GROUP BY `id`', 'a:1:{s:6:"points";i:2;}', 0.5, 1),
(@iRecSubscriptions, 'shared_context', 'sql', 'SELECT `tm`.`initiator`AS `id`, SUM({points}) AS `value` FROM `{connection}` AS `tg` INNER JOIN `{connection}` AS `tm` ON `tg`.`content`=`tm`.`content` AND `tm`.`initiator`<>{profile_id} AND `tm`.`initiator` NOT IN (SELECT `content` FROM `sys_profiles_conn_subscriptions` WHERE `initiator`={profile_id}) AND `tm`.`mutual`=''1'' WHERE `tg`.`initiator`={profile_id} AND `tg`.`mutual`=''1'' GROUP BY `id`', 'a:2:{s:6:"points";i:1;s:10:"connection";s:14:"bx_groups_fans";}', 0.5, 1);

CREATE TABLE IF NOT EXISTS `sys_recommendation_data` (
  `id` int(11) NOT NULL auto_increment,
  `profile_id` int(11) NOT NULL default '0',
  `object_id` int(11) NOT NULL default '0',
  `item_id` int(11) NOT NULL default '0',
  `item_value` int(11) NOT NULL default '0',
  `item_reducer` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `recommendation` (`profile_id`, `object_id`, `item_id`)
);


-- STORAGE

UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-document.svg' WHERE `icon` = 'mime-type-document.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-vector.svg' WHERE `icon` = 'mime-type-vector.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-presentation.svg' WHERE `icon` = 'mime-type-presentation.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-archive.svg' WHERE `icon` = 'mime-type-archive.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-spreadsheet.svg' WHERE `icon` = 'mime-type-spreadsheet.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-audio.svg' WHERE `ext` = 'mime-type-audio.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-image.svg' WHERE `ext` = 'mime-type-image.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-video.svg' WHERE `ext` = 'mime-type-video.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-png.svg' WHERE `ext` = 'mime-type-png.png';
UPDATE `sys_storage_mime_types` SET `icon` = 'mime-type-psd.svg' WHERE `ext` = 'mime-type-psd.png';


-- FORMS

UPDATE `sys_objects_form` SET `submit_name` = 'a:2:{i:0;s:10:"do_publish";i:1;s:9:"do_submit";}' WHERE `object` = 'sys_account' AND `submit_name` = 'do_submit';

INSERT IGNORE INTO `sys_form_inputs` (`object`, `module`, `name`, `value`, `values`, `checked`, `type`, `caption_system`, `caption`, `info`, `required`, `collapsed`, `html`, `attrs`, `attrs_tr`, `attrs_wrapper`, `checker_func`, `checker_params`, `checker_error`, `db_pass`, `db_params`, `editable`, `deletable`) VALUES
('sys_account', 'system', 'do_publish', '_sys_form_account_input_publish', '', 0, 'submit', '_sys_form_login_input_caption_system_do_publish', '', '', 0, 0, 0, '', '', '', '', '', '', '', '', 0, 0);

UPDATE `sys_form_inputs` SET `caption_system` = '_sys_form_forgot_password_input_caption_system_password_reset', `caption` = '_sys_form_forgot_password_input_caption_password_reset' WHERE `object` = 'sys_forgot_password' AND `name` = 'password';

UPDATE `sys_form_display_inputs` SET `input_name` = 'do_publish' WHERE `display_name` = 'sys_account_create' AND `input_name` = 'do_submit';


-- MENU

INSERT IGNORE INTO `sys_objects_menu` (`object`, `title`, `set_name`, `module`, `template_id`, `deletable`, `active`, `override_class_name`, `override_class_file`) VALUES
('sys_con_submenu', '_sys_menu_title_con_submenu', 'sys_con_submenu', 'system', 8, 0, 1, '', '');

INSERT IGNORE INTO `sys_menu_sets` (`set_name`, `module`, `title`, `deletable`) VALUES
('sys_con_submenu', 'system', '_sys_menu_set_title_con_submenu', 0);

UPDATE `sys_menu_items` SET `icon` = '<svg width="167" height="28" viewBox="0 0 167 28" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M9.54 18.5C9.43733 18.5 9.358 18.472 9.302 18.416C9.246 18.3507 9.218 18.2713 9.218 18.178V9.036C9.218 8.93333 9.246 8.854 9.302 8.798C9.358 8.73267 9.43733 8.7 9.54 8.7H13.096C13.7867 8.7 14.384 8.812 14.888 9.036C15.4013 9.26 15.798 9.596 16.078 10.044C16.358 10.4827 16.498 11.0333 16.498 11.696C16.498 12.3587 16.358 12.9093 16.078 13.348C15.798 13.7867 15.4013 14.118 14.888 14.342C14.384 14.566 13.7867 14.678 13.096 14.678H10.618V18.178C10.618 18.2713 10.5853 18.3507 10.52 18.416C10.464 18.472 10.3847 18.5 10.282 18.5H9.54ZM10.604 13.502H13.026C13.7167 13.502 14.2347 13.348 14.58 13.04C14.9253 12.732 15.098 12.284 15.098 11.696C15.098 11.1173 14.93 10.6693 14.594 10.352C14.258 10.0347 13.7353 9.876 13.026 9.876H10.604V13.502ZM20.9047 18.64C20.1954 18.64 19.6027 18.5047 19.1267 18.234C18.6507 17.9633 18.2867 17.59 18.0347 17.114C17.7827 16.6287 17.6427 16.078 17.6147 15.462C17.6054 15.3033 17.6007 15.1027 17.6007 14.86C17.6007 14.608 17.6054 14.4073 17.6147 14.258C17.6427 13.6327 17.7827 13.082 18.0347 12.606C18.2961 12.13 18.6647 11.7567 19.1407 11.486C19.6167 11.2153 20.2047 11.08 20.9047 11.08C21.6047 11.08 22.1927 11.2153 22.6687 11.486C23.1447 11.7567 23.5087 12.13 23.7607 12.606C24.0221 13.082 24.1667 13.6327 24.1947 14.258C24.2041 14.4073 24.2087 14.608 24.2087 14.86C24.2087 15.1027 24.2041 15.3033 24.1947 15.462C24.1667 16.078 24.0267 16.6287 23.7747 17.114C23.5227 17.59 23.1587 17.9633 22.6827 18.234C22.2067 18.5047 21.6141 18.64 20.9047 18.64ZM20.9047 17.562C21.4834 17.562 21.9454 17.38 22.2907 17.016C22.6361 16.6427 22.8227 16.1013 22.8507 15.392C22.8601 15.252 22.8647 15.0747 22.8647 14.86C22.8647 14.6453 22.8601 14.468 22.8507 14.328C22.8227 13.6187 22.6361 13.082 22.2907 12.718C21.9454 12.3447 21.4834 12.158 20.9047 12.158C20.3261 12.158 19.8594 12.3447 19.5047 12.718C19.1594 13.082 18.9774 13.6187 18.9587 14.328C18.9494 14.468 18.9447 14.6453 18.9447 14.86C18.9447 15.0747 18.9494 15.252 18.9587 15.392C18.9774 16.1013 19.1594 16.6427 19.5047 17.016C19.8594 17.38 20.3261 17.562 20.9047 17.562ZM27.7024 18.5C27.581 18.5 27.4877 18.472 27.4224 18.416C27.357 18.3507 27.301 18.262 27.2544 18.15L25.2664 11.654C25.2477 11.6073 25.2384 11.5607 25.2384 11.514C25.2384 11.43 25.2664 11.36 25.3224 11.304C25.3877 11.248 25.4577 11.22 25.5324 11.22H26.1484C26.251 11.22 26.3304 11.248 26.3864 11.304C26.4424 11.36 26.4797 11.4113 26.4984 11.458L28.0524 16.736L29.7184 11.514C29.737 11.4487 29.7744 11.3833 29.8304 11.318C29.8957 11.2527 29.989 11.22 30.1104 11.22H30.5864C30.7077 11.22 30.801 11.2527 30.8664 11.318C30.9317 11.3833 30.969 11.4487 30.9784 11.514L32.6444 16.736L34.1984 11.458C34.2077 11.4113 34.2404 11.36 34.2964 11.304C34.3524 11.248 34.4317 11.22 34.5344 11.22H35.1504C35.2344 11.22 35.3044 11.248 35.3604 11.304C35.4164 11.36 35.4444 11.43 35.4444 11.514C35.4444 11.5607 35.435 11.6073 35.4164 11.654L33.4284 18.15C33.4004 18.262 33.349 18.3507 33.2744 18.416C33.209 18.472 33.111 18.5 32.9804 18.5H32.4344C32.313 18.5 32.2104 18.472 32.1264 18.416C32.0517 18.3507 32.0004 18.262 31.9724 18.15L30.3484 13.138L28.7244 18.15C28.687 18.262 28.631 18.3507 28.5564 18.416C28.4817 18.472 28.379 18.5 28.2484 18.5H27.7024ZM39.7016 18.64C38.7402 18.64 37.9749 18.346 37.4056 17.758C36.8362 17.1607 36.5236 16.3487 36.4676 15.322C36.4582 15.2007 36.4536 15.0467 36.4536 14.86C36.4536 14.664 36.4582 14.5053 36.4676 14.384C36.5049 13.7213 36.6589 13.1427 36.9296 12.648C37.2002 12.144 37.5689 11.7567 38.0356 11.486C38.5116 11.2153 39.0669 11.08 39.7016 11.08C40.4109 11.08 41.0036 11.2293 41.4796 11.528C41.9649 11.8267 42.3336 12.2513 42.5856 12.802C42.8376 13.3527 42.9636 13.9967 42.9636 14.734V14.972C42.9636 15.0747 42.9309 15.154 42.8656 15.21C42.8096 15.266 42.7349 15.294 42.6416 15.294H37.7976C37.7976 15.3033 37.7976 15.322 37.7976 15.35C37.7976 15.378 37.7976 15.4013 37.7976 15.42C37.8162 15.8027 37.9002 16.162 38.0496 16.498C38.1989 16.8247 38.4136 17.0907 38.6936 17.296C38.9736 17.5013 39.3096 17.604 39.7016 17.604C40.0376 17.604 40.3176 17.5527 40.5416 17.45C40.7656 17.3473 40.9476 17.2353 41.0876 17.114C41.2276 16.9833 41.3209 16.8853 41.3676 16.82C41.4516 16.6987 41.5169 16.6287 41.5636 16.61C41.6102 16.582 41.6849 16.568 41.7876 16.568H42.4596C42.5529 16.568 42.6276 16.596 42.6836 16.652C42.7489 16.6987 42.7769 16.7687 42.7676 16.862C42.7582 17.002 42.6836 17.1747 42.5436 17.38C42.4036 17.576 42.2029 17.772 41.9416 17.968C41.6802 18.164 41.3629 18.3273 40.9896 18.458C40.6162 18.5793 40.1869 18.64 39.7016 18.64ZM37.7976 14.328H41.6336V14.286C41.6336 13.866 41.5542 13.4927 41.3956 13.166C41.2462 12.8393 41.0269 12.5827 40.7376 12.396C40.4482 12.2 40.1029 12.102 39.7016 12.102C39.3002 12.102 38.9549 12.2 38.6656 12.396C38.3856 12.5827 38.1709 12.8393 38.0216 13.166C37.8722 13.4927 37.7976 13.866 37.7976 14.286V14.328ZM44.9596 18.5C44.8662 18.5 44.7869 18.472 44.7216 18.416C44.6656 18.3507 44.6376 18.2713 44.6376 18.178V11.556C44.6376 11.4627 44.6656 11.3833 44.7216 11.318C44.7869 11.2527 44.8662 11.22 44.9596 11.22H45.6036C45.6969 11.22 45.7762 11.2527 45.8416 11.318C45.9069 11.3833 45.9396 11.4627 45.9396 11.556V12.172C46.1262 11.8547 46.3829 11.6167 46.7096 11.458C47.0362 11.2993 47.4282 11.22 47.8856 11.22H48.4456C48.5389 11.22 48.6136 11.2527 48.6696 11.318C48.7256 11.374 48.7536 11.4487 48.7536 11.542V12.116C48.7536 12.2093 48.7256 12.284 48.6696 12.34C48.6136 12.396 48.5389 12.424 48.4456 12.424H47.6056C47.1016 12.424 46.7049 12.5733 46.4156 12.872C46.1262 13.1613 45.9816 13.558 45.9816 14.062V18.178C45.9816 18.2713 45.9489 18.3507 45.8836 18.416C45.8182 18.472 45.7389 18.5 45.6456 18.5H44.9596ZM52.7172 18.64C51.7559 18.64 50.9905 18.346 50.4212 17.758C49.8519 17.1607 49.5392 16.3487 49.4832 15.322C49.4739 15.2007 49.4692 15.0467 49.4692 14.86C49.4692 14.664 49.4739 14.5053 49.4832 14.384C49.5205 13.7213 49.6745 13.1427 49.9452 12.648C50.2159 12.144 50.5845 11.7567 51.0512 11.486C51.5272 11.2153 52.0825 11.08 52.7172 11.08C53.4265 11.08 54.0192 11.2293 54.4952 11.528C54.9805 11.8267 55.3492 12.2513 55.6012 12.802C55.8532 13.3527 55.9792 13.9967 55.9792 14.734V14.972C55.9792 15.0747 55.9465 15.154 55.8812 15.21C55.8252 15.266 55.7505 15.294 55.6572 15.294H50.8132C50.8132 15.3033 50.8132 15.322 50.8132 15.35C50.8132 15.378 50.8132 15.4013 50.8132 15.42C50.8319 15.8027 50.9159 16.162 51.0652 16.498C51.2145 16.8247 51.4292 17.0907 51.7092 17.296C51.9892 17.5013 52.3252 17.604 52.7172 17.604C53.0532 17.604 53.3332 17.5527 53.5572 17.45C53.7812 17.3473 53.9632 17.2353 54.1032 17.114C54.2432 16.9833 54.3365 16.8853 54.3832 16.82C54.4672 16.6987 54.5325 16.6287 54.5792 16.61C54.6259 16.582 54.7005 16.568 54.8032 16.568H55.4752C55.5685 16.568 55.6432 16.596 55.6992 16.652C55.7645 16.6987 55.7925 16.7687 55.7832 16.862C55.7739 17.002 55.6992 17.1747 55.5592 17.38C55.4192 17.576 55.2185 17.772 54.9572 17.968C54.6959 18.164 54.3785 18.3273 54.0052 18.458C53.6319 18.5793 53.2025 18.64 52.7172 18.64ZM50.8132 14.328H54.6492V14.286C54.6492 13.866 54.5699 13.4927 54.4112 13.166C54.2619 12.8393 54.0425 12.5827 53.7532 12.396C53.4639 12.2 53.1185 12.102 52.7172 12.102C52.3159 12.102 51.9705 12.2 51.6812 12.396C51.4012 12.5827 51.1865 12.8393 51.0372 13.166C50.8879 13.4927 50.8132 13.866 50.8132 14.286V14.328ZM60.3132 18.64C59.7999 18.64 59.3565 18.5513 58.9832 18.374C58.6099 18.1873 58.3019 17.94 58.0592 17.632C57.8259 17.3147 57.6485 16.9553 57.5272 16.554C57.4152 16.1527 57.3499 15.728 57.3312 15.28C57.3219 15.1307 57.3172 14.9907 57.3172 14.86C57.3172 14.7293 57.3219 14.5893 57.3312 14.44C57.3499 14.0013 57.4152 13.5813 57.5272 13.18C57.6485 12.7787 57.8259 12.4193 58.0592 12.102C58.3019 11.7847 58.6099 11.5373 58.9832 11.36C59.3565 11.1733 59.7999 11.08 60.3132 11.08C60.8639 11.08 61.3212 11.178 61.6852 11.374C62.0492 11.57 62.3479 11.8127 62.5812 12.102V8.882C62.5812 8.78867 62.6092 8.714 62.6652 8.658C62.7305 8.59267 62.8099 8.56 62.9032 8.56H63.5752C63.6685 8.56 63.7432 8.59267 63.7992 8.658C63.8645 8.714 63.8972 8.78867 63.8972 8.882V18.178C63.8972 18.2713 63.8645 18.3507 63.7992 18.416C63.7432 18.472 63.6685 18.5 63.5752 18.5H62.9452C62.8425 18.5 62.7632 18.472 62.7072 18.416C62.6512 18.3507 62.6232 18.2713 62.6232 18.178V17.59C62.3899 17.8887 62.0865 18.1407 61.7132 18.346C61.3399 18.542 60.8732 18.64 60.3132 18.64ZM60.6072 17.506C61.0739 17.506 61.4472 17.3987 61.7272 17.184C62.0072 16.9693 62.2172 16.6987 62.3572 16.372C62.4972 16.036 62.5719 15.6953 62.5812 15.35C62.5905 15.2007 62.5952 15.0233 62.5952 14.818C62.5952 14.6033 62.5905 14.4213 62.5812 14.272C62.5719 13.9453 62.4925 13.6233 62.3432 13.306C62.2032 12.9887 61.9885 12.7273 61.6992 12.522C61.4192 12.3167 61.0552 12.214 60.6072 12.214C60.1312 12.214 59.7532 12.3213 59.4732 12.536C59.1932 12.7413 58.9925 13.0167 58.8712 13.362C58.7499 13.698 58.6799 14.062 58.6612 14.454C58.6519 14.7247 58.6519 14.9953 58.6612 15.266C58.6799 15.658 58.7499 16.0267 58.8712 16.372C58.9925 16.708 59.1932 16.9833 59.4732 17.198C59.7532 17.4033 60.1312 17.506 60.6072 17.506ZM73.009 18.64C72.449 18.64 71.9823 18.542 71.609 18.346C71.2357 18.1407 70.937 17.8887 70.713 17.59V18.178C70.713 18.2713 70.6803 18.3507 70.615 18.416C70.559 18.472 70.4843 18.5 70.391 18.5H69.747C69.6537 18.5 69.5743 18.472 69.509 18.416C69.453 18.3507 69.425 18.2713 69.425 18.178V8.882C69.425 8.78867 69.453 8.714 69.509 8.658C69.5743 8.59267 69.6537 8.56 69.747 8.56H70.419C70.5217 8.56 70.601 8.59267 70.657 8.658C70.713 8.714 70.741 8.78867 70.741 8.882V12.102C70.9743 11.8127 71.273 11.57 71.637 11.374C72.0103 11.178 72.4677 11.08 73.009 11.08C73.5317 11.08 73.975 11.1733 74.339 11.36C74.7123 11.5373 75.0157 11.7847 75.249 12.102C75.4917 12.4193 75.6737 12.7787 75.795 13.18C75.9163 13.5813 75.9817 14.0013 75.991 14.44C76.0003 14.5893 76.005 14.7293 76.005 14.86C76.005 14.9907 76.0003 15.1307 75.991 15.28C75.9817 15.728 75.9163 16.1527 75.795 16.554C75.6737 16.9553 75.4917 17.3147 75.249 17.632C75.0157 17.94 74.7123 18.1873 74.339 18.374C73.975 18.5513 73.5317 18.64 73.009 18.64ZM72.715 17.506C73.2003 17.506 73.5783 17.4033 73.849 17.198C74.129 16.9833 74.3297 16.708 74.451 16.372C74.5723 16.0267 74.6423 15.658 74.661 15.266C74.6703 14.9953 74.6703 14.7247 74.661 14.454C74.6423 14.062 74.5723 13.698 74.451 13.362C74.3297 13.0167 74.129 12.7413 73.849 12.536C73.5783 12.3213 73.2003 12.214 72.715 12.214C72.2763 12.214 71.9123 12.3167 71.623 12.522C71.3337 12.7273 71.1143 12.9887 70.965 13.306C70.825 13.6233 70.7503 13.9453 70.741 14.272C70.7317 14.4213 70.727 14.6033 70.727 14.818C70.727 15.0233 70.7317 15.2007 70.741 15.35C70.7597 15.6953 70.8343 16.036 70.965 16.372C71.105 16.6987 71.315 16.9693 71.595 17.184C71.8843 17.3987 72.2577 17.506 72.715 17.506ZM78.7377 21.16C78.6631 21.16 78.5977 21.132 78.5417 21.076C78.4857 21.02 78.4577 20.9547 78.4577 20.88C78.4577 20.8427 78.4624 20.8053 78.4717 20.768C78.4811 20.7307 78.4997 20.684 78.5277 20.628L79.6057 18.066L76.9317 11.752C76.8851 11.64 76.8617 11.5607 76.8617 11.514C76.8617 11.43 76.8897 11.36 76.9457 11.304C77.0017 11.248 77.0717 11.22 77.1557 11.22H77.8417C77.9351 11.22 78.0097 11.2433 78.0657 11.29C78.1217 11.3367 78.1591 11.3927 78.1777 11.458L80.3057 16.554L82.4897 11.458C82.5177 11.3927 82.5551 11.3367 82.6017 11.29C82.6577 11.2433 82.7371 11.22 82.8397 11.22H83.4977C83.5817 11.22 83.6517 11.248 83.7077 11.304C83.7637 11.36 83.7917 11.4253 83.7917 11.5C83.7917 11.5467 83.7684 11.6307 83.7217 11.752L79.7457 20.922C79.7177 20.9873 79.6757 21.0433 79.6197 21.09C79.5731 21.1367 79.4984 21.16 79.3957 21.16H78.7377Z" fill="#478293"/><path d="M96.9739 9.94545C98.0069 8.91955 99.4297 8.28571 101.001 8.28571C101.165 8.28571 101.327 8.29263 101.488 8.3062C101.643 8.31927 101.784 8.2133 101.818 8.0616C102.142 6.60877 103.205 5.43424 104.591 4.95157C104.72 4.9065 104.733 4.71896 104.606 4.66953C103.487 4.23711 102.272 4 101.001 4C99.531 4 98.1355 4.317 96.8786 4.88633C96.7782 4.93184 96.7148 5.03261 96.7148 5.14291V9.84251C96.7148 9.97411 96.8806 10.0382 96.9739 9.94545Z" fill="#3E6B7C"/><path d="M106.937 22.0478C106.844 22.1164 106.715 22.0493 106.715 21.9337V14C106.715 13.8359 106.708 13.6733 106.694 13.5127C106.681 13.3578 106.787 13.2165 106.939 13.1827C108.392 12.8581 109.566 11.796 110.049 10.4098C110.094 10.2804 110.282 10.2671 110.331 10.395C110.763 11.5134 111.001 12.729 111.001 14C111.001 17.3 109.402 20.2266 106.937 22.0478Z" fill="#3E6B7C"/><path d="M108.857 8.99996C108.857 10.5779 107.578 11.8571 106 11.8571C104.422 11.8571 103.143 10.5779 103.143 8.99996C103.143 7.42201 104.422 6.14282 106 6.14282C107.578 6.14282 108.857 7.42201 108.857 8.99996Z" fill="#F97016"/><path d="M91.9516 17.5902C91.9065 17.7196 91.719 17.7329 91.6695 17.605C91.2371 16.4866 91 15.271 91 14C91 10.7001 92.5984 7.77346 95.0633 5.95217C95.1562 5.88354 95.2857 5.95082 95.2857 6.06629V14C95.2857 14.1642 95.2927 14.3267 95.3062 14.4873C95.3193 14.6422 95.2133 14.7835 95.0616 14.8174C93.6088 15.1419 92.4343 16.204 91.9516 17.5902Z" fill="#3E6B7C"/><path d="M105.122 23.1137C105.222 23.0682 105.286 22.9674 105.286 22.8572V18.1575C105.286 18.0259 105.12 17.9619 105.027 18.0546C103.994 19.0805 102.571 19.7143 101 19.7143C100.836 19.7143 100.673 19.7075 100.513 19.6939C100.358 19.6807 100.217 19.7867 100.183 19.9385C99.8581 21.3913 98.796 22.5657 97.4098 23.0484C97.2803 23.0936 97.2671 23.281 97.3949 23.3304C98.5133 23.7629 99.729 24 101 24C102.47 24 103.865 23.683 105.122 23.1137Z" fill="#3E6B7C"/><path d="M98.8569 19C98.8569 20.578 97.5777 21.8571 95.9997 21.8571C94.4218 21.8571 93.1426 20.578 93.1426 19C93.1426 17.422 94.4218 16.1428 95.9997 16.1428C97.5777 16.1428 98.8569 17.422 98.8569 19Z" fill="#F97016"/><path d="M128.5 14C128.5 16.4853 126.485 18.5 124 18.5C121.515 18.5 119.5 16.4853 119.5 14V8.75C119.5 8.33579 119.164 8 118.75 8C118.336 8 118 8.33579 118 8.75V14C118 17.3137 120.686 20 124 20C127.314 20 130 17.3137 130 14V8.75C130 8.33579 129.664 8 129.25 8C128.836 8 128.5 8.33579 128.5 8.75V14Z" fill="#3E6B7C"/><path d="M142.5 14V19.25C142.5 19.6642 142.836 20 143.25 20C143.664 20 144 19.6642 144 19.25V14C144 10.6863 141.314 8 138 8C134.686 8 132 10.6863 132 14V19.25C132 19.6642 132.336 20 132.75 20C133.164 20 133.5 19.6642 133.5 19.25V14C133.5 11.5147 135.515 9.5 138 9.5C140.485 9.5 142.5 11.5147 142.5 14Z" fill="#3E6B7C"/><path fill-rule="evenodd" clip-rule="evenodd" d="M156.5 17.9687V19.25C156.5 19.6642 156.836 20 157.25 20V20C157.664 20 158 19.6642 158 19.25V14C158 10.6863 155.314 8 152 8C148.686 8 146 10.6863 146 14C146 17.3137 148.686 20 152 20C153.792 20 155.401 19.2144 156.5 17.9687ZM156.5 14C156.5 16.4853 154.485 18.5 152 18.5C149.515 18.5 147.5 16.4853 147.5 14C147.5 11.5147 149.515 9.5 152 9.5C154.485 9.5 156.5 11.5147 156.5 14Z" fill="#3E6B7C"/><rect x="0.5" y="0.5" width="166" height="27" rx="7.5" stroke="#478293"/></svg>' WHERE `set_name` = 'sys_footer' AND `name` = 'powered_by';

DELETE FROM `sys_menu_items` WHERE `set_name` = 'sys_profile_stats' AND `name` = 'friend-suggestions';
INSERT INTO `sys_menu_items` (`set_name`, `module`, `name`, `title_system`, `title`, `link`, `onclick`, `target`, `icon`, `addon`, `submenu_object`, `visible_for_levels`, `active`, `copyable`, `order`) VALUES
('sys_profile_stats', 'system', 'friend-suggestions', '_sys_menu_item_title_system_connections', '_sys_menu_item_title_connections', 'page.php?i=friend-suggestions', '', '', 'users', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:31:"get_unconfirmed_connections_num";s:6:"params";a:1:{i:0;s:20:"sys_profiles_friends";}s:5:"class";s:23:"TemplServiceConnections";}', '', 2147483646, 1, 1, 1);

DELETE FROM `sys_menu_items` WHERE `set_name` = 'sys_con_submenu';
INSERT INTO `sys_menu_items` (`set_name`, `module`, `name`, `title_system`, `title`, `link`, `onclick`, `target`, `icon`, `addon`, `submenu_object`, `visible_for_levels`, `visibility_custom`, `active`, `copyable`, `order`) VALUES
('sys_con_submenu', 'system', 'friends', '', '_sys_menu_item_title_con_friends', 'page.php?i=friends', '', '', '', '', '', 2147483647, '', 1, 1, 1),
('sys_con_submenu', 'system', 'friend-suggestions', '', '_sys_menu_item_title_recom_friends', 'page.php?i=friend-suggestions', '', '', '', '', '', 2147483647, '', 1, 1, 2),
('sys_con_submenu', 'system', 'friend-requests', '', '_sys_menu_item_title_con_friend_requests', 'page.php?i=friend-requests', '', '', '', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:31:"get_unconfirmed_connections_num";s:6:"params";a:1:{i:0;s:20:"sys_profiles_friends";}s:5:"class";s:23:"TemplServiceConnections";}', '', 2147483647, '', 1, 1, 3),
('sys_con_submenu', 'system', 'sent-friend-requests', '', '_sys_menu_item_title_con_friend_requested', 'page.php?i=sent-friend-requests', '', '', '', '', '', 2147483647, '', 1, 1, 4),
('sys_con_submenu', 'system', 'follow-suggestions', '', '_sys_menu_item_title_recom_subscriptions', 'page.php?i=follow-suggestions', '', '', '', '', '', 2147483647, '', 1, 1, 5),
('sys_con_submenu', 'system', 'followers', '', '_sys_menu_item_title_con_followers', 'page.php?i=followers', '', '', '', '', '', 2147483647, '', 1, 1, 6),
('sys_con_submenu', 'system', 'following', '', '_sys_menu_item_title_con_following', 'page.php?i=following', '', '', '', '', '', 2147483647, '', 1, 1, 7);


-- PAGES

INSERT IGNORE INTO `sys_objects_page` (`object`, `uri`, `title_system`, `title`, `module`, `cover`, `layout_id`, `submenu`, `visible_for_levels`, `visible_for_levels_editable`, `url`, `meta_description`, `meta_keywords`, `meta_robots`, `cache_lifetime`, `cache_editable`, `deletable`, `override_class_name`, `override_class_file`, `sticky_columns`) VALUES
('sys_con_friends', 'friends', '_sys_page_title_system_con_friends', '_sys_page_title_con_friends', 'system', 1, 12, '', 2147483646, 1, 'page.php?i=friends', '', '', '', 0, 1, 0, 'BxTemplPageConnections', '', 0),
('sys_con_friend_requests', 'friend-requests', '_sys_page_title_system_con_friend_requests', '_sys_page_title_con_friend_requests', 'system', 1, 12, '', 2147483646, 1, 'page.php?i=friend-requests', '', '', '', 0, 1, 0, 'BxTemplPageConnections', '', 0),
('sys_con_friend_requested', 'sent-friend-requests', '_sys_page_title_system_con_friend_requested', '_sys_page_title_con_friend_requested', 'system', 1, 12, '', 2147483646, 1, 'page.php?i=sent-friend-requests', '', '', '', 0, 1, 0, 'BxTemplPageConnections', '', 0),
('sys_con_following', 'following', '_sys_page_title_system_con_following', '_sys_page_title_con_following', 'system', 1, 12, '', 2147483646, 1, 'page.php?i=following', '', '', '', 0, 1, 0, 'BxTemplPageConnections', '', 0),
('sys_con_followers', 'followers', '_sys_page_title_system_con_followers', '_sys_page_title_con_followers', 'system', 1, 12, '', 2147483646, 1, 'page.php?i=followers', '', '', '', 0, 1, 0, 'BxTemplPageConnections', '', 0),
('sys_recom_friends', 'friend-suggestions', '_sys_page_title_system_recom_friends', '_sys_page_title_recom_friends', 'system', 1, 12, '', 2147483646, 1, 'page.php?i=friend-suggestions', '', '', '', 0, 1, 0, 'BxTemplPageConnections', '', 0),
('sys_recom_subscriptions', 'follow-suggestions', '_sys_page_title_system_recom_subscriptions', '_sys_page_title_recom_subscriptions', 'system', 1, 12, '', 2147483646, 1, 'page.php?i=follow-suggestions', '', '', '', 0, 1, 0, 'BxTemplPageConnections', '', 0);


SET @iBlockOrder = IFNULL((SELECT `order` FROM `sys_pages_blocks` WHERE `object` = '' AND `cell_id` = 0 ORDER BY `order` DESC LIMIT 1), 0);

DELETE FROM `sys_pages_blocks` WHERE `object` = '' AND `title_system` IN('_sys_page_block_title_sys_recom_friends', '_sys_page_block_title_sys_recom_subscriptions');
INSERT INTO `sys_pages_blocks` (`object`, `cell_id`, `module`, `title_system`, `title`, `designbox_id`, `tabs`, `async`, `visible_for_levels`, `type`, `content`, `deletable`, `copyable`, `active`, `order`) VALUES
('', 0, 'system', '_sys_page_block_title_sys_recom_friends', '_sys_page_block_title_recom_friends', 11, 1, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:30:"browse_recommendations_friends";s:6:"params";a:0:{}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, @iBlockOrder + 1),
('', 0, 'system', '_sys_page_block_title_sys_recom_subscriptions', '_sys_page_block_title_recom_subscriptions', 11, 1, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:36:"browse_recommendations_subscriptions";s:6:"params";a:0:{}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, @iBlockOrder + 1);

UPDATE `sys_pages_blocks` SET `content` = 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:28:"account_profile_switcher_all";s:6:"params";a:0:{}s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `object` = 'sys_account_profile_switcher' AND `title` = '_sys_page_block_title_account_profile_switcher';


DELETE FROM `sys_pages_blocks` WHERE `object` IN('sys_con_friends', 'sys_con_friend_requests', 'sys_con_friend_requested', 'sys_con_following', 'sys_con_followers', 'sys_recom_friends', 'sys_recom_subscriptions');

INSERT INTO `sys_pages_blocks` (`object`, `cell_id`, `module`, `title_system`, `title`, `designbox_id`, `tabs`, `async`, `visible_for_levels`, `type`, `content`, `deletable`, `copyable`, `active`, `order`) VALUES

('sys_con_friends', 1, 'system', '', '_sys_page_block_title_con_friends', 11, 0, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:14:"browse_friends";s:6:"params";a:2:{i:0;s:12:"{profile_id}";i:1;a:1:{s:13:"empty_message";b:1;}}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, 1),
('sys_con_friend_requests', 1, 'system', '', '_sys_page_block_title_con_friend_requests', 11, 0, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:22:"browse_friend_requests";s:6:"params";a:2:{i:0;s:12:"{profile_id}";i:1;a:1:{s:13:"empty_message";b:1;}}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, 1),
('sys_con_friend_requested', 1, 'system', '', '_sys_page_block_title_con_friend_requested', 11, 0, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:23:"browse_friend_requested";s:6:"params";a:2:{i:0;s:12:"{profile_id}";i:1;a:1:{s:13:"empty_message";b:1;}}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, 1),

('sys_con_following', 1, 'system', '', '_sys_page_block_title_con_following', 11, 0, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:20:"browse_subscriptions";s:6:"params";a:2:{i:0;s:12:"{profile_id}";i:1;a:1:{s:13:"empty_message";b:1;}}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, 1),
('sys_con_followers', 1, 'system', '', '_sys_page_block_title_con_followers', 11, 0, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:20:"browse_subscribed_me";s:6:"params";a:2:{i:0;s:12:"{profile_id}";i:1;a:1:{s:13:"empty_message";b:1;}}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, 1),

('sys_recom_friends', 1, 'system', '', '_sys_page_block_title_recom_friends', 11, 0, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:30:"browse_recommendations_friends";s:6:"params";a:2:{i:0;s:12:"{profile_id}";i:1;a:1:{s:13:"empty_message";b:1;}}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, 1),
('sys_recom_subscriptions', 1, 'system', '', '_sys_page_block_title_recom_subscriptions', 11, 0, 0, 2147483647, 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:36:"browse_recommendations_subscriptions";s:6:"params";a:2:{i:0;s:12:"{profile_id}";i:1;a:1:{s:13:"empty_message";b:1;}}s:5:"class";s:20:"TemplServiceProfiles";}', 0, 1, 1, 1);


-- PRELOADER

DELETE FROM `sys_preloader` WHERE `module` = 'system' AND `type` = 'css_system' AND (`content` = 'icons.css' OR `content` = 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:21:"get_preloader_content";s:6:"params";a:1:{i:0;s:5:"icons";}s:5:"class";s:12:"BaseServices";}');
INSERT INTO `sys_preloader`(`module`, `type`, `content`, `active`, `order`) VALUES
('system', 'css_system', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:21:"get_preloader_content";s:6:"params";a:1:{i:0;s:5:"icons";}s:5:"class";s:12:"BaseServices";}', 1, 13);

DELETE FROM `sys_preloader` WHERE `module` = 'system' AND `type` = 'js_system' AND `content` = 'pusher/pusher.min.js';
INSERT INTO `sys_preloader`(`module`, `type`, `content`, `active`, `order`) VALUES
('system', 'js_system', 'pusher/pusher.min.js', 1, 0);

DELETE FROM `sys_preloader` WHERE `module` = 'system' AND `type` = 'js_system' AND `content` = 'BxDolSockets.js';
INSERT INTO `sys_preloader`(`module`, `type`, `content`, `active`, `order`) VALUES
('system', 'js_system', 'BxDolSockets.js', 1, 45);


-- TRANSCODERS

UPDATE `sys_objects_transcoder` SET `ts` = UNIX_TIMESTAMP() WHERE `object` IN('bx_ads_cover', 'bx_ads_view_photos', 'bx_channels_cover', 'bx_classes_cover', 'bx_classes_gallery_photos', 'bx_courses_cover', 'bx_events_cover', 'bx_forum_cover', 'bx_forum_view_photos', 'bx_glossary_cover', 'bx_groups_cover', 'bx_market_cover', 'bx_photos_cover', 'bx_polls_cover', 'bx_posts_cover', 'bx_posts_view_photos', 'bx_snipcart_cover', 'bx_spaces_cover', 'bx_stream_cover', 'bx_tasks_cover', 'bx_tasks_gallery_photos', 'bx_timeline_photos_big', 'bx_timeline_videos_photo_big', 'bx_videos_cover');


-- --------------------------- 13.1.0-B2

-- Settings

SET @iTypeId = (SELECT `id` FROM `sys_options_types` WHERE `name` = 'system');

DELETE FROM `sys_options_categories` WHERE `name` = 'pwa_manifest';
INSERT INTO `sys_options_categories`(`type_id`, `name`, `caption`, `hidden`, `order`) VALUES (@iTypeId, 'pwa_manifest', '_adm_stg_cpt_category_pwa_manifest', 1, 2);
SET @iCategoryId = LAST_INSERT_ID();

DELETE FROM `sys_options` WHERE `name` IN('sys_pwa_manifest_name', 'sys_pwa_manifest_short_name', 'sys_pwa_manifest_description', 'sys_pwa_manifest_background_color', 'sys_pwa_manifest_theme_color');
INSERT INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_error`, `order`) VALUES
(@iCategoryId, 'sys_pwa_manifest_name', '_adm_stg_cpt_option_sys_pwa_manifest_name', '', 'digit', '', '', '', 1),
(@iCategoryId, 'sys_pwa_manifest_short_name', '_adm_stg_cpt_option_sys_pwa_manifest_short_name', '', 'digit', '', '', '', 2),
(@iCategoryId, 'sys_pwa_manifest_description', '_adm_stg_cpt_option_sys_pwa_manifest_description', '', 'text', '', '', '', 3), 
(@iCategoryId, 'sys_pwa_manifest_background_color', '_adm_stg_cpt_option_sys_pwa_manifest_background_color', '', 'digit', '', '', '', 4),
(@iCategoryId, 'sys_pwa_manifest_theme_color', '_adm_stg_cpt_option_sys_pwa_manifest_theme_color', '', 'digit', '', '', '', 5);

DELETE FROM `sys_options_categories` WHERE `name` = 'pwa_sw';
INSERT INTO `sys_options_categories`(`type_id`, `name`, `caption`, `hidden`, `order`) VALUES (@iTypeId, 'pwa_sw', '_adm_stg_cpt_category_pwa_sw', 1, 2);
SET @iCategoryId = LAST_INSERT_ID();

DELETE FROM `sys_options` WHERE `name` IN('sys_pwa_sw_enable', 'sys_pwa_sw_cache', 'sys_pwa_sw_offline');
INSERT INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_error`, `order`) VALUES
(@iCategoryId, 'sys_pwa_sw_enable', '_adm_stg_cpt_option_sys_pwa_sw_enable', '', 'checkbox', '', '', '', 1),
(@iCategoryId, 'sys_pwa_sw_cache', '_adm_stg_cpt_option_sys_pwa_sw_cache', '', 'text', '', '', '', 2), 
(@iCategoryId, 'sys_pwa_sw_offline', '_adm_stg_cpt_option_sys_pwa_sw_offline', '', 'digit', '', '', '', 3);

-- Vote and Score objects

UPDATE `sys_objects_vote` SET `ClassName` = 'BxTemplCmtsVoteLikes' WHERE `Name` = 'sys_cmts';
UPDATE `sys_objects_vote` SET `ClassName` = 'BxTemplCmtsVoteReactions' WHERE `Name` = 'sys_cmts_reactions';

UPDATE `sys_objects_score` SET `class_name` = 'BxTemplCmtsScore' WHERE `name` = 'sys_cmts';

-- Recomendations

SET @iRecFriends = (SELECT `id` FROM `sys_objects_recommendation` WHERE `name` = 'sys_friends');

DELETE FROM `sys_recommendation_criteria` WHERE `name` IN('shared_context', 'shared_location', 'last_active') AND `object_id` = @iRecFriends;
INSERT INTO `sys_recommendation_criteria` (`object_id`, `name`, `source_type`, `source`, `params`, `weight`, `active`) VALUES
(@iRecFriends, 'shared_context', 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:44:"get_friend_recommendations_by_shared_context";s:6:"params";a:3:{i:0;s:12:"{profile_id}";i:1;s:12:"{connection}";i:2;s:8:"{points}";}s:5:"class";s:27:"TemplServiceRecommendations";}', 'a:2:{s:6:"points";i:1;s:10:"connection";s:14:"bx_groups_fans";}', 0.20, 1),
(@iRecFriends, 'shared_location', 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:45:"get_friend_recommendations_by_shared_location";s:6:"params";a:3:{i:0;s:12:"{profile_id}";i:1;s:8:"{radius}";i:2;s:8:"{points}";}s:5:"class";s:27:"TemplServiceRecommendations";}', 'a:2:{s:6:"radius";i:10;s:6:"points";i:1;}', 0.20, 1),
(@iRecFriends, 'last_active', 'sql', 'SELECT `tp`.`id` AS `id`, {points} AS `value` FROM `sys_profiles` AS `tp` INNER JOIN `sys_accounts` AS `ta` ON `tp`.`account_id`=`ta`.`id` LEFT JOIN `sys_sessions` AS `ts` ON `tp`.`account_id`=`ts`.`user_id` WHERE `tp`.`id`<>{profile_id} AND `tp`.`id` NOT IN (SELECT `content` FROM `sys_profiles_conn_friends` WHERE `initiator`={profile_id} AND `mutual`=''1'') AND `tp`.`type` IN (''bx_persons'', ''bx_organizations'') ORDER BY `ts`.`date` DESC, `ta`.`logged` DESC, {order_by}', 'a:1:{s:6:"points";i:0;}', 0.1, 1);


SET @iRecSubscriptions = (SELECT `id` FROM `sys_objects_recommendation` WHERE `name` = 'sys_subscriptions');

DELETE FROM `sys_recommendation_criteria` WHERE `name` = 'shared_context' AND `object_id` = @iRecSubscriptions;
INSERT INTO `sys_recommendation_criteria` (`object_id`, `name`, `source_type`, `source`, `params`, `weight`, `active`) VALUES
(@iRecSubscriptions, 'shared_context', 'service', 'a:4:{s:6:"module";s:6:"system";s:6:"method";s:50:"get_subscription_recommendations_by_shared_context";s:6:"params";a:3:{i:0;s:12:"{profile_id}";i:1;s:12:"{connection}";i:2;s:8:"{points}";}s:5:"class";s:27:"TemplServiceRecommendations";}', 'a:2:{s:6:"points";i:1;s:10:"connection";s:14:"bx_groups_fans";}', 0.5, 1);


-- --------------------------- 13.1.0-RC2

-- Options

UPDATE `sys_options` SET `order` = 141 WHERE `name` = 'sys_default_curl_timeout';

SET @iCategoryIdHid = (SELECT `id` FROM `sys_options_categories` WHERE `name` = 'hidden');

INSERT IGNORE INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_params`, `check_error`, `order`) VALUES
(@iCategoryIdHid, 'sys_default_socket_timeout', '_adm_stg_cpt_option_sys_default_socket_timeout', '30', 'digit', '', '', '', '', 140),
(@iCategoryIdHid, 'sys_form_lpc_enable', '_adm_stg_cpt_option_sys_form_lpc_enable', 'on', 'checkbox', '', '', '', '', 260);


SET @iCategoryIdApi = (SELECT `id` FROM `sys_options_categories` WHERE `name` = 'api_layout');

INSERT IGNORE INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_error`, `order`) VALUES
(@iCategoryIdApi, 'sys_api_conn_in_prof_units', '_adm_stg_cpt_option_sys_api_conn_in_prof_units', '', 'checkbox', '', '', '', 31);

-- Pages

UPDATE `sys_pages_blocks` SET `copyable` = 0 WHERE `object` = 'sys_con_friends' AND `title` = '_sys_page_block_title_con_friends';
UPDATE `sys_pages_blocks` SET `copyable` = 0 WHERE `object` = 'sys_con_friend_requests' AND `title` = '_sys_page_block_title_con_friend_requests';
UPDATE `sys_pages_blocks` SET `copyable` = 0 WHERE `object` = 'sys_con_friend_requested' AND `title` = '_sys_page_block_title_con_friend_requested';


UPDATE `sys_pages_blocks` SET `copyable` = 0 WHERE `object` = 'sys_con_following' AND `title` = '_sys_page_block_title_con_following';
UPDATE `sys_pages_blocks` SET `copyable` = 0 WHERE `object` = 'sys_con_followers' AND `title` = '_sys_page_block_title_con_followers';

UPDATE `sys_pages_blocks` SET `copyable` = 0 WHERE `object` = 'sys_recom_friends' AND `title` = '_sys_page_block_title_recom_friends';
UPDATE `sys_pages_blocks` SET `copyable` = 0 WHERE `object` = 'sys_recom_subscriptions' AND `title` = '_sys_page_block_title_recom_subscriptions';


-- --------------------------- 13.1.0-RC3

-- Options

SET @iCategoryIdSS = (SELECT `id` FROM `sys_options_categories` WHERE `name` = 'site_settings');

INSERT IGNORE INTO `sys_options`(`category_id`, `name`, `caption`, `value`, `type`, `extra`, `check`, `check_error`, `order`) VALUES
(@iCategoryIdSS, 'sys_profiles_search_limit', '_adm_stg_cpt_option_sys_profiles_search_limit', '20', 'digit', '', '', '', 23);

-- Menu

UPDATE `sys_objects_menu` SET `override_class_name` = 'BxTemplMenuSubmenuWithAddons' WHERE `object` = 'sys_con_submenu';

UPDATE `sys_menu_items` SET `addon` = 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:21:"profile_friends_count";s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `set_name` = 'sys_con_submenu' AND `name` = 'friends';
UPDATE `sys_menu_items` SET `addon` = 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:36:"profile_recommendation_friends_count";s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `set_name` = 'sys_con_submenu' AND `name` = 'friend-suggestions';
UPDATE `sys_menu_items` SET `addon` = 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:30:"profile_friends_requests_count";s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `set_name` = 'sys_con_submenu' AND `name` = 'friend-requests';
UPDATE `sys_menu_items` SET `addon` = 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:35:"profile_sent_friends_requests_count";s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `set_name` = 'sys_con_submenu' AND `name` = 'sent-friend-requests';
UPDATE `sys_menu_items` SET `addon` = 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:38:"profile_recommendation_following_count";s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `set_name` = 'sys_con_submenu' AND `name` = 'follow-suggestions';
UPDATE `sys_menu_items` SET `addon` = 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:23:"profile_followers_count";s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `set_name` = 'sys_con_submenu' AND `name` = 'followers';
UPDATE `sys_menu_items` SET `addon` = 'a:3:{s:6:"module";s:6:"system";s:6:"method";s:23:"profile_following_count";s:5:"class";s:20:"TemplServiceProfiles";}' WHERE `set_name` = 'sys_con_submenu' AND `name` = 'following';



-- Last step is to update current version

UPDATE `sys_modules` SET `version` = '13.1.0' WHERE `version` = '13.0.0' AND `name` = 'system';

