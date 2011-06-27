<?xml version='1.0' encoding='iso-8859-1'?>
<xsl:stylesheet version='1.0' 
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

	<xsl:output omit-xml-declaration="yes" indent="no" />

	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="count( /envelope/message ) &gt; 1">
				<xsl:apply-templates select="/envelope/message[last()]" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="envelope | message">
		<xsl:variable name="envelopeClasses">
			<xsl:choose>
				<xsl:when test="(message[1]/@highlight = 'yes' and message[1]/@action = 'yes') or (@highlight = 'yes' and @action = 'yes')">
					<xsl:text>envelope highlight action</xsl:text>
				</xsl:when>
				<xsl:when test="message[1]/@action = 'yes' or @action = 'yes'">
					<xsl:text>envelope action</xsl:text>
				</xsl:when>
				<xsl:when test="message[1]/@highlight = 'yes' or @highlight = 'yes'">
					<xsl:text>envelope highlight</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>envelope</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="allClasses">
			<xsl:choose>
				<xsl:when test="(message[1]/@ignored = 'yes' or ../@ignored = 'yes') or (@ignored = 'yes')">
					<xsl:value-of select="$envelopeClasses" />
					<xsl:text> ignore</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$envelopeClasses" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="senderNick" select="sender | ../sender" />

		<xsl:variable name="senderClasses">
			<xsl:choose>
				<xsl:when test="$senderNick/@self = 'yes'">
					<xsl:text>member self</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>member</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="$senderNick/@class = 'operator'">
				<xsl:text> operator</xsl:text>
			</xsl:if>
			<xsl:if test="$senderNick/@class = 'voice'">
				<xsl:text> voice</xsl:text>
			</xsl:if>
		</xsl:variable>

		<xsl:variable name="envelopeSenderClasses">
			<xsl:choose>
				<xsl:when test="$senderNick/@self = 'yes'">
					<xsl:text>self</xsl:text>
				</xsl:when>
				<xsl:otherwise></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="hostmask" select="sender/@hostmask | ../sender/@hostmask" />

		<xsl:variable name="properIdentifier">
			<xsl:choose>
				<xsl:when test="@id">
					<xsl:value-of select="@id" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="../@id" />
					<xsl:text>.</xsl:text>
					<xsl:value-of select="position()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- Not sure I caught all legal characters found in an IRC nick -->
		<xsl:variable name="senderHash" select="number(translate($senderNick,
			'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM-_^[]{}',
			'12345678901234567890123456789012345678901234567890123456789'))" />

		<xsl:variable name="senderColor">
			<xsl:choose>
				<xsl:when test="$senderNick/@self = 'yes'">colorself</xsl:when>
				<xsl:when test="string-length($senderNick/text()) &gt; 0">
					<xsl:value-of select="concat('color', $senderHash mod 15)" />
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<div id="{$properIdentifier}" class="{$envelopeClasses} {$envelopeSenderClasses}">
			<div class="timestamp">
				<xsl:call-template name="time">
					<xsl:with-param name="date" select="message[1]/@received | @received" />
				</xsl:call-template>
			</div>
			<a href="member:{$senderNick}" class="{$senderClasses} {$senderColor}" title="{$hostmask}"><xsl:value-of select="$senderNick" /></a>
			<span class="message">
				<xsl:choose>
					<xsl:when test="message[1]">
						<xsl:apply-templates select="message[1]/child::node()" mode="copy" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="child::node()" mode="copy" />
					</xsl:otherwise>
				</xsl:choose>
			</span>
		</div>

		<xsl:apply-templates select="message[position() &gt; 1]" />
	</xsl:template>

	<xsl:template match="event">
		<xsl:variable name="eventClasses">
			<xsl:choose>
				<xsl:when test="@name='memberKicked'">
					<xsl:text>event kicked</xsl:text>
				</xsl:when>
				<xsl:when test="@name='memberParted'">
					<xsl:text>event parted</xsl:text>
				</xsl:when>
				<xsl:when test="@name='memberJoined'">
					<xsl:text>event joined</xsl:text>
				</xsl:when>
				<xsl:when test="@name='memberVoiced'">
					<xsl:text>event voiced</xsl:text>
				</xsl:when>
				<xsl:when test="@name='memberPromotedToOperator'">
					<xsl:text>event promoted</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>event</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<div class="timestamp">
			<xsl:call-template name="time">
				<xsl:with-param name="date" select="@occurred" />
			</xsl:call-template>
		</div>
		<div class="{$eventClasses}">
			<xsl:apply-templates select="message/child::node()" mode="copy" />
			<xsl:if test="(@name='memberKicked' or @name='memberParted') and reason != ''">
				<xsl:text> [</xsl:text>
				<xsl:apply-templates select="reason/child::node()" mode="copy"/>
				<xsl:text>]</xsl:text>
			</xsl:if>
		</div>
	</xsl:template>

	<xsl:template match="span[@class='member']" mode="copy">
		<a href="member:{current()}" class="member"><xsl:value-of select="current()" /></a>
		<xsl:if test="(../../@name='memberJoined' or ../../@name='memberParted') and ../../who/@hostmask">
			<span class="hostmask">
				<xsl:value-of select="../../who/@hostmask" />
			</span>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="message//text()" mode="copy">
		<xsl:call-template name="embedWordsInElement">
			<xsl:with-param name="string" select="."/>
			<xsl:with-param name="target" select="'*'"/>
			<xsl:with-param name="replacement" select="'strong'"/>
			<xsl:with-param name="after" select="''"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="@*|*" mode="copy">
		<xsl:copy><xsl:apply-templates select="@*|node()" mode="copy" /></xsl:copy>
	</xsl:template>

	<xsl:template name="time">
        	<xsl:param name="date" /> <!-- YYYY-MM-DD HH:MM:SS +/-HHMM -->

		<xsl:variable name="hour" select="substring($date, 12, 2)"/>
		<xsl:variable name="minutes" select="substring($date, 15, 2)"/>
		<xsl:variable name="seconds" select="substring($date, 18, 2)"/>
		<xsl:variable name="hour12">
			<xsl:choose>
				<xsl:when test="$hour &gt; 12">
					<xsl:value-of select="format-number($hour - 12, '00')" />
				</xsl:when>
				<xsl:when test="$hour = 0">
					<xsl:text>12</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$hour" />
				</xsl:otherwise>
			</xsl:choose>		
		</xsl:variable>
		<xsl:variable name="pm">
			<xsl:choose>
				<xsl:when test="$hour &gt; $hour12">
					<xsl:text> pm</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> am</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>		

		<span class="hour12">
			<xsl:value-of select="$hour12"/>
		</span>
		<span class="hour">
			<xsl:value-of select="$hour"/>
		</span>
		<xsl:text>:</xsl:text>
		<xsl:value-of select="$minutes"/>
		<span class="seconds">
			<xsl:text>:</xsl:text>
			<xsl:value-of select="$seconds"/>
		</span>
		<span class="pm">
			<xsl:value-of select="$pm"/>
		</span>
	</xsl:template>

	<xsl:template name="embedWordsInElement">
  		<xsl:param name="string"/>
 		<xsl:param name="target"/>
		<xsl:param name="replacement"/>
		<xsl:param name="after"/>

		<xsl:variable name="begintarget" select="concat(' ', $target)"/>
		<xsl:variable name="endtarget" select="concat($target, ' ')"/>
		
		<xsl:if test="$string != ''">
		<xsl:choose>
			<xsl:when test="$after=''">
				<xsl:choose>
 					<xsl:when test="starts-with($string, $target)">
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring($string, 2)"/>
					       		<xsl:with-param name="target" select="$target"/>
						       	<xsl:with-param name="replacement" 
				             			select="$replacement"/>
							<xsl:with-param name="after" select="$target"/>
						</xsl:call-template>
					</xsl:when>
		    			<xsl:when test="contains($string, $begintarget)">
   						<xsl:value-of select="substring-before($string, $begintarget)"/>
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring-after($string, $begintarget)"/>
					        	<xsl:with-param name="target" select="$target"/>
					        	<xsl:with-param name="replacement" 
			             				select="$replacement"/>
							<xsl:with-param name="after" select="$begintarget"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$string"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$after=$target">
 				<xsl:choose>
		    			<xsl:when test="contains($string, $endtarget)">
						<xsl:element name="{$replacement}">
							<xsl:value-of select="$target"/>
	   						<xsl:value-of select="substring-before($string, $endtarget)"/>
							<xsl:value-of select="$target"/>
						</xsl:element>
						<xsl:text> </xsl:text>
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring-after($string, $endtarget)"/>
					        	<xsl:with-param name="target" select="$target"/>
					        	<xsl:with-param name="replacement" 
			             				select="$replacement"/>
							<xsl:with-param name="after" select="$endtarget"/>
						</xsl:call-template>
					</xsl:when>
		    			<xsl:when test="contains($string, $begintarget)">
   						<xsl:value-of select="concat($target, substring-before($string, $begintarget))"/>
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring-after($string, $begintarget)"/>
					        	<xsl:with-param name="target" select="$target"/>
					        	<xsl:with-param name="replacement" 
			             				select="$replacement"/>
							<xsl:with-param name="after" select="$begintarget"/>
						</xsl:call-template>
					</xsl:when>
		    			<xsl:when test="substring($string, string-length($string)) = $target">
						<xsl:element name="{$replacement}">
							<xsl:value-of select="$target"/>
							<xsl:value-of select="$string"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$target"/>
						<xsl:value-of select="$string"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$after=$begintarget">
 				<xsl:choose>
		    			<xsl:when test="contains($string, $endtarget)">
						<xsl:text> </xsl:text>
						<xsl:element name="{$replacement}">
							<xsl:value-of select="$target"/>
	   						<xsl:value-of select="substring-before($string, $endtarget)"/>
							<xsl:value-of select="$target"/>
						</xsl:element>
						<xsl:text> </xsl:text>
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring-after($string, $endtarget)"/>
					        	<xsl:with-param name="target" select="$target"/>
					        	<xsl:with-param name="replacement" 
			             				select="$replacement"/>
							<xsl:with-param name="after" select="$endtarget"/>
						</xsl:call-template>
					</xsl:when>
		    			<xsl:when test="contains($string, $begintarget)">
   						<xsl:value-of select="concat($begintarget, substring-before($string, $begintarget))"/>
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring-after($string, $begintarget)"/>
					        	<xsl:with-param name="target" select="$target"/>
					        	<xsl:with-param name="replacement" 
			             				select="$replacement"/>
							<xsl:with-param name="after" select="$begintarget"/>
						</xsl:call-template>
					</xsl:when>
		    			<xsl:when test="substring($string, string-length($string)) = $target">
						<xsl:text> </xsl:text>
						<xsl:element name="{$replacement}">
							<xsl:value-of select="$target"/>
							<xsl:value-of select="$string"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$begintarget"/>
						<xsl:value-of select="$string"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$after=$endtarget">
				<xsl:choose>
 					<xsl:when test="starts-with($string, $target)">
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring($string, 2)"/>
					       		<xsl:with-param name="target" select="$target"/>
						       	<xsl:with-param name="replacement" 
				             			select="$replacement"/>
							<xsl:with-param name="after" select="$target"/>
						</xsl:call-template>
					</xsl:when>
		    			<xsl:when test="contains($string, $begintarget)">
   						<xsl:value-of select="substring-before($string, $begintarget)"/>
						<xsl:call-template name="embedWordsInElement">
						        <xsl:with-param name="string" 
						             select="substring-after($string, $begintarget)"/>
					        	<xsl:with-param name="target" select="$target"/>
					        	<xsl:with-param name="replacement" 
			             				select="$replacement"/>
							<xsl:with-param name="after" select="$begintarget"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$string"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
