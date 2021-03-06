%{
/*-------------------------------------------------------------------------
 *
 * exprscan.l
 *	  a lexical scanner for a simple expression syntax
 *
 * Portions Copyright (c) 1996-2015, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *-------------------------------------------------------------------------
 */

/* line and column number for error reporting */
static int	yyline = 0, yycol = 0;

/* Handles to the buffer that the lexer uses internally */
static YY_BUFFER_STATE scanbufhandle;
static char *scanbuf;
static int	scanbuflen;
%}

%option 8bit
%option never-interactive
%option nodefault
%option noinput
%option nounput
%option noyywrap
%option warn
%option prefix="expr_yy"

space			[ \t\r\f]

%%

"+"				{ yycol += yyleng; return '+'; }
"-"				{ yycol += yyleng; return '-'; }
"*"				{ yycol += yyleng; return '*'; }
"/"				{ yycol += yyleng; return '/'; }
"%"				{ yycol += yyleng; return '%'; }
"("				{ yycol += yyleng; return '('; }
")"				{ yycol += yyleng; return ')'; }

:[a-zA-Z0-9_]+	{
					yycol += yyleng;
					yylval.str = pg_strdup(yytext + 1);
					return VARIABLE;
				}
[0-9]+			{
					yycol += yyleng;
					yylval.ival = strtoint64(yytext);
					return INTEGER;
				}

[\n]			{ yycol = 0; yyline++; }
{space}+		{ yycol += yyleng; /* ignore */ }

.				{
					yycol += yyleng;
					fprintf(stderr, "unexpected character \"%s\"\n", yytext);
					return CHAR_ERROR;
				}
%%

void
yyerror(const char *message)
{
	/* yyline is always 1 as pgbench calls the parser for each line...
	 * so the interesting location information is the column number */
	fprintf(stderr, "%s at column %d\n", message, yycol);
	/* go on to raise the error from pgbench with more information */
}

/*
 * Called before any actual parsing is done
 */
void
expr_scanner_init(const char *str)
{
	Size	slen = strlen(str);

	/*
	 * Might be left over after error
	 */
	if (YY_CURRENT_BUFFER)
		yy_delete_buffer(YY_CURRENT_BUFFER);

	/*
	 * Make a scan buffer with special termination needed by flex.
	 */
	scanbuflen = slen;
	scanbuf = pg_malloc(slen + 2);
	memcpy(scanbuf, str, slen);
	scanbuf[slen] = scanbuf[slen + 1] = YY_END_OF_BUFFER_CHAR;
	scanbufhandle = yy_scan_buffer(scanbuf, slen + 2);

	BEGIN(INITIAL);
}


/*
 * Called after parsing is done to clean up after seg_scanner_init()
 */
void
expr_scanner_finish(void)
{
	yy_delete_buffer(scanbufhandle);
	pg_free(scanbuf);
}
