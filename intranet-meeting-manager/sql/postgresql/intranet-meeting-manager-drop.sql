-- /packages/intranet-meeting-manager/sql/postgresql/intranet-meeting-manager-drop.sql
--
-- Copyright (c) 2014-now Project Open Business Solutions S.L.
--
-- All rights including reserved. To inquire license terms please
-- refer to http://www.project-open.com/modules/<module-key>

-------------------------------------------------------------

delete from acs_rels where object_id_one in (select protocol_id from im_meeting_manager_protocols) or object_id_two in (select protocol_id from im_meeting_manager_protocols);
delete from acs_rels where object_id_one in (select item_id from im_meeting_manager_protocol_items) or object_id_two in (select item_id from im_meeting_manager_protocol_items);
delete from acs_objects where object_id in (select protocol_id from im_meeting_manager_protocols);
delete from acs_objects where object_id in (select item_id from im_meeting_manager_protocol_items);

drop table im_meeting_manager_protocol_items;
drop table im_meeting_manager_protocols;

select im_component_plugin__del_module('intranet-meeting-manager');
