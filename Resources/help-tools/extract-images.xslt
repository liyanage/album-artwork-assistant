<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
>


<xsl:output method="text" version="1.0" encoding="utf-8" indent="no"/>

<xsl:param name="website"/>

<xsl:template match="/*">
<xsl:apply-templates select="//*[local-name() = 'img']"/>
</xsl:template>

<xsl:template match="*[local-name() = 'img']">
<xsl:value-of select="$website"/>/<xsl:value-of select="@src"/><xsl:text>
</xsl:text>
</xsl:template>


</xsl:stylesheet>