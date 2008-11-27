<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
>


<xsl:output method="xml" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" version="1.0" encoding="utf-8" indent="yes"/>

<xsl:param name="website"/>
<xsl:param name="lang"/>

<xsl:template match="/*">

<html>

    <head>
        <title>Album Artwork Assistant Help</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        <meta name="robots" content="anchors"/>
        <meta name="template" content="2box"/>
        <meta name="pagetype" content="access"/>
		<meta name="AppleTitle" content="Album Artwork Assistant Help" />
		
		<link rel='stylesheet' type='text/css' href='../../help.css'/>

    </head>

    <body id="apple-pd">

	<h1>Album Artwork Assistant Help</h1>
		
	<p><a href="{$website}">Website</a> <span class='separator'>|</span> <a href='../../release-notes.html'>Release Notes</a></p>

	<div id='onlinehelp'>
		<xsl:copy-of select="//*[@id='onlinehelp']/*[@id=concat('onlinehelp_', $lang)]/node()"/>
	</div>
	
	</body>

</html>
</xsl:template>

</xsl:stylesheet>