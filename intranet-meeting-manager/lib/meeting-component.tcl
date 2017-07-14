# /packages/intranet-meeting-manager/lib/intranet-meeting-component.tcl
#
# Copyright (c) 2014-now Project Open Business Solutions S.L.
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

set sql "
	select 
		protocol_id, 
		project_id,
		meeting_location,
		meeting_name,
		to_char(meeting_day_and_time, 'YYYY-MM-DD') as meeting_date
	from 
		im_meeting_manager_protocols
	where 
		project_id = :project_id
	order by 
		meeting_day_and_time DESC
" 

set table_html "
        <table class='table_list_page' id='action-table'>
        <thead>
        <tr>
                <td>[lang::message::lookup "" intranet-meeting-manager.MeetingId "Id"]</td>
                <td>[lang::message::lookup "" intranet-meeting-manager.Meetingname "Name"]</td>
                <td>[lang::message::lookup "" intranet-meeting-manager.Location "Location"]</td>
                <td>[lang::message::lookup "" intranet-meeting-manager.Date "Date"]</td>
        </tr>
        </thead>
        <tbody>
"
db_foreach r $sql {
    set url [export_vars -base "/intranet-meeting-manager/meeting-minutes/new" { {protocol_id} {project_id} {return_url} } ] 
    append table_html "
	<tr>
		<td>$protocol_id</td>
		<td><a href=\"$url\">$meeting_name</a></td>
		<td>$meeting_location</td>
		<td>$meeting_date</td>
	</tr>
    "	
}

append table_html "
	</tbody>
	</table>
"




