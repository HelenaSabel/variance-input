<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:variance="https://variance.unil.ch/" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>This XSLT is passed a TEI document with the results of the MEDITE alignment
                algorithm and it returns 6 XHMTL fragmented files: list of replacements, list of
                additions, list of deletions, list of transpositions, reading view of the source
                text, reading view of the target text.</xd:p>
        </xd:desc>
    </xd:doc>

    <xd:doc>
        <xd:desc>Output: several fragmented XHTML files, and thus we do not create doctype
            declarations nor a namespace.</xd:desc>
    </xd:doc>
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" method="xhtml"
        normalization-form="NFC" omit-xml-declaration="yes"/>


    <xd:doc>
        <xd:desc>Function to create an unique number based on the position of the editorial
            intervention (of the same type).</xd:desc>
        <xd:param name="context">Context node for which the unique number is generated.</xd:param>
    </xd:doc>
    <xsl:function as="xs:string" name="variance:generate-number">
        <xsl:param as="element()" name="context"/>
        <xsl:variable as="xs:integer" name="count"
            select="count($context/preceding::*[local-name() eq $context/local-name()])"/>
        <xsl:value-of select="format-number($count, '00000')"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>Function used to provide and ID (and href) value to the generated
                <xd:b>html:spans</xd:b> or <xd:b>html:a</xd:b> elements.</xd:desc>
        <xd:param name="target">Value of the @target attribute of the anchor/milestone element we
            are processing.</xd:param>
        <xd:param name="context">List of editorial interventions in which we should find a match for
                <xd:ref name="target" type="parameter"/></xd:param>
    </xd:doc>
    <xsl:function as="xs:string" name="variance:get-id">
        <xsl:param as="xs:string" name="target"/>
        <xsl:param as="node()" name="context"/>
        <xsl:variable name="match" select="$context/*[(@corresp | @target) = $target]"/>
        <xsl:choose>
            <xsl:when test="$match">
                <xsl:value-of select="variance:generate-number($match)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$target"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xd:doc>
        <xd:desc>Function to retrieve the first following <xd:b>tei:metamark</xd:b> or
                <xd:b>tei:milestone</xd:b> element of the <xd:b>tei:metamark</xd:b> or
                <xd:b>tei:milestone</xd:b> that is being processed.</xd:desc>
        <xd:param name="context">The <xd:b>tei:metamark</xd:b> or <xd:b>tei:milestone</xd:b> that is
            being processed.</xd:param>
    </xd:doc>
    <xsl:function as="element()?" name="variance:retrieve-next-anchor">
        <xsl:param as="element()" name="context"/>
        <xsl:sequence select="$context/following::*[local-name() = ('metamark', 'anchor')][1]"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>Named template to retrieve the contents of an editorial element (e.g
                <xd:b>addition</xd:b>).</xd:desc>
        <xd:param name="target">Value of the @target attribute of the <xd:b>tei:milestone</xd:b>
            element being processed.</xd:param>
        <xd:param name="context">List of editorial interventions in which we should find a match for
                <xd:ref name="target" type="parameter"/></xd:param>
    </xd:doc>
    <xsl:template as="item()*" name="get-contents">
        <xsl:param as="xs:string?" name="target"/>
        <xsl:param as="node()?" name="context"/>
        <xsl:apply-templates select="$context/*[@corresp eq $target]/node()"/>
    </xsl:template>

    <xd:doc>
        <xd:desc>Global variables that hold de lists of transformations for convenience and
            increased performance.</xd:desc>
    </xd:doc>
    <xsl:variable name="transposition" select="//listTranspose"/>
    <xsl:variable name="addition" select="//listAddition"/>
    <xsl:variable name="substitution" select="//listSubstitution"/>
    <xsl:variable name="deletion" select="//listDeletion"/>

    <xd:doc>
        <xd:desc>Main template from which we genetare the 6 XHTML files using multimodal
            instructions. Note that there is a first transformation pass done via <xd:ref
                name="withLineBreaks" type="variable"/> (mode "lb") to get rid of paragraphs and add
            instead line breaks.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="withLineBreaks">
            <xsl:apply-templates mode="lb"/>
        </xsl:variable>
        <xsl:result-document href="d.xhtml">
            <xsl:apply-templates select="$transposition"/>
        </xsl:result-document>
        <xsl:result-document href="i.xhtml">
            <xsl:apply-templates select="$addition"/>
        </xsl:result-document>
        <xsl:result-document href="r.xhtml">
            <xsl:apply-templates select="$substitution"/>
        </xsl:result-document>
        <xsl:result-document href="s.xhtml">
            <xsl:apply-templates select="$deletion"/>
        </xsl:result-document>
        <xsl:result-document href="source.xhtml">
            <xsl:apply-templates mode="source"
                select="$withLineBreaks//body/descendant::*[local-name() = ('metamark', 'anchor')]"
            />
        </xsl:result-document>
        <xsl:result-document href="target.xhtml">
            <xsl:apply-templates mode="target"
                select="$withLineBreaks//body/descendant::*[local-name() = ('metamark', 'anchor')]"
            />
        </xsl:result-document>
    </xsl:template>

    <xd:doc>
        <xd:desc>Identity transformation for the "lb" mode pass.</xd:desc>
    </xd:doc>
    <xsl:template match="node() | @*" mode="lb">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="lb"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc>
        <xd:desc>Insertion of <xd:b>tei:lb</xd:b> elements for each paragraph.</xd:desc>
    </xd:doc>
    <xsl:template match="p" mode="lb" name="pReplacement">
        <xsl:apply-templates select="node()" mode="lb"/>
        <lb xmlns="http://www.tei-c.org/ns/1.0"/>
    </xsl:template>

    <xd:doc>
        <xd:desc>Template to create list of transpositions for document
            <xd:i>d.xhtml</xd:i>.</xd:desc>
    </xd:doc>
    <xsl:template match="transpose">
        <li>
            <a class="sync sync-twice" data-tags="" href="#ad_{variance:generate-number(.)}"
                id="lbd_{variance:generate-number(.)}">
                <xsl:apply-templates/>
            </a>
        </li>
    </xsl:template>

    <xd:doc>
        <xd:desc>Template to create list of deletions for document <xd:i>s.xhtml</xd:i>.</xd:desc>
    </xd:doc>
    <xsl:template match="deletion">
        <li>
            <a class="sync" data-tags="" href="#as_{variance:generate-number(.)}"
                id="lbs_{variance:generate-number(.)}">
                <xsl:apply-templates/>
            </a>
        </li>
    </xsl:template>

    <xd:doc>
        <xd:desc>Template to create list of additions for document <xd:i>i.xhtml</xd:i>.</xd:desc>
    </xd:doc>
    <xsl:template match="addition">
        <li>
            <a class="sync" data-tags="" href="#bi_{variance:generate-number(.)}"
                id="lai_{variance:generate-number(.)}">
                <xsl:apply-templates/>
            </a>
        </li>
    </xsl:template>

    <xd:doc>
        <xd:desc>Template to create list of replacements for document
            <xd:i>r.xhtml</xd:i>.</xd:desc>
    </xd:doc>
    <xsl:template match="substitution">
        <xsl:variable name="anchor"
            select="current()/ancestor::TEI//metamark[@corresp eq current()/@corresp]"/>
        <xsl:variable name="delimiter" select="variance:retrieve-next-anchor($anchor)"/>
        <xsl:variable name="replacement">
            <xsl:apply-templates/>
        </xsl:variable>
        <xsl:variable name="source">
            <xsl:sequence select="$anchor/following::node()[. &lt;&lt; $delimiter]"/>
        </xsl:variable>
        <li>
            <a class="sync sync-twice" data-tags="" href="#ar_{variance:generate-number(.)}"
                id="lbr_{variance:generate-number(.)}">
                <xsl:sequence select="($source, ' &#8594; ', $replacement)"/>
            </a>
        </li>
    </xsl:template>

    <xd:doc>
        <xd:desc>Processing of <xd:b>tei:anchor</xd:b> elements for the generation of the source
            view.</xd:desc>
    </xd:doc>
    <xsl:template match="anchor" mode="source">
        <xsl:variable name="delimiter" select="variance:retrieve-next-anchor(.)"/>
        <a class="span_c sync sync-single" data-tags="" href="#bc_{variance:generate-number(.)}"
            id="ac_{variance:generate-number(.)}">
            <xsl:apply-templates select="./following::node()[. &lt;&lt; $delimiter]"/>
        </a>
    </xsl:template>

    <xd:doc>
        <xd:desc>Processing of <xd:b>tei:metamark</xd:b> elements for the generation of the source
            view.</xd:desc>
    </xd:doc>
    <xsl:template match="metamark" mode="source">
        <xsl:variable name="delimiter" select="variance:retrieve-next-anchor(.)"/>
        <xsl:choose>
            <xsl:when test="@function eq 'del'">
                <span class="span_s" data-tags="" id="as_{variance:get-id(./@target, $deletion)}">
                    <xsl:call-template name="get-contents">
                        <xsl:with-param name="context" select="$deletion"/>
                        <xsl:with-param name="target" select="./@target"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="@function eq 'add'"/>
            <xsl:when test="@function eq 'subst'">
                <a class="sync sync-single span_r" data-tags=""
                    href="#br_{variance:get-id(./@target, $substitution)}"
                    id="ar_{variance:get-id(./@target, $substitution)}">
                    <xsl:apply-templates select="./following::node()[. &lt;&lt; $delimiter]"/>
                </a>
            </xsl:when>
            <xsl:when test="@function eq 'trans'">
                <a class="sync sync-single span_d" data-tags=""
                    href="#bd_{variance:get-id(./@target, $transposition)}"
                    id="ad_{variance:get-id(./@target, $transposition)}">
                    <xsl:apply-templates select="./following::node()[. &lt;&lt; $delimiter]"/>
                </a>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xd:doc>
        <xd:desc>Processing of <xd:b>tei:anchor</xd:b> elements for the generation of the target
            view.</xd:desc>
    </xd:doc>
    <xsl:template match="anchor" mode="target">
        <xsl:variable name="delimiter" select="variance:retrieve-next-anchor(.)"> </xsl:variable>
        <a class="span_c sync sync-single" data-tags="" href="#ac_{variance:generate-number(.)}"
            id="bc_{variance:generate-number(.)}">
            <xsl:apply-templates select="./following::node()[. &lt;&lt; $delimiter]"/>
        </a>
    </xsl:template>

    <xd:doc>
        <xd:desc>Processing of <xd:b>tei:metamark</xd:b> elements for the generation of the target
            view.</xd:desc>
    </xd:doc>
    <xsl:template match="metamark" mode="target">
        <xsl:variable name="delimiter" select="variance:retrieve-next-anchor(.)"/>
        <xsl:choose>
            <xsl:when test="@function eq 'del'"/>
            <xsl:when test="@function eq 'add'">
                <span class="span_i" id="bi_{variance:get-id(./@target, $addition)}" data-tags="">
                    <xsl:call-template name="get-contents">
                        <xsl:with-param name="target" select="@target"/>
                        <xsl:with-param name="context" select="$addition"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="@function eq 'subst'">
                <a class="sync sync-single span_r" data-tags=""
                    href="#ar_{variance:get-id(./@target, $substitution)}"
                    id="br_{variance:get-id(./@target, $substitution)}">
                    <xsl:call-template name="get-contents">
                        <xsl:with-param name="target" select="@target"/>
                        <xsl:with-param name="context" select="$substitution"/>
                    </xsl:call-template>
                </a>
            </xsl:when>
            <xsl:when test="@function eq 'trans' and not(@corresp)">
                <a class="sync sync-single span_d" data-tags=""
                    href="#ad_{variance:get-id(./@target, $transposition)}"
                    id="bd_{variance:get-id(./@target, $transposition)}">
                    <xsl:apply-templates select="./following::node()[. &lt;&lt; $delimiter]"/>
                </a>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xd:doc>
        <xd:desc>Processing of <xd:b>tei:lb</xd:b> elements (likely generated by <xd:ref
                name="pReplacement" type="template"/>).</xd:desc>
    </xd:doc>
    <xsl:template match="lb" mode="#all">
        <br/>
    </xsl:template>
    <xd:doc>
        <xd:desc>Processing of <xd:b>tei:emph</xd:b> elements.</xd:desc>
    </xd:doc>
    <xsl:template match="emph" mode="#all">
        <em>
            <xsl:apply-templates/>
        </em>
    </xsl:template>

    <xd:doc>
        <xd:desc>Processing of <xd:b>tei:pb</xd:b> elements to create images. It assumes that there
            won’t be any periods in the image file name so we can use it to get rid of the
            extension.</xd:desc>
    </xd:doc>
    <xsl:template match="pb">
        <span class="page-marker" data-image-name="{substring-before(@facs, '.')}">
            <span class="page-number"><xsl:value-of select="@pagination"/></span>
            <img src="/img/settings/{@facs}"/>
        </span>
    </xsl:template>
</xsl:stylesheet>
