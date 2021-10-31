module decorator.core;

import jansi;
import std.traits : Unqual;

private alias str = const(char)[];

private struct CommentBC(size_t maxColours)
{
    str                 text;
    size_t              at;
    Colour[maxColours]  colours;
    size_t              colourCount;
}

private struct Colour 
{
    size_t          start;
    size_t          end;
    AnsiStyleSet    colour;
}

private struct DecoratorLineBC(size_t maxTopComments, size_t maxbotComments, size_t maxColours)
{
    str     text;
    string  fileName;
    size_t  lineNumber;

    CommentBC!maxColours[maxTopComments]    topComments;
    CommentBC!maxColours[maxbotComments]    botComments;
    Colour[maxColours]                      colours;

    size_t topCommentCount;
    size_t botCommentCount;
    size_t colourCount;
}

/++
 + Used to decorate lines.
 +
 + Notes:
 +  This struct allocates all of its memory on the stack. There are 0 malloc and GC allocations.
 +
 +  This struct is zero-copy in regards to its string data, so the lifetime of the string data is a burden for the user.
 +
 +  This struct is suffixed with `BC` as it's specifically designed for betterC. 
 +  A more comfortable non-betterC version will eventually be made.
 +
 + Params:
 +  maxLines                       = The maximum number of lines to allocate stack space for.
 +  maxTopCommentsPerLine          = How many top comments per line to allocate stack space for.
 +  maxBotCommentsPerLine          = How many bottom comments per line to allocate stack space for.
 +  maxColoursPerLineAndPerComment = How many colour segments per line and per comment to allocate stack space for.
 + ++/
