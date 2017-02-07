
// made for: https://github.com/jgstew/bigfix-content/blob/master/dashboards/ClientSettingsManager.ojo

function fnCreateTaskClientSettingsXML(name, value, userName="") {
    return `<?xml version="1.0" encoding="UTF-8"?>
<BES xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BES.xsd">
	<Task>
		<Title>Set "${ name }" to "${ value }" - Universal</Title>
		<Description><![CDATA[<P>This task will set a client setting</P><P>This task was automatically generated using the Dashboard: "Custom - Client Settings Manager"</P><P>&nbsp;</P>]]></Description>
		<Relevance>not exists settings "${ name }" whose("${ value }" = value of it) of client</Relevance>
		<Category>Configuration: Client Settings</Category>
		<DownloadSize>0</DownloadSize>
		<Source>Custom Dashboard - Client Settings Manager</Source>
		<SourceID>jgstew${ (userName) ? "; " + userName : "" }</SourceID>
		<SourceReleaseDate>${ (new Date()).toISOString().slice(0,10) }</SourceReleaseDate>
		<SourceSeverity></SourceSeverity>
		<CVENames></CVENames>
		<SANSID></SANSID>
		<Domain>BESC</Domain>
		<DefaultAction ID="Action1">
			<Description>
				<PreLink>Click </PreLink>
				<Link>here</Link>
				<PostLink> to set the Client Setting</PostLink>
			</Description>
			<ActionScript MIMEType="application/x-Fixlet-Windows-Shell">
setting "${ name }"="${ value }" on "{ parameter "action issue date" of action}" for client
			</ActionScript>
			<SuccessCriteria Option="OriginalRelevance"></SuccessCriteria>
		</DefaultAction>
	</Task>
</BES>`;
}

// if this file is run directly, do the following:
if (require.main === module) {
	console.log( fnCreateActionClientSettings("blahSettingName", "blahSettingValue") );
	// http://stackoverflow.com/a/16714931/861745
	// https://github.com/jgstew/tools/blob/master/JS/YYYY-MM-DD.js
}
