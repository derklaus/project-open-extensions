<master>
<property name="title">#intranet-core.Projects#</property>
<property name="main_navbar_label">projects</property>
<property name="show_context_help_p">@show_context_help_p;noquote@</property>


<form action="new-2.tcl" method="post" name="protocol_form" id="protocol_form">

<input type="hidden" name="project_id" value="@project_id;noquote@" />
<input type="hidden" name="protocol_id" id="protocol_id" value="@protocol_id;noquote@" />
<input type="hidden" name="last_new_row_action_item" id="last_new_row_action_item" value="1" />
<input type="hidden" name="last_new_row_agreement" id="last_new_row_agreement" value="1" />
<input type="hidden" name="return_url" value="@return_url;noquote@" />

<h1><%=[lang::message::lookup "" intranet-meeting-manager.MeetingMinutes "Meeting Minutes"]%></h1>

<table border="0" class="table_list_page">
<tr>
	<td valign="top">
	    <h2><%=[lang::message::lookup "" intranet-meeting-manager.MeetingInfo "Meeting"]%>:</h2>
	    <table class="filter-table">
	        <tr>
            	        <td><%=[lang::message::lookup "" intranet-meeting-manager.MeetingName "Name"]%>@required_field;noquote@</td>
			<td><span class="po_form_element"><input type="text" size="60" value="@meeting_name;noquote@" name="meeting_name"></span></td>
		</tr>
	        <tr>
            	        <td><%=[lang::message::lookup "" intranet-meeting-manager.Location "Location"]%></td>
			<td><span class="po_form_element"><input type="text" size="60" value="@meeting_location;noquote@" name="meeting_location"></span></td>
		</tr>
        	<tr>
			<td><%=[lang::message::lookup "" intranet-meeting-manager.Date "Date"]%>@required_field;noquote@</td>
			<td>
                        <span class="po_form_element">
                                <input type="text" size="10" value="@meeting_date;noquote@" name="meeting_date" id="meeting_date">
                                <input type="button" onclick="return showCalendar('meeting_date', 'yyyy-mm-dd');" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');">
                        </span>
                	</td>
        	</tr>
        	<tr>
			<td><%=[lang::message::lookup "" intranet-meeting-manager.Time "Time"]%></td>
			<td><span class="po_form_element"><input type="text" size="5" value="@meeting_time;noquote@" name="meeting_time"></span></td>
        	</tr>
	     </table>
	</td>
	<td valign="top">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
	<td valign="top">
	    <h2><%=[lang::message::lookup "" intranet-meeting-manager.Participants "Participants"]%>:</h2>
	    @participants_html;noquote@
	</td>
</tr>
</table>

<h2><%=[lang::message::lookup "" intranet-meeting-manager.ActionItems "Action Items"]%>:</h2>
@action_items_table_html;noquote@
<span id="addNewActionItem"><img src="/intranet/images/navbar_default/add.png" alt="" />  <%=[lang::message::lookup "" intranet-meeting-manager.AddNewTask "Add new task"]%></span>

<h2><%=[lang::message::lookup "" intranet-meeting-manager.Agreements "Agreements"]%>:</h2>
@agreements_table_html;noquote@
<span id="addNewAgreement"><img src="/intranet/images/navbar_default/add.png" alt="" />  <%=[lang::message::lookup "" intranet-meeting-manager.AddNewAgreement "Add new agreement"]%></span>
<br><br><br>

<!--<input type="submit" value="@button_text;noquote@">-->

</form>

<button id="btnSubmitForm">@button_text;noquote@</button>

<script type="text/javascript">

