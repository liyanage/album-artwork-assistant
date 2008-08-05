<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:aws="http://webservices.amazon.com/AWSECommerceService/2005-10-05"
	exclude-result-prefixes="aws"
>

<xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>

<xsl:template match="/aws:ItemSearchResponse">
	<plist>
		<dict>
			<key>results</key>
			<array>
			<xsl:apply-templates select="aws:Items/aws:Item[aws:LargeImage]"/>
			</array>
		</dict>
	</plist>
</xsl:template>


<xsl:template match="aws:Item">
	<dict>
		<key>url</key>
		<string><xsl:value-of select="aws:LargeImage/aws:URL"/></string>
		<key>tbUrl</key>
		<string><xsl:value-of select="aws:MediumImage/aws:URL"/></string>
		<key>width</key>
		<integer><xsl:value-of select="aws:LargeImage/aws:Width"/></integer>
		<key>height</key>
		<integer><xsl:value-of select="aws:LargeImage/aws:Height"/></integer>
	</dict>
</xsl:template>



</xsl:stylesheet>



