# /packages/intranet-core/projects/new.tcl

ad_page_contract {

    @param project_id group id
    @param parent_id the parent project id
    @param return_url the url to return to

    @author klaus.hofeditz@project-open.com

} {
    { project_id:integer }
    { protocol_id:integer "" }
    { return_url "" }
}

# ############################################################
# DEFAULTS
# ############################################################

set show_context_help_p 0
set user_id [ad_maybe_redirect_for_registration]
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red>*</font>"
set current_url [im_url_with_query]
set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]

if { ![exists_and_not_null return_url] && [exists_and_not_null project_id]} {
    set return_url [export_vars -base "/intranet/projects/view" {project_id}]
}

# ############################################################
# Permissions
# ############################################################
     
set protocol_exists_p 0

if { "" != $protocol_id } {
    set project_id_verify [db_string get_project_id_verify "select project_id from im_meeting_manager_protocols where protocol_id = :protocol_id " -default 0]
    if { "" != $project_id } {
	if { $project_id_verify != $project_id } {
	    ad_return_complaint 1 [lang::message::lookup "" intranet-meeting-manager.NoProtocolFound "Protocol not found, please verify protocoll_id & project_id"]
	    return 
	}
    } else {
	set project_id $project_id_verify
    }

    set protocol_exists_p 1

    # Check project permissions for this user
    im_project_permissions $user_id $project_id view read write admin
    if {!$write} {
	ad_return_complaint "Insufficient Privileges" "
            <li>You don't have sufficient privileges to see this page."
	return
    }

    set page_title  [lang::message::lookup "" intranet-meeting-manager.EditProtocol "Edit Protocol"]
    set button_text [lang::message::lookup "" intranet-meeting-manager.SaveProtocol "Save Protocol"]

} else {
    set page_title  [lang::message::lookup "" intranet-meeting-manager.NewProtocol "New Protocol"]
    set button_text [lang::message::lookup "" intranet-meeting-manager.CreateProtocol "Create Protocol"]

}


# ############################################################
# Create the Form
# ############################################################

# -----------------------------------------------------------
# Project Members
# -----------------------------------------------------------

set sql_query "
        select
                rels.object_id_two as user_id,
                rels.object_id_two as party_id,
                im_email_from_user_id(rels.object_id_two) as email,
                im_name_from_user_id(rels.object_id_two, $name_order) as name,
		(select count(*) from acs_rels where object_id_one = :protocol_id and object_id_two = rels.object_id_two) as is_participant_p
        from
                acs_rels rels
                LEFT OUTER JOIN im_biz_object_members bo_rels ON (rels.rel_id = bo_rels.rel_id)
                LEFT OUTER JOIN im_categories c ON (c.category_id = bo_rels.object_role_id)
        where
                rels.object_id_one = :project_id and
                rels.object_id_two in (select party_id from parties) and
                rels.object_id_two not in (
                        -- Exclude banned or deleted users
                        select  m.member_id
                        from    group_member_map m,
                                membership_rels mr
                        where   m.rel_id = mr.rel_id and
                                m.group_id = acs__magic_object_id('registered_users') and
                                m.container_id = m.group_id and
                                mr.member_state != 'approved'
                )
        order by
                name
"

# ------------------ Format the table body ----------------

set project_member_count 0
set participants_html ""
set assignee_data [list]


db_foreach users_in_group $sql_query {
    incr project_member_count
    append participants_html "
            <tr>
                    <td>
    "
    # ToDO !!!
    set show_user 0
    if {$show_user > 0} {
	append participants_html "<a href=/intranet/users/view?user_id=$user_id>$name</A>"
    } else {
        append participants_html $name
    }
	
    append participants_html "</td>" 

    if { $is_participant_p } {
	set checked "checked"
    } else {
	set checked ""
    }

    append participants_html "
              <td align=middle>
                <input $checked type='checkbox' name='participated.$user_id' value='1'>
              </td>
    "
    append participants_html "\n</tr>"

    lappend assignee_data "\{\"user_id\":\"$user_id\",\"name\":\"$name\"\}"

}