Ext.require(['Ext.ux.form.field.BoxSelect']);
Ext.onReady(function() {

	$('#addNewActionItem').click(function() {
		var last_new_row_action_item = $('#last_new_row_action_item').val(); 
		console.log('last_new_row_action_item from hidden Field:' + last_new_row_action_item);
		last_new_row_action_item = ++last_new_row_action_item; 
		$('#last_new_row_action_item').val(last_new_row_action_item);


		// add table row  
		var row_str = '<tr>' +
                        '<td valign="top"><span class="po_form_element"><input type="text" size="3" value="" name="new_item_number.' + last_new_row_action_item + '"></span></td>' +
                        '<td valign="top"><span class="po_form_element"><input type="text" size="60" value="" name="new_item_name.' + last_new_row_action_item + '"></span></td>' +
                        '<td valign="top"><span class="po_form_element" id="new_item_assignees.' + last_new_row_action_item + '"></span></td>' +
                        '<td valign="top">' +
                                '<span class="po_form_element">' +
                                '        <input type="text" size="10" value="" name="new_item_finish_date.' + last_new_row_action_item + '" id="new_item_finish_date.' + last_new_row_action_item + '">' +
                                '        <input type="button" onclick="return showCalendar(\'new_item_finish_date.' + last_new_row_action_item + '\', \'y-m-d\');" style="height:20px; width:20px; background: url(\'/resources/acs-templating/calendar.gif\');">' +
                                '</span>' +
                        '</td>' +
                '</tr>';

		$('#action-table').children('tbody').append(row_str);

		var js_str = "Ext.create('Ext.ux.form.field.BoxSelect', {" +
		     "name: 'new_item_assignees." + last_new_row_action_item +"'," +
 		     "id: 'new_item_assignees." + last_new_row_action_item +"'," +
                     "displayField: 'name'," +
                     "valueField: 'user_id'," +
                     "width: 200," +
                     "labelWidth: 130," +
                     "emptyText: 'Choose assignees'," +
                     "store: 'User'," +
                     "queryMode: 'local'," +
                     "renderTo: 'new_item_assignees." + 
		     last_new_row_action_item +
		     "'" +
            	     "});"
		var newAssigneeSelect = new Function('',js_str);		
		newAssigneeSelect();
	});


        $('#addNewAgreement').click(function() {
                var last_new_row_agreement = $('#last_new_row_agreement').val();
                console.log('last_new_row_agreement from hidden Field:' + last_new_row_agreement);
                last_new_row_agreement = ++last_new_row_agreement;
                $('#last_new_row_agreement').val(last_new_row_agreement);


                // add table row
                var row_str = '<tr>' +
                        '<td valign="top"><span class="po_form_element"><input type="text" size="3" value="" name="new_agreement_number.' + last_new_row_agreement + '"></span></td>' +
                        '<td valign="top"><span class="po_form_element"><input type="text" size="60" value="" name="new_agreement_name.' + last_new_row_agreement + '"></span></td>' +
                '</tr>';

                $('#agreement-table').children('tbody').append(row_str);

        });

	// Special Handling for ExtJS Box 
        var clickHandlerSubmitForm = function() {
	    console.log('Found value field new_item_assignees.1: ' + document.getElementById('box_select_new_item_assignees.1').value);
            var protocolForm = document.forms['protocol_form'];
            for (i = 1; i <= $('#last_new_row_action_item').val(); i++) {
	    	    var fieldName = 'box_select_new_item_assignees.' + i ;
                    var input = document.createElement('input');
	            input.type = 'hidden';
        	    input.name = 'new_item_assignees.' + i;
                    input.value = Ext.getCmp(fieldName).getValue();
                    protocolForm.appendChild(input);
            }
	    var formOK = true;

	    $('#protocol_form *').filter(':input').each(function() {
	       if ('assignees' == this.name.substring(0,9) ) {
                    var input = document.createElement('input');
                    input.type = 'hidden';
		    var foo = this.name.split('.')
                    id = foo[1];
                    input.name = 'item_assignees.' + id;
                    input.value = Ext.getCmp(this.name).getValue();
                    protocolForm.appendChild(input);
	       }
    	    });

            for (i = 1; i <= $('#last_new_row_action_item').val(); i++) {
	    	var fieldName = 'new_item_finish_date.' + i ;
		console.log('fieldName:' + fieldName);
		console.log('value:' + document.getElementById(fieldName).value);
		if ( !document.getElementById(fieldName).value ) {
		   // alert('<%=[lang::message::lookup "" intranet-meeting-manager.DateRequired "Please provide a date for all Action Items"]%>');
		   // formOK = false;
		   // break;		   
		}
		
		if ( document.getElementById(fieldName).value && !Ext.Date.parse(document.getElementById(fieldName).value,'c') ) {
                   alert('<%=[lang::message::lookup "" intranet-meeting-manager.WrongDateFormat "Wrong date or date format found - Date format must be: YYYY-MM-DD"]%>');
                   formOK = false;
		   break;
                }
	    }
	    if ( formOK ) { protocolForm.submit(); }
        };

        var setHiddenFormField = function(field, value) {
                // alert(Ext.getCmp(field).getRawValue());
                // alert(Ext.getCmp('new_item_assignees.1').getValue());
        };


 	//add listener for button click
        Ext.EventManager.on('btnSubmitForm', 'click', clickHandlerSubmitForm);

	(function() {

		// Define the model for a State
		Ext.define('User', {
	    		extend: 'Ext.data.Model',
	        	fields: [
				{type: 'string', name: 'user_id'},
				{type: 'string', name: 'name'}
    			]
		});

		var users = [@assignee_data;noquote@];

		var statesStore = Ext.create('Ext.data.Store', {
	    		model: 'User',
	    		storeId: 'User',
	    		data: users
		});

	})();
/*

        function setHiddenFormField(field, value) {
		// alert(Ext.getCmp('new_item_assignees.1').getRawValue()); 
                // alert(target_languages);

        };
*/
	<!-- INCLUDE SELECT BOXES: ASSIGNEES --> 
	@action_items_js;noquote@

});


	$(document).ready(function(){
	});

</script>
