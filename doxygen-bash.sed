#!/bin/sed -nf
/^## \+@fn/{
    :step
    /@param [^ ]\+ .*$/{
        # Groups are
        # \1: @fn <funcname>
        # \2: already identified params
        # \3: previous doc string
        # \4: @param<space>
        # \5: newly identified param name plus optional dot-dot-dot string
        # \6: optional dot-dot-dot string
        # \7: everything after \5 to end of line
        # Here, we-reinsert param names into the <funcname>()
        s/\(@fn [^(\n]\+\)(\([^(]*\))\(.*\)\(@param \)\([^ \n]\+\(\.\.\.\)\?\)\([^\n]*\)$/\1(\2, \5)\3\4\5\7/
    }
    / *\(function *\)\?[a-z:A-Z0-9_]\+ *() *{ *$/!{
        N
        b step
    }
    # Remove optional 'function' keyword (and some extra spaces).
    s/ *\(function *\)\?\([a-z:.A-Z0-9_]\+ *() *{\) *$/\2/
    # Here, we should have @fn (, param1, param2, param3), we remove
    # the first extra ", ".
    s/\(@fn[^(]\+\)(, /\1(/
    # Remove the function body to avoid interference.
    s/\(@fn \([^(]\+\)(\)\([^)]*\)\().*\)\n\2() *{/\1\3\4\n\2(\3) { }/
    # Replace all '## ' to '//! ' at beginning-of-line.
    s/\(^\|\n\)## /\1\/\/! /g
    p
    b end
}
/^declare /{
    # The principle is quite easy. For every declare option, we add a
    # keyword into the sed exchange buffer. Once everything is parsed,
    # we add the variable identifier and maybe the variable default
    # value, add that to the exchange buffer and print the result.

    # Reset exchange buffer
    x
    s/.*//
    x
    # Remove declare keyword, we wont need it anymore
    s/^declare \+//
    # Simple declaration case.
    /^[^-]/{
        x
        s/.*/&String /
        x
        b declareprint
    }
    # Concat options. Some of them are ignored, such as -f.
    :declare
    s/^-\([aAilrtux]\+\) \+-\([aAilrtux]\+\) \+/-\1\2 /
    t declare

    # Prepend Exported and ReadOnly attributes
    /^-[aAiltur]*x/{
        x
        s/.*/&Exported /
        x
    }
    /^-[aAiltux]*r/{
        x
        s/.*/&ReadOnly /
        x
    }

    # Integer type, exclusive with default 'String' type.
    /^-[aAlturx]*i/{
        x
        s/.*/&Integer /
        x
        b array
    }

    # String type. handling.
    /^-[aAtrx]*l/{
        x
        s/.*/&LowerCase /
        x
    }
    /^-[aAtrx]*u/{
        x
        s/.*/&UpperCase /
        x
    }
    x
    s/.*/&String /
    x

    : array
    # For arrays, we remove the initialisation since I dont know yet
    # how to print it for doxygen to understand.
    /^-[Ailturx]*a/{
        x
        s/.*/&Array /
        x
        b deletevalue
    }
    /^-[ailturx]*A/{
        x
        s/.*/&AssociativeArray /
        x
        b deletevalue
    }

    :declareprint
    # Remove the declare option, x, then G will concat the exchange
    # buffer (the 'type' string) and the regular buffer (the var
    # possibly followed by an init value). The rest is quite easy to
    # understand.
    s/-[^ ]\+ \+//
    x
    G
    s/\n//
    s/=/ = /
    s/$/;/
    p
    x
    b end
}

# Delete non doxygen-related lines content, but not the line
# themselves.
/^## /!{
     s/^.*$//p
}
b end

# For arrays, to avoid duplication.
: deletevalue
s/\(-[^ ]\+ \+[^=]\+\)=.*/\1/
b declareprint

:end
# Make all ## lines doxygen-able.
s/^## /\/\/! /p