set assignee_data [join $assignee_data ","]



if { [empty_string_p $participants_html] } {
    set participants_html "<tr><td colspan=2><i>[_ intranet-core.none]</i></td></tr>\n"
}

set participants_html "
             <table class='table_list_page' border=0>
              $participants_html
             </table>
 
"

# -------------------------------------------------------------------------------
# Set attributes, action items and agreements 
# -------------------------------------------------------------------------------

# Defaults Meeting attributes 
set meeting_name ""
set meeting_location ""
set meeting_date ""
set meeting_time ""


# Defaults Action Items 
set ctr_action_items 0 
set existing_action_items_html ""

# Defaults Agreements
set ctr_agreements 0 
set existing_agreements_html ""

set action_items_js ""


if { $protocol_exists_p } {

    # Get "assignees" for all action items and store them in an array 
    set sql "
	select 
		object_id_one, 
		object_id_two 
	from 
		acs_rels 
	where 
		object_id_one in (select item_id from im_meeting_manager_protocol_items where protocol_id = :protocol_id) 
    "

    db_foreach r $sql {
	if { ![info exists action_item_assignee_arr($object_id_one)] } {
	    set action_item_assignee_arr($object_id_one) [list '$object_id_two']
	} else {
	    set action_item_assignee_arr($object_id_one) [lappend action_item_assignee_arr($object_id_one) '$object_id_two']
	}
    }

    # ad_return_complaint xx [array get action_item_assignee_arr]

    # Get Meeting Minutes Attributes 
    set sql "
		select
			meeting_name,
			to_char(meeting_day_and_time, 'YYYY-MM-DD') as meeting_date,
			to_char(meeting_day_and_time, 'hh:mm') as meeting_time
		from 
                    	im_meeting_manager_protocols 
		where 
			protocol_id = :protocol_id						              
    "

    db_1row get_meeting_minutes_attributes $sql

    # Action Items 
    set sql "
		select 
			item_id,
			item_number,
			item_name, 
			to_char(item_finish_date, 'YYYY-MM-DD') as item_finish_date
		from 
			im_meeting_manager_protocol_items
		where 
			protocol_id = :protocol_id and 
			is_agreement_p = 'f' 
		order by 
			item_number
    "

    db_foreach r $sql {
	append existing_action_items_html "
	        <tr>
        	        <td valign='top'><span class='po_form_element'><input type='text' size='3' value='$item_number' name='item_number.$item_id'></span></td>
        	        <td valign='top'><span class='po_form_element'><input type='text' size='60' value='$item_name' name='item_name.$item_id'></span></td>
        	        <td valign='top'><span class='po_form_element' id='basicBoxselect.$item_id'></span></td>
                	<td valign='top'>
                       	<span class='po_form_element'>
                               	<input type='text' size='10' value='$item_finish_date' name='item_finish_date.$item_id' id='item_finish_date.$item_id'>
                               	<input type='button' onclick=\"return showCalendar('item_finish_date.$item_id', 'yyyy-mm-ddd');\" style=\"height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');\">
                       	</span>
                	</td>
        	</tr>
        "
	# Build value field 
	if { [info exists action_item_assignee_arr($item_id)]  } {
	    set value_field [join $action_item_assignee_arr($item_id), ","]
	} else {
	    set value_field ""
	}

	append action_items_js "
		Ext.create('Ext.ux.form.field.BoxSelect', {
                        name: 'assignees.$item_id',
                        id: 'assignees.$item_id',
			displayField: 'name',
			valueField: 'user_id',
			width: 200,
			labelWidth: 130,
			emptyText: 'Choose assignees',
			store: 'User',
			queryMode: 'local',
			value: \[$value_field\],

			renderTo: 'basicBoxselect.$item_id'
		}); \n \n
        "

	incr ctr_action_items
    }

    # Agreements 
    set sql "
                select
			item_id,
                        item_number,
                        item_name
                from
			im_meeting_manager_protocol_items
                where
                        protocol_id = :protocol_id and
                        is_agreement_p = 't'
                order by
                        item_number
    "

    db_foreach r $sql {
            append existing_agreements_html "
                <tr>
                        <td valign='top'><span class='po_form_element'><input type='text' size='3' value='$item_number' name='agreement_number.$item_id'></span></td>
                        <td valign='top'><span class='po_form_element'><input type='text' size='60' value='$item_name' name='agreement_name.$item_id'></span></td>
                </tr>
                "
            incr ctr_action_items
     }
}

