/*
 * generated by Xtext 2.13.0-SNAPSHOT
 */
package io.typefox.yang.parser.antlr.lexer.jflex;

import java.io.Reader;
import java.io.IOException;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.TokenSource;

import static io.typefox.yang.parser.antlr.internal.InternalYangParser.*;

@SuppressWarnings({"all"})
%%

%{
	public final static TokenSource createTokenSource(Reader reader) {
		return new YangFlexer(reader);
	}

	private int offset = 0;
	
	public void reset(Reader reader) {
		yyreset(reader);
		offset = 0;
	}

	@Override
	public Token nextToken() {
		try {
			int type = advance();
			if (type == Token.EOF) {
				return Token.EOF_TOKEN;
			}
			int length = yylength();
			final String tokenText = yytext();
			CommonToken result = new CommonTokenWithText(tokenText, type, Token.DEFAULT_CHANNEL, offset);
			offset += length;
			return result;
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public String getSourceName() {
		return "FlexTokenSource";
	}

	public static class CommonTokenWithText extends CommonToken {

		private static final long serialVersionUID = 1L;

		public CommonTokenWithText(String tokenText, int type, int defaultChannel, int offset) {
			super(null, type, defaultChannel, offset, offset + tokenText.length() - 1);
			this.text = tokenText;
		}
	}

%}

%unicode
%implements org.antlr.runtime.TokenSource
%class YangFlexer
%function advance
%public
%int
%eofval{
return Token.EOF;
%eofval}

WS=[\ \n\r\t]+

ML_COMMENT="/*" ~"*/"
SL_COMMENT="/""/"[^\r\n]*(\r?\n)?

ID= [a-zA-Z] [a-zA-Z0-9_\.\-]*

STRING=[^\ \n\r\t\{\}\;\'\"]+
SINGLE_QUOTED_STRING= "'" [^']* "'"?
DOUBLE_QUOTED_STRING= \" ([^\\\"]|\\.)* \"?
ESCAPED_DQ_STRING= \\\" [^\\\"]* \\\"?

NUMBER= [0-9]+ ("." [0-9]+)? | "." [0-9]+ 

OPERATOR= "and" | "or" | "mod" | "div" | "*" | "|" | "+" | "-" | "=" | "!=" | "<" | "<=" | ">" | ">="

STRING_CONCAT= ({WS} | {ML_COMMENT} | {SL_COMMENT})* "+" ({WS} | {ML_COMMENT} | {SL_COMMENT})*

%s EXPRESSION, IN_EXPRESSION_STRING, IN_SQ_EXPRESSION_STRING
%s COLON_EXPECTED, ID_EXPECTED
%s BLACK_BOX_STRING

%%

<COLON_EXPECTED> {
	\: {yybegin(ID_EXPECTED); return Colon;}
}
<ID_EXPECTED> {
	{ID} {yybegin(BLACK_BOX_STRING); return RULE_ID;}
}

<BLACK_BOX_STRING> {
	{STRING} { return RULE_STRING; }	
	{SINGLE_QUOTED_STRING} { return RULE_STRING; }
	{DOUBLE_QUOTED_STRING} { return RULE_STRING; }
	
	{ML_COMMENT} { return RULE_ML_COMMENT; }
	{SL_COMMENT} { return RULE_SL_COMMENT; }
}

<EXPRESSION> {
	{ML_COMMENT} { return RULE_ML_COMMENT; }
	{SL_COMMENT} { return RULE_SL_COMMENT; }
	\"          {yybegin(IN_EXPRESSION_STRING); return RULE_HIDDEN;}
	"'"         {yybegin(IN_SQ_EXPRESSION_STRING); return RULE_HIDDEN;}
	{OPERATOR}  { return RULE_OPERATOR; }
	{ID}        { return RULE_ID; }
	{NUMBER}    { return RULE_NUMBER; }
	":"         { return Colon; }
	"("         { return LeftParenthesis; }
	")"         { return RightParenthesis; }
	"["         { return LeftSquareBracket; }
	"]"         { return RightSquareBracket; }
	"."         { return FullStop; }
	".."        { return FullStopFullStop; }
	"/"         { return Solidus; }
	","         { return Comma; }
}

<IN_EXPRESSION_STRING> {
	{SINGLE_QUOTED_STRING} { return RULE_STRING; }
	{ESCAPED_DQ_STRING}    { return RULE_STRING; }
	{OPERATOR}  { return RULE_OPERATOR; }
	{ID}        { return RULE_ID; }
	{NUMBER}    { return RULE_NUMBER; }
	":"         { return Colon; }
	"("         { return LeftParenthesis; }
	")"         { return RightParenthesis; }
	"["         { return LeftSquareBracket; }
	"]"         { return RightSquareBracket; }
	"."         { return FullStop; }
	".."        { return FullStopFullStop; }
	"/"         { return Solidus; }
	","         { return Comma; }

	\" {STRING_CONCAT} { yybegin(EXPRESSION); return RULE_HIDDEN; }
	\"                 { yybegin(YYINITIAL); return RULE_HIDDEN; }
}

<IN_SQ_EXPRESSION_STRING> {
	{DOUBLE_QUOTED_STRING}    { return RULE_STRING; }
	{OPERATOR}  { return RULE_OPERATOR; }
	{ID}        { return RULE_ID; }
	{NUMBER}    { return RULE_NUMBER; }
	":"         { return Colon; }
	"("         { return LeftParenthesis; }
	")"         { return RightParenthesis; }
	"["         { return LeftSquareBracket; }
	"]"         { return RightSquareBracket; }
	"."         { return FullStop; }
	".."        { return FullStopFullStop; }
	"/"         { return Solidus; }
	","         { return Comma; }

	"'" {STRING_CONCAT} { yybegin(EXPRESSION); return RULE_HIDDEN; }
	"'"                 { yybegin(YYINITIAL); return RULE_HIDDEN; }
}

<YYINITIAL> {
"action"                  {yybegin(BLACK_BOX_STRING); return Action; }
"anydata"                 {yybegin(BLACK_BOX_STRING); return Anydata; }
"anyxml"                  {yybegin(BLACK_BOX_STRING); return Anyxml; }
"argument"                {yybegin(BLACK_BOX_STRING); return Argument; }
"augment"                 {yybegin(BLACK_BOX_STRING); return Augment; }
"base"                    {yybegin(BLACK_BOX_STRING); return Base; }
"belongs-to"              {yybegin(BLACK_BOX_STRING); return BelongsTo; }
"bit"                     {yybegin(BLACK_BOX_STRING); return Bit; }
"case"                    {yybegin(BLACK_BOX_STRING); return Case; }
"choice"                  {yybegin(BLACK_BOX_STRING); return Choice; }
"config"                  {yybegin(BLACK_BOX_STRING); return Config; }
"contact"                 {yybegin(BLACK_BOX_STRING); return Contact; }
"container"               {yybegin(BLACK_BOX_STRING); return Container; }
 "default"                {yybegin(BLACK_BOX_STRING); return Default; }
 "description"            {yybegin(BLACK_BOX_STRING); return Description; }
 "enum"                   {yybegin(BLACK_BOX_STRING); return Enum; }
 "error-app-tag"          {yybegin(BLACK_BOX_STRING); return ErrorAppTag; }
 "error-message"          {yybegin(BLACK_BOX_STRING); return ErrorMessage; }
 "extension"              {yybegin(BLACK_BOX_STRING); return Extension; }
 "deviation"              {yybegin(EXPRESSION); return Deviation; }
 "deviate"                {yybegin(BLACK_BOX_STRING); return Deviate; }
 "feature"                {yybegin(BLACK_BOX_STRING); return Feature; }
 "fraction-digits"        {yybegin(BLACK_BOX_STRING); return FractionDigits; }
 "grouping"               {yybegin(BLACK_BOX_STRING); return Grouping; }
 "identity"               {yybegin(BLACK_BOX_STRING); return Identity; }
 "if-feature"             {yybegin(EXPRESSION); return IfFeature; }
 "import"                 {yybegin(BLACK_BOX_STRING); return Import; }
 "include"                {yybegin(BLACK_BOX_STRING); return Include; }
 "input"                  {yybegin(BLACK_BOX_STRING); return Input; }
 "key"                    {yybegin(EXPRESSION); return Key; }
 "leaf"                   {yybegin(BLACK_BOX_STRING); return Leaf; }
 "leaf-list"              {yybegin(BLACK_BOX_STRING); return LeafList; }
 "length"                 {yybegin(BLACK_BOX_STRING); return Length; }
 "list"                   {yybegin(BLACK_BOX_STRING); return List; }
 "mandatory"              {yybegin(BLACK_BOX_STRING); return Mandatory; }
 "max-elements"           {yybegin(BLACK_BOX_STRING); return MaxElements; }
 "min-elements"           {yybegin(BLACK_BOX_STRING); return MinElements; }
 "module"                 {yybegin(BLACK_BOX_STRING); return Module; }
 "must"                   {yybegin(EXPRESSION); return Must; }
 "namespace"              {yybegin(BLACK_BOX_STRING); return Namespace; }
 "notification"           {yybegin(BLACK_BOX_STRING); return Notification; }
 "ordered-by"             {yybegin(BLACK_BOX_STRING); return OrderedBy; }
 "organization"           {yybegin(BLACK_BOX_STRING); return Organization; }
 "output"                 {yybegin(BLACK_BOX_STRING); return Output; }
 "path"                   {yybegin(EXPRESSION); return Path; }
 "pattern"                {yybegin(BLACK_BOX_STRING); return Pattern; }
 "position"               {yybegin(BLACK_BOX_STRING); return Position; }
 "prefix"                 {yybegin(BLACK_BOX_STRING); return Prefix; }
 "presence"               {yybegin(BLACK_BOX_STRING); return Presence; }
 "range"                  {yybegin(BLACK_BOX_STRING); return Range; }
 "reference"              {yybegin(BLACK_BOX_STRING); return Reference; }
 "refine"                 {yybegin(BLACK_BOX_STRING); return Refine; }
 "require-instance"       {yybegin(BLACK_BOX_STRING); return RequireInstance; }
 "revision"               {yybegin(BLACK_BOX_STRING); return Revision; }
 "revision-date"          {yybegin(BLACK_BOX_STRING); return RevisionDate; }
 "rpc"                    {yybegin(BLACK_BOX_STRING); return Rpc; }
 "status"                 {yybegin(BLACK_BOX_STRING); return Status; }
 "submodule"              {yybegin(BLACK_BOX_STRING); return Submodule; }
 "type"                   {yybegin(BLACK_BOX_STRING); return Type; }
 "typedef"                {yybegin(BLACK_BOX_STRING); return Typedef; }
 "unique"                 {yybegin(EXPRESSION); return Unique; }
 "units"                  {yybegin(BLACK_BOX_STRING); return Units; }
 "uses"                   {yybegin(BLACK_BOX_STRING); return Uses; }
 "value"                  {yybegin(BLACK_BOX_STRING); return Value; }
 "when"                   {yybegin(EXPRESSION); return When; }
 "yang-version"           {yybegin(BLACK_BOX_STRING); return YangVersion; }
 "yin-element"            {yybegin(BLACK_BOX_STRING); return YinElement; }
{ID}                      { yybegin(COLON_EXPECTED);  return RULE_ID; }
	
	{ML_COMMENT} { return RULE_ML_COMMENT; }
	{SL_COMMENT} { return RULE_SL_COMMENT; }
}
\; { yybegin(YYINITIAL); return Semicolon; }
\{ { yybegin(YYINITIAL); return LeftCurlyBracket; }
\} { yybegin(YYINITIAL); return RightCurlyBracket; }
{WS} { return RULE_WS; }
