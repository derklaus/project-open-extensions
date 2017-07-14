# /packages/intranet-meeting-manager/tcl/intranet-meeting-manager-procs.tcl
#
# Copyright (c) 2014-now Project Open Business Solutions S.L
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_proc -public im_meeting_manager_meetings_component {
    -project_id
    {-return_url "" }

} {
    Returns a HTML table with that lists all meetings 
} {
    set params [list [list project_id $project_id] [list return_url $return_url]] 
    set result [ad_parse_template -params $params "/packages/intranet-meeting-manager/lib/meeting-component"]
    return [string trim $result]
}