# -----------------------------------------------------------
# Action Item Table  
# -----------------------------------------------------------

set action_items_table_html "
	<table class='table_list_page' id='action-table'>
	<thead>
        <tr>
		<td>[lang::message::lookup "" intranet-meeting-manager.ActionItemNo "No."]</td>
                <td>[lang::message::lookup "" intranet-meeting-manager.ActionItem "Action Item"]</td>
                <td>[lang::message::lookup "" intranet-meeting-manager.Who "Who"]</td>
                <td>[lang::message::lookup "" intranet-meeting-manager.UntilWhen "Until When"]</td>
        </tr>
	</thead>
	<tbody>
	$existing_action_items_html
        <tr>
                <td valign='top'><span class='po_form_element'><input type='text' size='3' value='' name='new_item_number.1'></span></td>
                <td valign='top'><span class='po_form_element'><input type='text' size='60' value='' name='new_item_name.1'></span></td>
                <td valign='top'><span class='po_form_element' id='new_item_assignees.1.container'></span></td>
                <td valign='top'>
                        <span class='po_form_element'>
                                <input type='text' size='10' value='' name='new_item_finish_date.1' id='new_item_finish_date.1'>
                                <input type='button' onclick=\"return showCalendar('new_item_finish_date.1', 'yyyy-mm-dd');\" style=\"height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');\">
                        </span>
                </td>
        </tr>
	</tbody>
	</table>	
"

append action_items_js "
            Ext.create('Ext.ux.form.field.BoxSelect', {
                     name: 'box_select_new_item_assignees.1',
                     id: 'box_select_new_item_assignees.1',
                     displayField: 'name',
                     valueField: 'user_id',
                     width: 200,
                     labelWidth: 130,
                     emptyText: 'Choose assignees',
                     store: 'User',
                     queryMode: 'local',
                     renderTo: 'new_item_assignees.1.container',
		     listeners: {
                        change: function(field, newValue, oldValue)
    			{
                           // alert(newValue + ', ' + field.getName() );
			   setHiddenFormField(field.getName(), newValue);	
			}
		     }
            }); \n \n
"

# -----------------------------------------------------------
# Agreements Table  
# -----------------------------------------------------------

set agreements_table_html "
	<table class='table_list_page' id='agreement-table'>
        <thead>
        <tr>
		<td>[lang::message::lookup "" intranet-meeting-manager.AgreementNo "No."]</td>
                <td>[lang::message::lookup "" intranet-meeting-manager.Agreement "Agreement"]</td>

        </tr>
        </thead>
        <tbody>
	$existing_agreements_html
        <tr>
                <td valign='top'><span class='po_form_element'><input type='text' size='3' value='' name='new_agreement_number.1'></span></td>
                <td valign='top'><span class='po_form_element'><input type='text' size='60' value='' name='new_agreement_name.1'></span></td>
        </tr>
        </tbody>
	</table>	
"

# -----------------------------------------------------------
# Load libs 
# -----------------------------------------------------------

# template::head::add_css -href "http://cdn.sencha.io/extjs-4.1.1-gpl/resources/css/ext-all.css" -order "10000"
# template::head::add_css -href "http://cdn.sencha.io/extjs-4.1.1-gpl/examples/shared/example.css" -order "10001"

template::head::add_css -href "/sencha-extjs-v421/resources/css/ext-all.css" -order "10000"
template::head::add_javascript -src "/sencha-extjs-v421/ext-all.js" -order "10001"

template::head::add_css -href "/intranet-meeting-manager/css/BoxSelect.css" -order "10000"
template::head::add_javascript -src "/intranet-meeting-manager/js/BoxSelect.js" -order "10002"