struct DecoratorBC(
    size_t maxLines,
    size_t maxTopCommentsPerLine,
    size_t maxBotCommentsPerLine,
    size_t maxColoursPerLineAndPerComment,
)
{
    private alias LineT = DecoratorLineBC!(maxTopCommentsPerLine, maxBotCommentsPerLine, maxColoursPerLineAndPerComment);

    private LineT[maxLines] _lines;
    private size_t          _lineCount;

    @safe @nogc nothrow pure
    {
        /++
        + Adds a new line into the output.
        +
        + Params:
        +  text        = The text to use.
        +  file        = The file that this line belongs to.
        +  lineNumber  = The line number of this line.
        +
        + Returns:
        +  A non-null string on error, otherwise `null` on success.
        + ++/
        string addLine(const(char)[] text, string file = "<memory>", size_t lineNumber = 0)
        {
            if(this._lineCount >= this._lines.length)
                return "maxLines has been reached.";

            this._lines[this._lineCount++] = LineT(
                text,
                file,
                lineNumber
            );
            return null;
        }

        /++
        + Adds a new top comment for a specific line, pointing to a specific character.
        +
        + Params:
        +  line = The index of the line to attach this comment onto.
        +  at   = The character within the line to point to.
        +  text = The contents of this comment.
        +
        + Returns:
        +  A non-null string on error, otherwise `null` on success.
        + ++/
        string addTopComment(size_t line, size_t at, const(char)[] text)
        {
            if(line >= this._lineCount)
                return "Line doesn't exist.";

            scope l = &this._lines[line];
            if(l.topCommentCount >= l.topComments.length)
                return "maxTopCommentsPerLine has been reached for this particular line.";
            l.topComments[l.topCommentCount++] = CommentBC!maxColoursPerLineAndPerComment(
                text,
                at
            );

            return null;
        }

        /// ditto
        string addBotComment(size_t line, size_t at, const(char)[] text)
        {
            if(line >= this._lineCount)
                return "Line doesn't exist.";

            scope l = &this._lines[line];
            if(l.botCommentCount >= l.botComments.length)
                return "maxBotCommentsPerLine has been reached for this particular line.";
            l.botComments[l.botCommentCount++] = CommentBC!maxColoursPerLineAndPerComment(
                text,
                at
            );

            return null;
        }

        /++
        + Colours a specific top comment, for a specific range of characters.
        +
        + Params:
        +  line    = The index of the line which contains the wanted comment.
        +  comment = The index of the comment to colour.
        +  start   = The start character (inclusive) to colour.
        +  end     = The end character (exclusive) to colour.
        +  colour  = The colouring to apply.
        +
        + Returns:
        +  A non-null string on error, otherwise `null` on success.
        + ++/
        string colourTopComment(size_t line, size_t comment, size_t start, size_t end, AnsiStyleSet colour)
        {
            if(line >= this._lineCount)
                return "Line doesn't exist.";
            if(comment >= this._lines[line].topCommentCount)
                return "Comment doesn't exist for this line.";
            if(this._lines[line].topComments[comment].colourCount >= this._lines[line].topComments[comment].colours.length)
                return "maxColoursPerLineAndPerComment has been reached for this comment.";
            
            this._lines[line].topComments[comment].colours[this._lines[line].topComments[comment].colourCount++] = Colour(
                start,
                end,
                colour
            );

            return null;
        }

        /// ditto
        string colourBotComment(size_t line, size_t comment, size_t start, size_t end, AnsiStyleSet colour)
        {
            if(line >= this._lineCount)
                return "Line doesn't exist.";
            if(comment >= this._lines[line].botCommentCount)
                return "Comment doesn't exist for this line.";
            if(this._lines[line].botComments[comment].colourCount >= this._lines[line].botComments[comment].colours.length)
                return "maxColoursPerLineAndPerComment has been reached for this comment.";
            
            this._lines[line].botComments[comment].colours[this._lines[line].botComments[comment].colourCount++] = Colour(
                start,
                end,
                colour
            );

            return null;
        }

        /// ditto
        string colourLine(size_t line, size_t start, size_t end, AnsiStyleSet colour)
        {
            if(line >= this._lineCount)
                return "Line doesn't exist.";
            if(this._lines[line].colourCount >= this._lines[line].colours.length)
                return "maxColoursPerLineAndPerComment has been reached for this line.";
            
            this._lines[line].colours[this._lines[line].colourCount++] = Colour(
                start,
                end,
                colour
            );

            return null;
        }
    }

    /++
     + Pushes all of the string segments needed to render the output of this Decorator.
     +
     + Notes:
     +  Not all the slices returned will be in heap memory, so do not persist any given slices.
     +
     +  `writeln` and friends has special support for this type of `toString`, so non-betterC users can still use
     +  this comfortably.
     +
     + Params:
     +  sink = Either a function/delegate that accepts `const(char)[]`, or an OutputRange that accepts `const(char)[]`.
     + ++/
    void toString(Sink)(scope auto ref Sink sink)
    {
        void put(str text)
        {
            static if(__traits(hasMember, Sink, "put"))
                sink.put(text);
            else
                sink(text);
        }
        
        // Figure out how the longest prefix.
        size_t longestPrefix = 0;
        size_t[maxLines] prefixLengthPerLine;
        foreach(i, line; this._lines)
        {
            size_t size = line.fileName.length + 1; // + 1 for the ':' we add
            do {
                size++;
                line.lineNumber /= 10;
            } while(line.lineNumber > 0);
            if(size > longestPrefix)
                longestPrefix = size;
            prefixLengthPerLine[i] = size;
        }

        // Print out each line and its comments.
        void writePadding(size_t amount)
        {
            foreach(i; 0..amount)
                put(" ");
        }

        void writeColoured(str text, scope const Colour[] colours)
        {
            auto colourI = 0;
            auto start = 0UL;
            while(colourI < colours.length) 
            {
                auto colour = cast()colours[colourI];
                colourI++;

                if(start > colour.start) 
                    colour.start = start;
                put(text[start..colour.start]);
                start = colour.end;

                char[AnsiStyleSet.MAX_CHARS_NEEDED] buf;
                put(ANSI_CSI);
                put(colour.colour.toSequence(buf));
                put("m");
                put(text[colour.start..colour.end]);
                put(ANSI_COLOUR_RESET);
            }
            if(start < text.length) 
            {
                put(text[start..$]);
            }
        }

        foreach(i, const line; this._lines[0..this._lineCount])
        {
            // Write out the top comment
            auto commentsWritten = 0;
            for (auto j = 0; j < line.topCommentCount*3; j++)
            {
                writePadding(longestPrefix);
                put(" | ");

                auto cursor = 0UL;
                const mod = j % 3;
                auto written = false;

                for(auto k = 0; k < line.topCommentCount; k++)
                {
                    const comment = line.topComments[k];
                    if(cursor > comment.at) 
                        continue;
                    writePadding(comment.at - cursor);
                    cursor = comment.at;

                    if(k == commentsWritten && !written && mod == 0) 
                    {
                        writeColoured(comment.text, comment.colours[0..comment.colourCount]);
                        written = true;
                        commentsWritten++;
                        cursor += comment.text.length;
                    } 
                    else if(k == commentsWritten-1 && mod == 1) 
                    {
                        put("^");
                        cursor++;
                    } 
                    else if(k < commentsWritten) 
                    {
                        put("│");
                        cursor++;
                    }
                }

                put("\n");
            }

            // Write out the actual line.
            put(line.fileName);
            put(":");
            IntToCharBuffer buf;
            put(toBase10(line.lineNumber, buf));
            writePadding(longestPrefix - prefixLengthPerLine[i]);
            put(" | ");
            writeColoured(line.text, line.colours[0..line.colourCount]);
            put("\n");

            // Write out the bottom comments
            commentsWritten = 0;
            for(auto j = 0; j < line.botCommentCount*3; j++) 
            {
                writePadding(longestPrefix);
                put(" | ");

                auto cursor = 0UL;
                const mod = j % 3;
                auto written = false;

                for(auto k = commentsWritten; k < line.botCommentCount; k++)
                {
                    auto comment = line.botComments[k];
                    if(cursor > comment.at) 
                        continue;
                    writePadding(comment.at-cursor);
                    cursor = comment.at;

                    if(k == commentsWritten && !written) 
                    {
                        if(mod == 0) 
                        {
                            put("│");
                            cursor++;
                        } 
                        else if(mod == 1) 
                        {
                            put("v");
                            cursor++;
                        } 
                        else 
                        {
                            written = true; // Stop the other comments from acting like they need to be written out on this line.
                            commentsWritten++;
                            writeColoured(comment.text, comment.colours[0..comment.colourCount]);
                            cursor += comment.text.length; // Stop the other comments from overwriting our text with their pipes.
                        }
                    } 
                    else 
                    {
                        put("│");
                        cursor++;
                    }
                }

                put("\n");
            }
        }
    }
}
///
version(none)
unittest
{
    import std;
	DecoratorBC!(1, 3, 3, 2) d;

	d.addLine("0123456789", "Some file", 69);
	d.colourLine(0, 2, 5, AnsiStyleSet.init.fg(Ansi4BitColour.magenta));
	d.colourLine(0, 4, 8, AnsiStyleSet.init.bg(Ansi4BitColour.magenta));

	d.addBotComment(0, 0, "abc");
	d.addBotComment(0, 5, "123lolol");
	d.addBotComment(0, 9, "doe ray me");
	d.colourBotComment(0, 0, 0, 3, AnsiStyleSet.init.fg(Ansi4BitColour.cyan));

	d.addTopComment(0, 2, "abc");
	d.addTopComment(0, 7, "123lolol");
	d.addTopComment(0, 9, "doe ray me");
	d.colourTopComment(0, 1, 0, 3, AnsiStyleSet.init.fg(Ansi4BitColour.green));
	d.colourTopComment(0, 1, 3, 6, AnsiStyleSet.init.fg(Ansi4BitColour.red).style(AnsiStyle.init.bold));

    writeln(d);
}
version(none)
unittest
{
    import core.stdc.stdio;
    DecoratorBC!(1, 1, 1, 3) d;

    d.addLine("printf(\"%s\", 400)", "main.c", 5);
    d.colourLine(0, 0, 6, AnsiStyleSet.init.fg(Ansi4BitColour.yellow));
    d.colourLine(0, 7, 11, AnsiStyleSet.init.fg(Ansi4BitColour.magenta));
    d.colourLine(0, 13, 16, AnsiStyleSet.init.fg(Ansi4BitColour.cyan));

    d.addTopComment(0, 8, "%s was specified.");
    d.colourTopComment(0, 0, 0, 3, AnsiStyleSet.init.fg(Ansi4BitColour.green));

    d.addBotComment(0, 13, "But a %d value was passed");
    d.colourBotComment(0, 0, 6, 8, AnsiStyleSet.init.fg(Ansi4BitColour.red));
    
    d.toString((const(char)[] str){ printf("%.*s", cast(int)str.length, str.ptr); });
}

// Stolen from another project I made
private enum MAX_SIZE_T_STRING_LEN = "18446744073709551615".length;
private immutable BASE10_CHARS = "0123456789";
private alias IntToCharBuffer = char[MAX_SIZE_T_STRING_LEN];
private char[] toBase10(NumT)(NumT num_, scope ref return IntToCharBuffer buffer)
{
    Unqual!NumT num = num_;
    size_t cursor = buffer.length-1;
    if(num == 0)
    {
        buffer[cursor] = '0';
        return buffer[cursor..$];
    }

    static if(__traits(isScalar, NumT))
    {
        static if(!__traits(isUnsigned, NumT))
        {
            const isNegative = num < 0;
            auto numAbs = isNegative ? num * -1UL : num;
        }
        else
            auto numAbs = num;

        while(numAbs != 0)
        {
            assert(numAbs >= 0);
            buffer[cursor--] = BASE10_CHARS[numAbs % 10];
            numAbs /= 10;
        }

        static if(!__traits(isUnsigned, NumT))
        if(isNegative)
            buffer[cursor--] = '-';
    }
    else static assert(false, "Don't know how to convert '"~NumT.stringof~"' into base-10");

    return buffer[cursor+1..$];    
}