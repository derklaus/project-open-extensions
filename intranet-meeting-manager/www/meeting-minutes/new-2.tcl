# /packages/intranet-meeting-manager/www/meeting-minutes/new-2.tcl
#

ad_page_contract {
    Writes / updates protocol  

} {
    project_id:integer
    { protocol_id:integer "" }
    { meeting_name }
    { meeting_location ""}
    { meeting_date}
    { meeting_time ""}
    { participated:array "" }
    { item_number:array ""}
    { item_name:array ""}
    { item_assignees:array ""}
    { item_finish_date:array ""}
    { new_item_number:array ""}
    { new_item_name:array ""}
    { new_item_assignees:array ""}
    { new_item_finish_date:array ""}
    { agreement_number:array ""}
    { agreement_name:array ""}
    { new_agreement_number:array ""}
    { new_agreement_name:array ""}
    { return_url "" }
}

# ############################################################
# DEFAULTS
# ############################################################

set user_id [ad_maybe_redirect_for_registration]

# ############################################################
# Validation & Preparation 
# ############################################################

if {[catch {
     if { $meeting_date != [clock format [clock scan $meeting_date] -format %Y-%m-%d] } {
        ad_return_complaint 1 "<strong>[_ intranet-core.Meeting_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$meeting_date'<br>"
    }
} err_msg]} {
    ad_return_complaint 1 "<strong>[_ intranet-core.Meeting_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
    [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$meeting_date'<br>
    [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
}

if { ""== $meeting_time } { set meeting_time "00:00" }
set meeting_day_and_time "$meeting_date ${meeting_time}:00-00"

# -----------------------------------------------------------------
# Create a new Protocol if it didn't exist yet
# -----------------------------------------------------------------

if {![exists_and_not_null protocol_id]} {
  
    set protocol_id [db_string get_protocol_id "select acs_object__new(null,'acs_object')" -default 0]

    set sql "
	insert into im_meeting_manager_protocols 
		(protocol_id, meeting_name, meeting_location, meeting_day_and_time, project_id) 
	values
		(:protocol_id, :meeting_name, :meeting_location, :meeting_day_and_time, :project_id) 
   "
    if {[catch {
	db_dml create_protocol $sql
    } err_msg]} {
	global errorInfo
	ns_log Error $errorInfo
	ad_return_complaint 1 "[lang::message::lookup "" intranet-meeting-manager.UnableToStoreProtocol "Protocol can't be stored"]: $errorInfo"
	return
    }

} else {
    # Protocoll exists 
}

# -----------------------------------------------------------------
# Set Participants
# -----------------------------------------------------------------

foreach participant [array names participated] {
    # Todo: Improve 
    if {[catch {
	set rel_id [db_string get_protocol_id "select acs_object__new(null,'relationship')" -default 0]
	db_dml set_meeting_participants "insert into acs_rels (rel_id, object_id_one, object_id_two, rel_type) values (:rel_id, :protocol_id, :participant, 'relationship')"
    } err_msg]} {
	global errorInfo
	ns_log Error $errorInfo
    }
}

# -----------------------------------------------------------------
# Save all new Action Items 
# -----------------------------------------------------------------

foreach item [array names new_item_number] {

    # Ignore when no name has been provided
    if { "" == $new_item_name($item) } { continue }

    set item_number_ $new_item_number($item)
    set item_name_ $new_item_name($item)
    set finish_date_ $new_item_finish_date($item)

    set item_id [db_string get_item_id "select acs_object__new(null, 'acs_object')" -default 0]
    set sql "
        insert into im_meeting_manager_protocol_items
                (item_id, protocol_id, item_number, item_name, item_finish_date, item_order, is_agreement_p)
        values
                (:item_id, :protocol_id, :item_number_, :item_name_, :finish_date_, 0, 'f')
    "
    if {[catch {
        db_dml create_item $sql
    } err_msg]} {
        global errorInfo
        ns_log Error $errorInfo
        ad_return_complaint 1 "[lang::message::lookup "" intranet-meeting-manager.UnableToCreateItem "Action item can't be stored"]: $errorInfo"
        return
    }

    # Set Assignees
    foreach assignee [split $new_item_assignees($item) ","] {
	if {[catch {
	    set rel_id [db_string get_protocol_id "select acs_object__new(null,'relationship')" -default 0]
	    db_dml set_action_item_assignees "insert into acs_rels (rel_id, object_id_one, object_id_two, rel_type) values (:rel_id, :item_id, :assignee, 'relationship')"
	} err_msg]} {
	    global errorInfo
	    ns_log Error $errorInfo
	}
    }
}

# -----------------------------------------------------------------
# Save all new Agreements
# -----------------------------------------------------------------

foreach item [array names new_agreement_number] {

    # Ignore when no name has been provided
    if { "" == $new_agreement_name($item) } { continue }

    set number_ $new_agreement_number($item)
    set name_ $new_agreement_name($item)

    set item_id [db_string get_item_id "select acs_object__new(null, 'acs_object')" -default 0]
    set sql "
        insert into im_meeting_manager_protocol_items
                (item_id, protocol_id, item_number, item_name, is_agreement_p)
        values
                (:item_id, :protocol_id, :number_, :name_, 't')
    "

    if {[catch {
        db_dml create_item $sql
    } err_msg]} {
        global errorInfo
        ns_log Error $errorInfo
        ad_return_complaint 1 "[lang::message::lookup "" intranet-meeting-manager.UnableToCreateItem "Agreement item can't be stored"]: $errorInfo"
        return
    }
}

# -----------------------------------------------------------------
# Updating existent Action Items 
# -----------------------------------------------------------------

foreach item [array names item_number] {

    set item_number_ $item_number($item)
    set item_name_ $item_name($item)
    set finish_date_ $item_finish_date($item)

    set sql "
        update im_meeting_manager_protocol_items set 
                (item_number, item_name, item_finish_date)
        =
                (:item_number_, :item_name_, :finish_date_ )
	where 
		item_id = :item
    "

    if {[catch {
        db_dml update_item $sql
    } err_msg]} {
        global errorInfo
        ns_log Error $errorInfo
        ad_return_complaint 1 "[lang::message::lookup "" intranet-meeting-manager.UnableToCreateItem "Action item can't be stored"]: $errorInfo"
        return
    }

    # TodDo: Improve - currently we assume that only acs_rels assignee rels are stored 
    db_dml remove_item_assignees "delete from acs_rels where object_id_one = :item and rel_type = 'relationship'"

    # re-create Assignees
    if { [info exists item_assignees($item)] } {
	foreach assignee [split $item_assignees($item) ","] {
	    if {[catch {
		set rel_id [db_string get_new_rel_id "select acs_object__new(null,'relationship')" -default 0]
		db_dml set_action_item_assignees "insert into acs_rels (rel_id, object_id_one, object_id_two, rel_type) values (:rel_id, :item, :assignee, 'relationship')"
	    } err_msg]} {
		global errorInfo
		ns_log Error $errorInfo
	    }
	}
     }
}

# -----------------------------------------------------------------
# Updating existent Agreements 
# -----------------------------------------------------------------

foreach item [array names agreement_number] {

    set number_ $agreement_number($item)
    set name_ $agreement_name($item)
    set sql "update im_meeting_manager_protocol_items set (item_number, item_name) = (:number_, :name_) where item_id = :item"

    if {[catch {
        db_dml update_agreement $sql
    } err_msg]} {
        global errorInfo
        ns_log Error $errorInfo
        ad_return_complaint 1 "[lang::message::lookup "" intranet-meeting-manager.UnableToCreateItem "Agreement item can't be stored"]: $errorInfo"
        return
    }
}


db_release_unused_handles

if { "" == $return_url } {
    ad_return_complaint [export_vars -base "/intranet-meeting-manager/meeting-minutes/new" {{protocol_id} {project_id}} ]
} else {
    ad_returnredirect $return_url
}



