<!---
	Name: kloutCFC
	Author: Andy Matthews
	Website: http://www.andyMatthews.net || http://kloutCFC.riaforge.org
	Created: 5/26/2011
	Last Updated: 5/26/2011
	History:
			5/26/2011			Initial creation
			6/5/2011			0.1 release
	Purpose: Wrapper for the Klout API
	Version: Listed in contructor
	A ColdFusion wrapper for the Klout social media influence API
--->

<cfcomponent hint="A ColdFusion wrapper for the Klout social media influence API" displayname="kloutCFC" output="false" accessors="true" >

	<cfproperty name="currentVersion" default="1.0">
	<cfproperty name="appName" default="kloutCFC">
	<cfproperty name="lastUpdated">
	<cfproperty name="apiRoot" default="http://api.klout.com/1">
	<cfproperty name="docURL" default="http://developer.klout.com/docs">
	<cfproperty name="apiKey" default="1.0">

	<!--- ##	 INTERNAL METHODS ## --->
	<cffunction name="init" description="Initializes the CFC, returns itself" returntype="kloutCFC" access="public" output="false">
		<cfargument name="apiKey" type="string" required="true">

		<cfscript>
			VARIABLES.currentVersion = '0.1';
			VARIABLES.appName = 'kloutCFC';
			VARIABLES.lastUpdated = DateFormat(CreateDate(2011,06,05),'mm/dd/yyyy');
	        VARIABLES.apiRoot = 'http://api.klout.com/1';
	        VARIABLES.docURL = 'http://developer.klout.com/docs';
	        VARIABLES.apiKey = ARGUMENTS.apiKey;
		</cfscript>

		<cfreturn THIS>
	</cffunction>

	<cffunction name="introspect" description="Returns detailed info about this CFC" returntype="struct" access="public" output="false">
		<cfreturn getMetaData(this)>
	</cffunction>

	<cffunction name="call" description="The actual http call to the remote server" returntype="struct" access="private" output="false">
		<cfargument name="attr" required="true" type="struct">
		<cfargument name="params" required="true" type="struct">

		<cfscript>
			// what fieldtype will this be?
			fieldType = iif( ARGUMENTS.attr['method'] == 'GET', De('URL'), De('formField') );
		</cfscript>

		<cfhttp attributecollection="#ARGUMENTS.attr#">
			<cfloop collection="#ARGUMENTS.params#" item="key">
				<cfhttpparam name="#key#" type="#fieldType#" value="#ARGUMENTS.params[key]#">
			</cfloop>
		</cfhttp>

		<cfreturn cfhttp>

	</cffunction>

	<cffunction name="prep" description="Prepares data for call to remote servers" returntype="struct" access="private" output="false">
		<cfargument name="config" type="struct" required="true">

		<cfscript>
			stringified = '';
			attributes = {};
			returnColdFusion = false;
			params = Duplicate(ARGUMENTS['config']['params']);
			params['key'] = VARIABLES.apiKey;

			// make sure the format type is allowed
			if (NOT ListFindNoCase('cfm,json,xml',LCase(ARGUMENTS['config']['format']))) {
				throw('Allowed output types are cfm, json, and xml');
			}

			// does the user want a coldfusion object returned?
			if (ARGUMENTS['config']['format'] == 'cfm') {
				returnColdFusion = true;
				attributes['format'] = 'json';
			} else {
				attributes['format'] = ARGUMENTS['config']['format'];
			}

			// finish setting up the attributes for the http call
			attributes['url'] = VARIABLES.apiRoot & ARGUMENTS['config']['url'] & '.' & attributes['format'];
			attributes['method'] = ARGUMENTS['config']['method'];

			try {
				data = call(attributes, params);
				stringified = data.filecontent.toString();

				//writedump(var=data.filecontent.toString(), abort=true);

				// is this a valid user?
				if ( FindNoCase('"users":[]',stringified) ) {
					// it's not, so throw an error
					returnStruct.data = '';
					returnStruct.success = 0;
					returnStruct.message = 'Not a valid Klout user. Please try again';
				} else {
					// it is so proceed as normal
					returnStruct.data = (returnColdFusion)  ? deserializeJSON(stringified) : stringified;
					returnStruct.success = 1;
					returnStruct.message = data.StatusCode & ' - Request successful';
				}

			} catch(any e) {
				//set success and message value
				returnStruct.data = '';
				returnStruct.success = 0;
				returnStruct.message = 'An error occurred. Please check your parameters and try your request again.';
			}
		</cfscript>

		<cfreturn returnStruct>
	</cffunction>


	<!--- ##	 SCORE METHODS ## --->
	<cffunction name="klout" description="This method returns a user score pair" returntype="struct" access="public" output="false">
		<cfargument name="output_type" type="string" required="false" default="json">
		<cfargument name="request_type" type="string" required="false" default="get">
		<cfargument name="users" type="string" required="true" hint="Commadelimited list of 5 users or less">

		<cfscript>
			config = {};

			// prepare packet required by the main call method
			// the following values are required for EVERY call
			config['method'] = 'GET';
			config['format'] = ARGUMENTS['output_type'];
			config['url'] = '/klout';

			// the params object should always exist, but may be empty
			config['params'] = {};

			if (ListLen(ARGUMENTS['users']) GT 5) {
				throw('Only 5 usernames allowed.');
			} else {
				config['params']['users'] = Replace(Replace(ARGUMENTS['users'],' ','','ALL'),' ','','ALL');
			}
		</cfscript>

		<cfreturn prep(config)>
	</cffunction>


	<!--- ##	 USER METHODS ## --->
	<cffunction name="show" description="This method returns user objects" returntype="struct" access="public" output="false">
		<cfargument name="output_type" type="string" required="false" default="json">
		<cfargument name="request_type" type="string" required="false" default="get">
		<cfargument name="users" type="string" required="true" hint="Commadelimited list of 5 users or less">

		<cfscript>
			config = {};

			// prepare packet required by the main call method
			// the following values are required for EVERY call
			config['method'] = 'GET';
			config['format'] = ARGUMENTS['output_type'];
			config['url'] = '/users/show';

			// the params object should always exist, but may be empty
			config['params'] = {};

			if (ListLen(ARGUMENTS['users']) GT 5) {
				throw('Only 5 usernames allowed.');
			} else {
				config['params']['users'] = Replace(ARGUMENTS['users'],' ','','ALL');
			}
		</cfscript>

		<cfreturn prep(config)>
	</cffunction>

	<cffunction name="topics" description="This method returns topic objects" returntype="struct" access="public" output="false">
		<cfargument name="output_type" type="string" required="false" default="json">
		<cfargument name="request_type" type="string" required="false" default="get">
		<cfargument name="users" type="string" required="true" hint="Commadelimited list of 5 users or less">

		<cfscript>
			config = {};

			// prepare packet required by the main call method
			// the following values are required for EVERY call
			config['method'] = 'GET';
			config['format'] = ARGUMENTS['output_type'];
			config['url'] = '/users/topics';

			// the params object should always exist, but may be empty
			config['params'] = {};

			if (ListLen(ARGUMENTS['users']) GT 5) {
				throw('Only 5 usernames allowed.');
			} else {
				config['params']['users'] = Replace(ARGUMENTS['users'],' ','','ALL');
			}
		</cfscript>

		<cfreturn prep(config)>
	</cffunction>


	<!--- ##	 RELATIONSHIP METHODS ## --->
	<cffunction name="influenced_by" description="Returns the top 5 user score pairs that are influenced by the given user" returntype="struct" access="public" output="false">
		<cfargument name="output_type" type="string" required="false" default="json">
		<cfargument name="request_type" type="string" required="false" default="get">
		<cfargument name="users" type="string" required="true" hint="Commadelimited list of 5 users or less">

		<cfscript>
			config = {};

			// prepare packet required by the main call method
			// the following values are required for EVERY call
			config['method'] = 'GET';
			config['format'] = ARGUMENTS['output_type'];
			config['url'] = '/soi/influenced_by';

			// the params object should always exist, but may be empty
			config['params'] = {};

			if (ListLen(ARGUMENTS['users']) GT 5) {
				throw('Only 5 usernames allowed.');
			} else {
				config['params']['users'] = Replace(ARGUMENTS['users'],' ','','ALL');
			}
		</cfscript>

		<cfreturn prep(config)>
	</cffunction>

	<cffunction name="influencer_of" description="Returns the top 5 user score pairs that are influencers of the given user" returntype="struct" access="public" output="false">
		<cfargument name="output_type" type="string" required="false" default="json">
		<cfargument name="request_type" type="string" required="false" default="get">
		<cfargument name="users" type="string" required="true" hint="Commadelimited list of 5 users or less">

		<cfscript>
			config = {};

			// prepare packet required by the main call method
			// the following values are required for EVERY call
			config['method'] = 'GET';
			config['format'] = ARGUMENTS['output_type'];
			config['url'] = '/soi/influencer_of';

			// the params object should always exist, but may be empty
			config['params'] = {};

			if (ListLen(ARGUMENTS['users']) GT 5) {
				throw('Only 5 usernames allowed.');
			} else {
				config['params']['users'] = Replace(ARGUMENTS['users'],' ','','ALL');
			}
		</cfscript>

		<cfreturn prep(config)>
	</cffunction>

</cfcomponent>