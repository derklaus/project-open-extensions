-- /packages/intranet-meeting-manager/sql/postgresql/intranet-meeting-manager-create.sql
--
-- Copyright (c) 2014-now Project Open Business Solutions S.L. 
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-------------------------------------------------------------

create table im_meeting_manager_protocols (
        protocol_id 			integer
                                        primary key,
	project_id			integer not null
					REFERENCES im_projects,
	meeting_location		varchar,				
	meeting_name			varchar,
        meeting_day_and_time            timestamptz 
);


create table im_meeting_manager_protocol_items (
        item_id                  	integer
                                        primary key,
        protocol_id                     integer not null
                                        REFERENCES im_meeting_manager_protocols,
        item_number             	varchar, 
	item_name			varchar,
	item_finish_date		timestamp,
	item_order			integer, 
	is_agreement_p			varchar(1)
					DEFAULT 'f',
	CHECK (is_agreement_p = 'f' OR is_agreement_p = 't')
);


SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                	-- object_type
        now(),                        	-- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Meeting Protocolls',		-- plugin_name
        'intranet-meeting-manager',    	-- package_name
        'right',                        -- location
        '/intranet/projects/view',     	-- page_url
        null,                           -- view_name
        1,                              -- sort_order
        'im_meeting_manager_meetings_component -project_id $project_id -return_url /intranet/projects/view&project_id=$project_id' -- component_tcl
);


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS INTEGER AS $BODY$
 
declare
        v_plugin_id                 integer;
begin
 
	SELECT  im_component_plugin__new (
        	null,                           -- plugin_id
		'acs_object',                   -- object_type
        	now(),                          -- creation_date
        	null,                           -- creation_user
       		null,                           -- creation_ip
        	null,                           -- context_id
        	'Meetings Protocolls',          -- plugin_name
        	'intranet-meeting-manager',     -- package_name
        	'right',                        -- location
        	'/intranet/projects/view',      -- page_url
        	null,                           -- view_name
        	1,                              -- sort_order
        	'im_meeting_manager_meetings_component $project_id' -- component_tcl
	) into v_plugin_id;

	PERFORM im_grant_permission(v_plugin_id, 463, 'read');
 
        return 1;
 
end;$BODY$ LANGUAGE 'plpgsql';
 
SELECT inline_0 ();
DROP FUNCTION inline_0 ();
