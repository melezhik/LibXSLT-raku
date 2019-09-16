use v6;
#  -- DO NOT EDIT --
# generated by: ../LibXML-p6/etc/generator.p6 --mod=LibXSLT --lib=XSLT etc/libxslt-api.xml

unit module LibXSLT::Native::Gen::extra;
# interface for the non-standard features:
#    implement some extension outside the XSLT namespace but not EXSLT with is in a different library. 
use LibXSLT::Native::Defs :$lib, :xmlCharP;

sub xsltFunctionNodeSet(xmlXPathParserContext $ctxt, int32 $nargs) is native(XSLT) is export {*};
sub xsltRegisterAllExtras() is native(XSLT) is export {*};
