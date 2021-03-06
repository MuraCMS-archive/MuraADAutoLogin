component extends="mura.cfobject" {
		variables.LDAPServer='';
		variables.LDAPUsername='';
		variables.LDAPpassword='';
		variables.rejectURL='';
		variables.siteid='default';

		function onGlobalRequestStart(m){

			if(request.muraSessionManagement && !m.currentUser().isLoggedIn()){

				//set this to try to by pass for testing other things while not logged in
				var letmein=false;

				if(findNoCase('domain\',CGI.REMOTE_USER) gt 0){
					var SamAccountname=ucase(replacenocase(CGI.REMOTE_USER, 'domain\', ""));

					cfldap(action="query",
						server=variables.LDAPServer,
						name="LDAPResults",
						start="",
						filter="(&(objectclass=user)(SamAccountName=#SamAccountname#))",
						username=variables.LDAPUsername,
						password=variables.LDAPpassword,
						attributes = "cn,o,l,st,sn,c,mail,telephonenumber, givenname, streetaddress, postalcode, SamAccountname, physicalDeliveryOfficeName, department, title");

						if(LDAPResults.recordcount){
							arguments.m.event('siteid',variables.siteid);

							//check to see if the user has previous login into the system
							var userBean=$.getBean('user').loadBy(username=SamAccountname);

							if(!userBean.exists()
									|| 	(
										LDAPResults.givenName != userBean.get('fname')
										|| LDAPResults.sn != userBean.get('lname')
										|| userData.SamAccountname != userBean.get('remoteid')
									)
								){

								if(!userBean.exists()){
									userBean.setPassword(createUUID());
								}

								userBean.set({
										fname=userData.givienName,
										lname=userData.sn,
										username=userData.SamAccountname,
										email=userData.mail,
										remoteid=userData.SamAccountname
								}).save();
							}


							$.getBean("userUtility").loginByUserID(userBean.getUserID(),variables.siteid);

							//set siteArray
							if(session.mura.isLoggedIn){
								session.siteArray=[];
								var settingsManager = $.getBean("settingsManager");
								for( var site in settingsManager.getSites()) {
									if(application.permUtility.getModulePerm("00000000000000000000000000000000000",site)){
										arrayAppend(session.siteArray,site);
									}
								}
							}

						} else if(!letmein){
							location(url=variables.rejectURL, addtoken=false);
						}
				} else if(!letmein) {
					location(url=variables.rejectURL, addtoken=false);
				}

			}

		}

}
